import 'dart:async';

import 'package:chataptor/src/auth/guest_id_store.dart';
import 'package:chataptor/src/client/connection_state.dart';
import 'package:chataptor/src/client/message_parser.dart';
import 'package:chataptor/src/client/send_result.dart';
import 'package:chataptor/src/config/chataptor_config.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/logger/chataptor_logger.dart';
import 'package:chataptor/src/models/agent_info.dart';
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
  ChataptorClient.internal({
    required this.config,
    required ChatTransport transport,
    ChataptorStorage? storage,
  }) : _transport = transport,
       _storage = storage ?? config.storage ?? InMemoryChataptorStorage(),
       _guestIdStore = GuestIdStore(
         storage: storage ?? config.storage ?? InMemoryChataptorStorage(),
         siteId: config.siteId,
       ) {
    _connectionState.add(const Disconnected(DisconnectReason.userRequested));
    _transport.connectionState.listen(_handleTransportState);
    _transport.events.listen(_handleTransportEvent);
  }

  /// The active configuration.
  final ChataptorConfig config;

  final ChatTransport _transport;
  final ChataptorStorage _storage;
  final GuestIdStore _guestIdStore;

  final ValueStream<ConnectionState> _connectionState =
      ValueStream<ConnectionState>();
  final StreamController<Message> _messages =
      StreamController<Message>.broadcast();
  final StreamController<ChataptorError> _errors =
      StreamController<ChataptorError>.broadcast();

  bool _disposed = false;

  /// Active conversation ID, set after `conversation:create` succeeds.
  String? _conversationId;

  String _siteTopic() => 'site:${config.siteId}';
  String _conversationTopic() => 'conversation:$_conversationId';

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

  /// Opens the WebSocket, joins the site channel, creates a conversation, and
  /// joins the conversation channel. [Connected] is emitted only after the
  /// full handshake completes. Idempotent.
  Future<void> connect() async {
    _requireNotDisposed();
    if (currentConnectionState is Connected) return;
    _connectionState.add(const Connecting());

    final transportConfig = TransportConfig(
      url: _socketUrl(),
      params: await _buildSocketParams(),
      heartbeatInterval: config.transport.heartbeatInterval,
      reconnectionDelays: config.transport.reconnection.delays,
    );

    try {
      await _transport.connect(transportConfig);
      await _transport.joinChannel(_siteTopic(), {});
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
    final result = await _transport.push(_siteTopic(), 'conversation:create', {
      'user_agent': 'chataptor-flutter/0.1.0 (flutter)',
    });

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
        await _transport.joinChannel(_conversationTopic(), {});
        _connectionState.add(const Connected());
        config.hooks.onConnectionStateChanged?.call(const Connected());

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
      PushOk() => SendSuccess(draft),
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

  /// Releases every resource. After [dispose] the client is unusable.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _transport.dispose();
    await _connectionState.close();
    await _messages.close();
    await _errors.close();
  }

  Uri _socketUrl() {
    final scheme = config.apiUrl.scheme == 'https' ? 'wss' : 'ws';
    return config.apiUrl.replace(
      scheme: scheme,
      path: '${config.apiUrl.path}/socket/websocket',
    );
  }

  Future<Map<String, dynamic>> _buildSocketParams() async {
    final params = <String, dynamic>{
      'widgetKey': config.widgetKey,
      'siteId': config.siteId,
      'platform': 'flutter',
    };

    final customer = config.customer;
    if (customer.isAnonymous) {
      params['guestId'] = await _guestIdStore.getOrCreate();
    } else {
      if (customer.id != null) params['customerId'] = customer.id;
      if (customer.email != null) params['customerEmail'] = customer.email;
      if (customer.name != null) params['customerName'] = customer.name;
      if (customer.verificationHash != null) {
        params['customerData'] = {
          'hash': customer.verificationHash,
          if (customer.email != null) 'email': customer.email,
          ...customer.customData,
        };
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
      case MessageReceived():
        unawaited(_handleMessageReceived(event));
      case ChannelClosed():
        // Propagate as reconnecting — transport will also emit state.
        break;
      case ChannelError(:final message):
        _errors.add(NetworkError(message));
    }
  }

  Future<void> _handleMessageReceived(MessageReceived event) async {
    if (event.event != 'message:received') return;
    var message = parseIncomingMessage(event.payload);

    final beforeReceive = config.hooks.beforeReceive;
    if (beforeReceive != null) {
      final modified = await beforeReceive(message);
      if (modified == null) return;
      message = modified;
    }

    _messages.add(message);
    config.hooks.onMessageReceived?.call(message);
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
