import 'dart:async';

import 'package:chataptor/src/auth/customer_identity.dart';
import 'package:chataptor/src/auth/guest_id_store.dart';
import 'package:chataptor/src/client/connection_state.dart';
import 'package:chataptor/src/client/message_parser.dart';
import 'package:chataptor/src/client/send_result.dart';
import 'package:chataptor/src/config/chataptor_config.dart';
import 'package:chataptor/src/config/site_config.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/logger/chataptor_logger.dart';
import 'package:chataptor/src/models/agent_info.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:chataptor/src/models/message.dart';
import 'package:chataptor/src/models/message_draft.dart';
import 'package:chataptor/src/storage/chataptor_storage.dart';
import 'package:chataptor/src/storage/in_memory_storage.dart';
import 'package:chataptor/src/streams/value_stream.dart';
import 'package:chataptor/src/transport/chat_transport.dart';
import 'package:chataptor/src/transport/phoenix_socket_transport.dart';
import 'package:chataptor/src/transport/transport_types.dart';

/// Core SDK client. Orchestrates the transport, state streams, and business
/// logic that the Flutter layer and merchants consume.
///
/// Typical construction goes through `Chataptor.init` in
/// `package:chataptor_flutter`. Direct instantiation is supported for
/// multi-instance scenarios or tests (via [ChataptorClient.internal]).
class ChataptorClient {
  /// Creates a [ChataptorClient] using defaults. For tests and advanced
  /// use-cases, prefer [ChataptorClient.internal] which accepts a custom
  /// [ChatTransport].
  ChataptorClient({required ChataptorConfig config})
    : this.internal(config: config, transport: PhoenixSocketTransport());

  /// Internal / test entry point that lets callers inject a transport.
  ///
  /// When [storage] is omitted, falls back to [ChataptorConfig.storage] and
  /// finally to a fresh [InMemoryChataptorStorage]. The resolved instance
  /// is shared between the client's own state and the internal
  /// [GuestIdStore] — they never operate on two different in-memory
  /// backings.
  ChataptorClient.internal({
    required ChataptorConfig config,
    required ChatTransport transport,
    ChataptorStorage? storage,
  }) : this._withStorage(
         config: config,
         transport: transport,
         storage: storage ?? config.storage ?? InMemoryChataptorStorage(),
       );

  ChataptorClient._withStorage({
    required ChataptorConfig config,
    required ChatTransport transport,
    required ChataptorStorage storage,
  }) : _config = config,
       _transport = transport,
       _storage = storage,
       _guestIdStore = GuestIdStore(storage: storage, siteId: config.siteId) {
    _connectionState.add(const Disconnected(DisconnectReason.userRequested));
    _transport.connectionState.listen(_handleTransportState);
    _transport.events.listen(_handleTransportEvent);
  }

  /// The active configuration. Most fields are immutable for the lifetime
  /// of the client, but [ChataptorConfig.customer] may be swapped at
  /// runtime via [identify]; reading [config] always returns the current
  /// value.
  ChataptorConfig get config => _config;
  ChataptorConfig _config;

  final ChatTransport _transport;
  final ChataptorStorage _storage;
  final GuestIdStore _guestIdStore;

  final ValueStream<ConnectionState> _connectionState =
      ValueStream<ConnectionState>();
  final StreamController<Message> _messages =
      StreamController<Message>.broadcast();
  final StreamController<ChataptorError> _errors =
      StreamController<ChataptorError>.broadcast();
  final ValueStream<SiteConfig> _siteConfigStream = ValueStream<SiteConfig>();
  final ValueStream<List<AgentInfo>> _onlineAgentsStream =
      ValueStream<List<AgentInfo>>();

  bool _disposed = false;

  /// Active conversation ID, set after `conversation:create` succeeds.
  String? _conversationId;

  /// Guards against duplicate `message:received` pushes for the same
  /// server message and suppresses the server echo of the customer's
  /// own sent messages.
  final Set<String> _seenMessageIds = {};

