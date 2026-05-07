import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:flutter/material.dart';

/// Async send callback — receives the user's trimmed text.
typedef ChataptorComposerSend = Future<void> Function(String text);

/// Input + send button. Responsible for turning user input into a send
/// call; parent owns the networking via [onSend].
class ChataptorComposer extends StatefulWidget {
  /// Creates a [ChataptorComposer].
  const ChataptorComposer({
    super.key,
    required this.onSend,
    this.theme,
  });

  /// Called when the user taps send on non-empty text.
  final ChataptorComposerSend onSend;

  /// Optional theme override.
  final ChataptorTheme? theme;

  @override
  State<ChataptorComposer> createState() => _ChataptorComposerState();
}

class _ChataptorComposerState extends State<ChataptorComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && _controller.text.trim().isNotEmpty;

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? ChataptorTheme.matching(context);
    final loc = ChataptorLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: loc.typeMessage,
                textField: true,
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: loc.typeMessage,
                    filled: true,
                    fillColor: theme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: loc.sendMessage,
              onPressed: _canSend ? _handleSend : null,
              icon: const Icon(Icons.send_rounded),
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
