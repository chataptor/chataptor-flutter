import 'dart:async';

import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart' hide ConnectionState;

/// Demonstrates the "headless" integration path: no Chataptor widgets used,
/// only the [ChataptorClient] from the singleton. The merchant owns 100% of
/// the UI and reaches into the SDK purely for transport + state.
///
/// Mirrors the [ChataptorChatScreen] lifecycle contract:
/// - calls [ChataptorClient.connect] on mount,
/// - calls [ChataptorClient.disconnect] on unmount when in lazy mode.
class HeadlessChatScreen extends StatefulWidget {
  /// Creates a headless demo screen.
  const HeadlessChatScreen({super.key});

  @override
  State<HeadlessChatScreen> createState() => _HeadlessChatScreenState();
}

class _HeadlessChatScreenState extends State<HeadlessChatScreen> {
  final ChataptorClient _client = Chataptor.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _messages = [];
  ConnectionState _connection = const Disconnected(
    DisconnectReason.userRequested,
  );
  StreamSubscription<Message>? _messagesSub;
  StreamSubscription<ConnectionState>? _connectionSub;
  bool _sending = false;

  @override
  void initState() {
    super.initState();

    _messages.addAll(_client.currentMessages);
    final current = _client.currentConnectionState;
    if (current != null) _connection = current;

    _connectionSub = _client.connectionState.listen((state) {
      if (!mounted) return;
      setState(() => _connection = state);
    });
    _messagesSub = _client.messages.listen((m) {
      if (!mounted) return;
      setState(() => _messages.add(m));
      _scrollToBottom();
    });

    unawaited(_client.connect());
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _connectionSub?.cancel();
    if (_client.config.transport.connectionMode == ConnectionMode.lazy) {
      unawaited(_client.disconnect());
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _connection is! Connected || _sending) return;
    setState(() => _sending = true);
    final result = await _client.sendMessage(text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (result is SendSuccess) {
        _controller.clear();
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
        _scrollToBottom();
      } else if (result is SendFailure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Send failed: ${result.error}')));
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _connection is Connected && !_sending;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Headless (custom UI)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: _ConnectionBadge(state: _connection),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet — say hi.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _Bubble(message: _messages[i]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: canSend,
                      decoration: InputDecoration(
                        hintText: canSend
                            ? 'Type a message…'
                            : 'Waiting for connection…',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: canSend ? _send : null,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.state});

  final ConnectionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      Connected() => ('Connected', Colors.green),
      Connecting() => ('Connecting…', Colors.orange),
      Reconnecting(:final attemptNumber) => (
        'Reconnecting (attempt $attemptNumber)…',
        Colors.orange,
      ),
      Disconnected(:final reason) => (
        'Disconnected (${reason.name})',
        Colors.red,
      ),
    };
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.author == MessageAuthor.customer;
    final shownBody =
        !isCustomer && (message.bodyTranslated?.isNotEmpty ?? false)
        ? message.bodyTranslated!
        : message.body;
    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCustomer ? const Color(0xFFE3F2FD) : const Color(0xFFF1F1F4),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isCustomer ? 14 : 4),
            bottomRight: Radius.circular(isCustomer ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shownBody, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 2),
            Text(
              '${message.author.name} · ${_formatTime(message.timestamp)}',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final local = t.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