  /// In-memory cache of all messages received in this session (history +
  /// real-time). Persists across disconnect/reconnect cycles so the UI can
  /// show messages immediately on re-entry without a visible empty-state flash.
  /// Cleared only by [clearSession].
  final List<Message> _messageHistory = [];

  String _siteTopic() => 'site:${config.siteId}';
  String _conversationTopic() => 'conversation:$_conversationId';
  String _lastActivityStorageKey() =>
      'chataptor.last_activity_at.${config.siteId}';

  Future<void> _touchLastActivity() async {
    if (config.sessionIdleTimeout == null) return;
    await _storage.writeString(
      _lastActivityStorageKey(),
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  /// Reads the persisted last-activity timestamp and — when it exists,
  /// parses cleanly, and falls outside [ChataptorConfig.sessionIdleTimeout] —
  /// clears the guest session before the upcoming channel join. No-ops
  /// when the timeout is disabled or no prior activity has been recorded.
  Future<void> _enforceSessionIdleTimeout() async {
    final timeout = config.sessionIdleTimeout;
    if (timeout == null) return;
    final stored = await _storage.readString(_lastActivityStorageKey());
    if (stored == null) return;
    final last = DateTime.tryParse(stored);
    if (last == null) return;
    if (DateTime.now().toUtc().difference(last.toUtc()) <= timeout) return;
    await _guestIdStore.clear();
    await _storage.delete(_lastActivityStorageKey());
    _seenMessageIds.clear();
    _messageHistory.clear();
    _siteConfigStream.clear();
    _onlineAgentsStream.add(const []);
  }

  Map<String, dynamic> _buildSiteJoinParams() {
    final lang = config.translation.customerLanguage;
    if (config.translation.enabled && lang != null) {
      return {'browser_language': lang};
    }
    return {};
  }

  /// Snapshot of all messages received in this session, sorted oldest-first.
  ///
  /// Persists across [disconnect]/[connect] cycles. Use this to initialise a
  /// message list widget immediately on mount — the UI avoids an empty-state
  /// flash even when the user navigates away and back. The list is cleared by
  /// [clearSession] and returns to empty after [dispose].
  List<Message> get currentMessages =>
      List<Message>.unmodifiable(_messageHistory);

  /// Stream of connection state updates.
  Stream<ConnectionState> get connectionState => _connectionState.stream;

  /// Synchronous read of the current connection state.
  ConnectionState? get currentConnectionState => _connectionState.value;

  /// Stream of incoming messages (agent → customer) and locally sent
  /// messages (customer → agent) — the Flutter layer uses this to drive the
  /// message list.
  Stream<Message> get messages => _messages.stream;

  /// Stream of non-fatal errors emitted by the client.
  Stream<ChataptorError> get errors => _errors.stream;

  /// Last [SiteConfig] received from the backend on `site:X` channel join.
  ///
  /// Available after a successful [connect] when the server returned a
  /// `site_config` block in its join response. `null` before the first
  /// successful connect and after [clearSession]. Survives [disconnect] so
  /// that header chrome (team name, online indicator) does not flash to
  /// a blank state during a reconnect cycle — matches the
  /// [currentMessages] policy.
  SiteConfig? get currentSiteConfig => _siteConfigStream.value;

  /// Stream of [SiteConfig] updates. Emits once per successful
  /// `site:X` join. Replays the current value to new listeners.
  Stream<SiteConfig> get siteConfigStream => _siteConfigStream.stream;

  /// Snapshot of agents currently reported as online for this site, in
  /// arrival order. The list is capped on the wire and typically holds
  /// at most a handful of entries.
  ///
  /// Empty when no `agent:available` event has arrived yet, or after the
  /// most recent `agents:offline` push. Survives [disconnect] so the
  /// header avatar stack does not flash to empty during a reconnect cycle.
  /// Cleared by [clearSession].
  List<AgentInfo> get currentOnlineAgents =>
      _onlineAgentsStream.value ?? const [];

  /// Stream of online-agent snapshots. Emits a fresh list each time the
  /// backend pushes `agent:available` or `agents:offline`. Replays the
  /// current snapshot to new listeners.
  Stream<List<AgentInfo>> get onlineAgentsStream => _onlineAgentsStream.stream;

  /// Opens the WebSocket, joins the site channel, creates a conversation, and
  /// joins the conversation channel. [Connected] is emitted only after the
  /// full handshake completes. Idempotent.
  Future<void> connect() async {
    _requireNotDisposed();
    if (currentConnectionState is Connected) return;
    await _enforceSessionIdleTimeout();
    _connectionState.add(const Connecting());

    final transportConfig = TransportConfig(
      url: _socketUrl(),
      params: await _buildSocketParams(),
      heartbeatInterval: config.transport.heartbeatInterval,
      reconnectionDelays: config.transport.reconnection.delays,
    );

    try {
      await _transport.connect(transportConfig);
      final siteJoinPayload = await _transport.joinChannel(
        _siteTopic(),
        _buildSiteJoinParams(),
      );
      _ingestSiteJoinPayload(siteJoinPayload);
    } on Object catch (err, st) {
      config.logger.log(
        ChataptorLogLevel.error,
        'connect failed',
        error: err,
        stackTrace: st,
      );
      final chataptorErr = NetworkError(
        'connect failed: $err',
        underlyingException: err,
        stackTrace: st,
      );
      _errors.add(chataptorErr);
      config.hooks.onError?.call(chataptorErr);
      _connectionState.add(const Disconnected(DisconnectReason.networkError));
      rethrow;
    }

    // Create conversation on the site channel and join its dedicated channel.
    final createPayload = <String, dynamic>{
      'user_agent': 'chataptor-flutter/0.2.0 (flutter)',
    };
    final customerLang = config.translation.customerLanguage;
    if (config.translation.enabled && customerLang != null) {
      createPayload['client_language'] = customerLang;
    }
    // When the customer is identified, surface name and email on the
    // conversation:create payload so the conversation gets the right
    // attribution from the start.
    final customer = config.customer;
    if (!customer.isAnonymous) {
      if (customer.name != null) createPayload['customerName'] = customer.name;
      if (customer.email != null) {
        createPayload['customerEmail'] = customer.email;
      }
    }
    final result = await _transport.push(
      _siteTopic(),
      'conversation:create',
      createPayload,
    );

    switch (result) {
      case PushOk(:final response):
        final convRaw = response['conversation'];
        if (convRaw is! Map) {
          _emitConnectError('conversation:create returned unexpected response');
          return;
        }
        final convId = (convRaw['conversationId'] ?? convRaw['conv_id'])
            ?.toString();
        if (convId == null || convId.isEmpty) {
          _emitConnectError('conversation:create returned no conversation id');
          return;
        }
        _conversationId = convId;
        Map<String, dynamic> joinPayload;
        try {
          joinPayload = await _transport.joinChannel(_conversationTopic(), {});
        } on Object catch (err, st) {
          config.logger.log(
            ChataptorLogLevel.error,
            'joining conversation channel failed',
            error: err,
            stackTrace: st,
          );
          _emitConnectError('joining conversation channel failed: $err');
          return;
        }
        _connectionState.add(const Connected());
        config.hooks.onConnectionStateChanged?.call(const Connected());
        _loadHistory(joinPayload);
        _injectWelcomeIfApplicable();

      case PushServerError(:final reason):
        _emitConnectError('conversation:create rejected by server: $reason');

      case PushTimeout():
        _emitConnectError('conversation:create timed out');

      case PushDisconnected():
        _emitConnectError('disconnected during conversation:create');
    }
  }

  void _emitConnectError(String message) {
    final err = NetworkError(message);
    _errors.add(err);
    config.hooks.onError?.call(err);
    _connectionState.add(const Disconnected(DisconnectReason.networkError));
  }

  /// Closes the WebSocket. Idempotent.
  Future<void> disconnect() async {
    if (_disposed) return;
    await _transport.disconnect();
    _conversationId = null;
    // Rebuild seen IDs from the message buffer so that history dedup works
    // correctly on the next connect() without re-emitting already-cached
    // messages to the stream, while still surfacing any new messages that
    // arrived while the socket was closed.
    _seenMessageIds
      ..clear()
      ..addAll(_messageHistory.map((m) => m.id).where((id) => id.isNotEmpty));
    _connectionState.add(const Disconnected(DisconnectReason.userRequested));
  }

  /// Sends a text [text]. Runs the `beforeSend` interceptor if set, then
  /// pushes the payload over the transport. Returns a [SendResult]
  /// reflecting the outcome.
  Future<SendResult> sendMessage(
    String text, {
    Map<String, dynamic>? metadata,
  }) async {
    _requireNotDisposed();
    _requireConnected();

    var draft = MessageDraft(body: text, metadata: metadata ?? const {});

    final beforeSend = config.hooks.beforeSend;
    if (beforeSend != null) {
      final modified = await beforeSend(draft);
      if (modified == null) {
        const err = ValidationError(
          'send cancelled by beforeSend interceptor',
          fieldErrors: {},
        );
        config.hooks.onMessageFailed?.call(err);
        return SendFailure(err, draft);
      }
      draft = modified;
    }

    final payload = <String, dynamic>{
      'text': draft.body,
      if (draft.metadata.isNotEmpty) 'metadata': draft.metadata,
    };

    final result = await _transport.push(
      _conversationTopic(),
      'message:send',
      payload,
    );

    return switch (result) {
      PushOk(:final response) => _handleSendOk(response, draft),
      PushServerError(:final reason) => SendFailure(
        ServerError('server rejected send: $reason'),
        draft,
      ),
      PushTimeout() => SendFailure(const NetworkError('send timed out'), draft),
      PushDisconnected() => SendFailure(
        const ConnectionLostError('disconnected while sending'),
        draft,
      ),
    };
  }

  /// Migrates the current session to a new [CustomerIdentity].
  ///
  /// Use this after the customer signs in to your app: the SDK swaps
  /// the active [CustomerIdentity] in [config] and — if currently
  /// connected — reconnects so the new identity is applied on the next
  /// channel join.
  ///
  /// **Continuity:** within an active session, the guest ID assigned
  /// during the prior anonymous session is preserved across the
  /// migration so conversation history follows the customer when they
  /// sign in. However, [ChataptorConfig.sessionIdleTimeout] takes
  /// precedence — when the persisted session has been idle past the
  /// configured timeout, the upcoming [connect] inside [identify]
  /// clears the guest session first and the identified customer joins
  /// on a fresh anonymous-then-identified thread.
  ///
  /// **State requirements:** must be called when the connection is
  /// either [Connected] or [Disconnected]. Throws [ChataptorStateError]
  /// when invoked during [Connecting] or [Reconnecting] — those states
  /// represent in-flight transitions where a concurrent disconnect /
  /// reconnect would race with the in-flight connect sequence.
  ///
  /// When [newIdentity] equals the current customer (value equality),
  /// [identify] is a no-op and resolves immediately.
  ///
  /// Safe to call before [connect]: only the configuration is updated;
  /// no premature reconnect is triggered.
  Future<void> identify(CustomerIdentity newIdentity) async {
    _requireNotDisposed();
    if (_config.customer == newIdentity) return;
    final state = currentConnectionState;
    if (state is Connecting || state is Reconnecting) {
      throw ChataptorStateError(
        'Cannot call identify() while the connection is in transition '
        '($state). Wait until the client is Connected or Disconnected, '
        'then retry.',
      );
    }
    final shouldReconnect = state is! Disconnected;
    if (shouldReconnect) {
      await disconnect();
    }
    _config = _config.copyWith(customer: newIdentity);
    if (shouldReconnect) {
      await connect();
    }
  }

  /// Clears the local session: deletes the stored guest ID and disconnects if
  /// currently connected. The next [connect] call will create a new anonymous
  /// identity and open a fresh conversation on the backend.
  ///
  /// Use this when the customer explicitly wants to start a new support thread,
  /// or when a merchant-defined session expiry has elapsed.
  Future<void> clearSession() async {
    _requireNotDisposed();
    await disconnect();
    await _guestIdStore.clear();
    await _storage.delete(_lastActivityStorageKey());
    _seenMessageIds.clear();
    _messageHistory.clear();
    _siteConfigStream.clear();
    _onlineAgentsStream.add(const []);
  }

  /// Releases every resource. After [dispose] the client is unusable.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _transport.dispose();
    await _connectionState.close();
    await _messages.close();
    await _errors.close();
    await _siteConfigStream.close();
    await _onlineAgentsStream.close();
  }

  void _ingestSiteJoinPayload(Map<String, dynamic> payload) {
    final raw = payload['site_config'];
    if (raw is! Map) return;
    final parsed = SiteConfig.fromJson(Map<String, dynamic>.from(raw));
    _siteConfigStream.add(parsed);
  }

  /// Renders the merchant-configured welcome message as the first agent
  /// bubble on a freshly-opened conversation.
  ///
  /// Skipped when:
  /// - no conversation is active (defensive — should never happen),
  /// - the local message buffer already contains messages (reconnect on
  ///   an existing thread — the customer has seen the welcome already),
  /// - no site_config arrived or the active language variant resolves to
  ///   `null`,
  /// - a message with the same deterministic id is already in
  ///   `_seenMessageIds` (defends against duplicate injection across
  ///   reconnect cycles where the buffer was cleared but the id cache
  ///   survived).
  ///
  /// The id is deterministic per conversation (`welcome-<convId>`) and
  /// gets added to `_seenMessageIds`, so even pathological repeats are
  /// idempotent.
  void _injectWelcomeIfApplicable() {
    final convId = _conversationId;
    if (convId == null) return;
    if (_messageHistory.isNotEmpty) return;
    final siteConfig = _siteConfigStream.value;
    if (siteConfig == null) return;
    final welcomeBody = siteConfig.activeWelcomeMessage(
      config.translation.customerLanguage,
    );
    if (welcomeBody == null || welcomeBody.isEmpty) return;

    final welcomeId = 'welcome-$convId';
    if (_seenMessageIds.contains(welcomeId)) return;
    _seenMessageIds.add(welcomeId);

    final welcome = Message(
      id: welcomeId,
      conversationId: convId,
      body: welcomeBody,
      author: MessageAuthor.agent,
      timestamp: DateTime.now().toUtc(),
      type: MessageType.text,
      deliveryChannel: DeliveryChannel.websocket,
      status: MessageStatus.sent,
    );
    _messageHistory.add(welcome);
    _messages.add(welcome);
  }

  Uri _socketUrl() {
    final scheme = config.apiUrl.scheme == 'https' ? 'wss' : 'ws';
    return config.apiUrl.replace(
      scheme: scheme,
      path: '${config.apiUrl.path}/socket/websocket',
    );
  }

  Future<Map<String, dynamic>> _buildSocketParams() async {
    // guestId is always sent — even for identified customers. Omitting
    // it on the identified path would break conversation continuity
    // when a customer migrates from anonymous to identified mid-session
    // via [identify].
    final params = <String, dynamic>{
      'widgetKey': config.widgetKey,
      'siteId': config.siteId,
      'platform': 'flutter',
      'guestId': await _guestIdStore.getOrCreate(),
    };

    final customer = config.customer;
    if (!customer.isAnonymous) {
      if (customer.id != null) params['customerId'] = customer.id;
      // Identified customer attributes ship in a single customerData
      // map alongside an optional verification hash and any
      // merchant-provided custom fields.
      final customerData = <String, dynamic>{
        if (customer.email != null) 'email': customer.email,
        if (customer.name != null) 'name': customer.name,
        if (customer.verificationHash != null)
          'hash': customer.verificationHash,
        ...customer.customData,
      };
      if (customerData.isNotEmpty) {
        params['customerData'] = customerData;
      }
    }

    if (config.translation.enabled &&
        config.translation.customerLanguage != null) {
      params['browserLanguage'] = config.translation.customerLanguage;
    }
    return params;
  }

  void _handleTransportState(TransportConnectionState state) {
    // TransportConnected is intentionally not mapped here — connect() emits
    // Connected only after the full conversation handshake completes.
    final mapped = switch (state) {
      TransportConnecting() => const Connecting(),
      TransportConnected() => null,
      TransportReconnecting(:final attemptNumber, :final nextAttemptIn) =>
        Reconnecting(
          attemptNumber: attemptNumber,
          nextAttemptIn: nextAttemptIn,
        ),
      TransportDisconnected() => const Disconnected(
        DisconnectReason.networkError,
      ),
    };
    if (mapped == null) return;
    _connectionState.add(mapped);
    config.hooks.onConnectionStateChanged?.call(mapped);
  }

  void _handleTransportEvent(TransportEvent event) {
    switch (event) {
      case MessageReceived(:final event, :final payload):
        switch (event) {
          case 'message:received':
            unawaited(_handleMessageReceived(payload));
          case 'agent:available':
            _handleAgentAvailable(payload);
          case 'agents:offline':
            _handleAgentsOffline();
        }
      case ChannelClosed():
        // Propagate as reconnecting — transport will also emit state.
        break;
      case ChannelError(:final message):
        _errors.add(NetworkError(message));
    }
  }

  void _handleAgentAvailable(Map<String, dynamic> payload) {
    final agents = AgentInfo.listFromPresencePayload(payload);
    _onlineAgentsStream.add(List<AgentInfo>.unmodifiable(agents));
  }

  void _handleAgentsOffline() {
    _onlineAgentsStream.add(const []);
  }

  SendResult _handleSendOk(Map<String, dynamic> response, MessageDraft draft) {
    final msgId = _extractMsgId(response);
    if (msgId != null) _seenMessageIds.add(msgId);
    unawaited(_touchLastActivity());
    return SendSuccess(draft);
  }

  String? _extractMsgId(Map<String, dynamic> response) {
    final msg = response['message'];
    if (msg is! Map) return null;
    final id = (msg['msg_id'] ?? msg['id'])?.toString();
    return (id != null && id.isNotEmpty) ? id : null;
  }

  Future<void> _handleMessageReceived(Map<String, dynamic> payload) async {
    var message = parseIncomingMessage(payload);

    if (message.id.isNotEmpty) {
      if (_seenMessageIds.contains(message.id)) return;
      _seenMessageIds.add(message.id);
    }

    final beforeReceive = config.hooks.beforeReceive;
    if (beforeReceive != null) {
      final modified = await beforeReceive(message);
      if (modified == null) return;
      message = modified;
    }

    _messageHistory.add(message);
    _messages.add(message);
    unawaited(_touchLastActivity());
    config.hooks.onMessageReceived?.call(message);
  }

  void _loadHistory(Map<String, dynamic> joinPayload) {
    final raw = joinPayload['messages'];
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! Map) continue;
      final payload = Map<String, dynamic>.from(item);
      final message = parseIncomingMessage(payload);
      if (message.id.isNotEmpty) {
        if (_seenMessageIds.contains(message.id)) continue;
        _seenMessageIds.add(message.id);
      }
      _messageHistory.add(message);
      _messages.add(message);
    }
  }

  void _requireNotDisposed() {
    if (_disposed) {
      throw ChataptorStateError('ChataptorClient was disposed');
    }
  }

  void _requireConnected() {
    if (currentConnectionState is! Connected) {
      throw ChataptorStateError(
        'ChataptorClient is not connected — call connect() first',
      );
    }
  }

  /// Exposed for internal testing only.
  AgentInfo? get debugAgent => null;

  /// Exposed for internal testing only.
  ChataptorStorage get debugStorage => _storage;
}
