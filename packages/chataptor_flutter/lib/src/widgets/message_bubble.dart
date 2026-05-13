import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:flutter/material.dart';

/// Renders a single [Message]. Layout alternates based on [Message.author]
/// — customer messages align right, agent/bot messages align left. When
/// the message has a translation, both bodies are shown.
class ChataptorMessageBubble extends StatelessWidget {
  /// Creates a [ChataptorMessageBubble].
  const ChataptorMessageBubble({required this.message, super.key, this.theme});

  /// The message to render.
  final Message message;

  /// Optional theme override. Falls back to [ChataptorTheme.matching] if
  /// not supplied.
  final ChataptorTheme? theme;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? ChataptorTheme.matching(context);
    final fromCustomer = message.author == MessageAuthor.customer;
    final bg = fromCustomer
        ? effectiveTheme.customerBubbleColor
        : effectiveTheme.agentBubbleColor;
    final fg = fromCustomer
        ? effectiveTheme.customerBubbleTextColor
        : effectiveTheme.agentBubbleTextColor;

    final semanticsLabel = _buildSemanticsLabel(fromCustomer);

    return Semantics(
      label: semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: fromCustomer
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: effectiveTheme.bubbleRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildContent(effectiveTheme, fg, fromCustomer),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    ChataptorTheme theme,
    Color foreground,
    bool fromCustomer,
  ) {
    return [
      Text(
        _displayBody(fromCustomer),
        style: theme.bodyTextStyle.copyWith(color: foreground),
      ),
    ];
  }

  /// Returns the text to display: translated body for agent/bot messages when
  /// a translation is available, otherwise the source body.
  String _displayBody(bool fromCustomer) {
    if (!fromCustomer) {
      final t = message.bodyTranslated;
      if (t != null && t.isNotEmpty) return t;
    }
    return message.body;
  }

  String _buildSemanticsLabel(bool fromCustomer) {
    final who = fromCustomer ? 'Sent' : 'Received';
    return '$who message: ${_displayBody(fromCustomer)}';
  }
}
