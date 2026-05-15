import 'dart:async';

import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/scope.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:chataptor_flutter/src/widgets/composer.dart';
import 'package:chataptor_flutter/src/widgets/message_list.dart';
import 'package:flutter/material.dart' hide ConnectionState;

/// Full-screen chat UI. Pushed via `Navigator.push` or used as a body.
///
/// Composes [ChataptorMessageList] and [ChataptorComposer] and owns the
/// stateful connection to the [ChataptorClient] from [ChataptorScope.of].
class ChataptorChatScreen extends StatefulWidget {
  /// Creates a [ChataptorChatScreen].
  const ChataptorChatScreen({super.key, this.theme, this.title});

  /// Optional theme override.
  final ChataptorTheme? theme;

  /// Title displayed in the AppBar. Defaults to `'Support'` when omitted.
  final String? title;

  @override
  State<ChataptorChatScreen> createState() => _ChataptorChatScreenState();
}

class _ChataptorChatScreenState extends State<ChataptorChatScreen> {
  final List<Message> _messages = [];
  StreamSubscription<Message>? _messagesSub;
  StreamSubscription<ConnectionState>? _connectionStateSub;
  bool _connectStarted = false;
  bool _isLoading = true;
  bool _canSendMessage = false;
  ChataptorClient? _ownedClient;

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

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        title: Text(widget.title ?? 'Support', style: theme.headerTextStyle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: loc.closeChat,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ChataptorMessageList(
              messages: _messages,
              theme: theme,
              isLoading: _isLoading,
            ),
          ),
          ChataptorComposer(
            theme: theme,
            enabled: _canSendMessage,
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
