import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:chataptor_flutter/src/widgets/message_bubble.dart';
import 'package:flutter/material.dart';

/// A scrollable list of [Message]s. v0.1.0 uses [ListView.builder] with
/// `reverse: true` for new-message-at-bottom semantics. v0.6.0 migrates
/// to `super_sliver_list` for 1000+-message performance (per design spec
/// §7.10).
class ChataptorMessageList extends StatelessWidget {
  /// Creates a [ChataptorMessageList].
  const ChataptorMessageList({
    required this.messages,
    super.key,
    this.theme,
    this.isLoading = false,
  });

  /// Messages to render. Must be sorted oldest-first.
  final List<Message> messages;

  /// Optional theme override.
  final ChataptorTheme? theme;

  /// When `true` and [messages] is empty, shows a loading indicator instead of
  /// the empty-state text. Has no effect when [messages] is non-empty.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final effectiveTheme = theme ?? ChataptorTheme.matching(context);
    final loc = ChataptorLocalizations.of(context);

    if (messages.isEmpty) {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            loc.emptyState,
            style: effectiveTheme.bodyTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return RepaintBoundary(
          child: ChataptorMessageBubble(
            message: message,
            theme: effectiveTheme,
          ),
        );
      },
    );
  }
}
