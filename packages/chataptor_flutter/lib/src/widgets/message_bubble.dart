import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:flutter/material.dart';

/// Renders a single [Message]. Layout alternates based on [Message.author]
/// — customer messages align right, agent/bot messages align left. When
/// the message has a translation, both bodies are shown.
class ChataptorMessageBubble extends StatelessWidget {
  /// Creates a [ChataptorMessageBubble].
  const ChataptorMessageBubble({
    super.key,
    required this.message,
    this.theme,
  });

  /// The message to render.
  final Message message;

  /// Optional theme override. Falls back to [ChataptorTheme.matching] if
  /// not supplied.
  final ChataptorTheme? theme;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? ChataptorTheme.matching(context);
    final loc = ChataptorLocalizations.of(context);
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
          mainAxisAlignment:
              fromCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                      children: _buildContent(effectiveTheme, loc, fg),
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
    ChataptorLocalizations loc,
    Color foreground,
  ) {
    final widgets = <Widget>[
      Text(
        message.body,
        style: theme.bodyTextStyle.copyWith(color: foreground),
      ),
    ];

    final translated = message.bodyTranslated;
    if (translated != null && translated.isNotEmpty) {
      widgets.add(const SizedBox(height: 6));
      widgets.add(
        Text(
          translated,
          style: theme.bodyTextStyle.copyWith(
            color: foreground.withValues(alpha: 0.8),
          ),
        ),
      );
      final lang = message.sourceLanguage ?? '';
      widgets.add(const SizedBox(height: 2));
      widgets.add(
        Text(
          loc.translatedLabel.replaceFirst('{language}', lang),
          style: theme.translationLabelStyle,
        ),
      );
    }
    return widgets;
  }

  String _buildSemanticsLabel(bool fromCustomer) {
    final who = fromCustomer ? 'Sent' : 'Received';
    return '$who message: ${message.body}';
  }
}
