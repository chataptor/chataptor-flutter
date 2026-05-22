import 'dart:async';

import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/scope.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:chataptor_flutter/src/widgets/chat_header.dart';
import 'package:chataptor_flutter/src/widgets/composer.dart';
import 'package:chataptor_flutter/src/widgets/message_list.dart';
import 'package:flutter/material.dart' hide ConnectionState;

/// Full-screen chat UI. Pushed via `Navigator.push` or used as a body.
///
/// Composes [ChataptorMessageList] and [ChataptorComposer] and owns the
/// stateful connection to the [ChataptorClient] from [ChataptorScope.of].
class ChataptorChatScreen extends StatefulWidget {
  /// Creates a [ChataptorChatScreen].
  const ChataptorChatScreen({
    super.key,
    this.theme,
    this.title,
    this.showPoweredBy = true,
    this.showAppBar = true,
  });

  /// Optional theme override.
  final ChataptorTheme? theme;

  /// Title displayed in the AppBar. Defaults to `'Support'` when omitted.
  final String? title;

  /// Whether to show the "Powered by Chataptor" attribution strip between
  /// the message list and the composer. Defaults to `true`. Set to `false`
  /// to hide the attribution (white-label).
  final bool showPoweredBy;

  /// Whether the screen renders its own [AppBar]. Defaults to `true`.
  ///
  /// Set to `false` when embedding the screen inside a bottom sheet, dialog,
  /// or any host that already provides its own chrome (drag handle, close
  /// button, etc.). The agent-presence header still renders inline at the
  /// top of the body so customers keep the "who's online" cue regardless
  /// of how the chat is mounted.
  final bool showAppBar;

  @override
  State<ChataptorChatScreen> createState() => _ChataptorChatScreenState();
}

class _ChataptorChatScreenState extends State<ChataptorChatScreen> {
  final List<Message> _messages = [];
  StreamSubscription<Message>? _messagesSub;
  StreamSubscription<ConnectionState>? _connectionStateSub;
  StreamSubscription<SiteConfig>? _siteConfigSub;
  StreamSubscription<List<AgentInfo>>? _onlineAgentsSub;
  bool _connectStarted = false;
  bool _isLoading = true;
  bool _canSendMessage = false;
  ChataptorClient? _ownedClient;
  SiteConfig? _siteConfig;
  List<AgentInfo> _onlineAgents = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_connectStarted) return;
    _connectStarted = true;
    final client = ChataptorScope.of(context).client;
    _ownedClient = client;

    // Populate from cache immediately so there is no empty-state flash on
    // re-entry. The stream subscription below only delivers truly new messages
    // (history dedup happens at the client level via _seenMessageIds).
    _messages.addAll(client.currentMessages);
    _siteConfig = client.currentSiteConfig;
    _onlineAgents = client.currentOnlineAgents;

    _siteConfigSub = client.siteConfigStream.listen((cfg) {
      if (mounted) setState(() => _siteConfig = cfg);
    });
    _onlineAgentsSub = client.onlineAgentsStream.listen((agents) {
      if (mounted) setState(() => _onlineAgents = agents);
    });

    _connectionStateSub = client.connectionState.listen((state) {
      final loading = state is Connecting || state is Reconnecting;
      final canSend = state is Connected;
      if (mounted && (loading != _isLoading || canSend != _canSendMessage)) {
        setState(() {
          _isLoading = loading;
          _canSendMessage = canSend;
        });
      }
    });
    _messagesSub = client.messages.listen((m) {
      setState(() => _messages.add(m));
    });
    unawaited(client.connect());
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _connectionStateSub?.cancel();
    _siteConfigSub?.cancel();
    _onlineAgentsSub?.cancel();

    // Mirror the `lazy` contract from spec §4 #12: the screen that opened
    // the socket is responsible for closing it. `foregroundActive` mode is
    // owned by `ChataptorLifecycleObserver` — we must NOT pre-empt it.
    final client = _ownedClient;
    if (client != null &&
        client.config.transport.connectionMode == ConnectionMode.lazy) {
      unawaited(client.disconnect());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? ChataptorTheme.matching(context);
    final loc = ChataptorLocalizations.of(context);
    final client = ChataptorScope.of(context).client;

    final resolvedTitle =
        widget.title ??
        _siteConfig?.activeHeaderTitle(
          client.config.translation.customerLanguage,
        );

    final isOffline = _siteConfig?.offlineMode == OfflineMode.manualOffline;
    final variant = _siteConfig?.variantFor(
      client.config.translation.customerLanguage,
    );
    final offlineTitle = variant?.offlineTitle ?? loc.offlineBannerTitle;
    final offlineSubtitle =
        variant?.offlineSubtitle ?? loc.offlineBannerSubtitle;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: theme.surfaceColor,
              titleSpacing: 0,
              title: ChataptorChatHeader(
                title: resolvedTitle,
                onlineAgents: _onlineAgents,
                theme: theme,
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: loc.closeChat,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: Column(
        children: [
          if (!widget.showAppBar)
            Container(
              color: theme.surfaceColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ChataptorChatHeader(
                title: resolvedTitle,
                onlineAgents: _onlineAgents,
                theme: theme,
              ),
            ),
          Expanded(
            child: ChataptorMessageList(
              messages: _messages,
              theme: theme,
              isLoading: _isLoading,
            ),
          ),
          if (isOffline)
            _OfflineBanner(
              title: offlineTitle,
              subtitle: offlineSubtitle,
              theme: theme,
            ),
          if (widget.showPoweredBy) const _PoweredByBanner(),
          ChataptorComposer(
            theme: theme,
            enabled: _canSendMessage && !isOffline,
            onSend: (text) async {
              if (client.currentConnectionState is! Connected) return;
              final result = await client.sendMessage(text);
              if (result is SendSuccess) {
                // Optimistically render the sent draft as a message.
                setState(() {
                  _messages.add(
                    Message(
                      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
                      conversationId: '',
                      body: text,
                      author: MessageAuthor.customer,
                      timestamp: DateTime.now().toUtc(),
                      type: MessageType.text,
                      deliveryChannel: DeliveryChannel.websocket,
                      status: MessageStatus.sent,
                    ),
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.title,
    required this.subtitle,
    required this.theme,
  });

  final String title;
  final String subtitle;
  final ChataptorTheme theme;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      width: double.infinity,
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoweredByBanner extends StatelessWidget {
  const _PoweredByBanner();

  @override
  Widget build(BuildContext context) {
    final loc = ChataptorLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            children: [
              TextSpan(text: loc.poweredByPrefix),
              const TextSpan(
                text: 'chataptor.com',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
