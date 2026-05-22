import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:chataptor_flutter/src/widgets/message_bubble.dart';
import 'package:flutter/material.dart';

/// A scrollable list of [Message]s. Uses [ListView.builder] with
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
        return const _MessageSkeleton(key: ValueKey('chataptor-skeleton'));
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

class _MessageSkeleton extends StatefulWidget {
  const _MessageSkeleton({super.key});

  @override
  State<_MessageSkeleton> createState() => _MessageSkeletonState();
}

class _MessageSkeletonState extends State<_MessageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        children: const [
          _SkeletonBubble(widthFactor: 0.62, isLeft: true, height: 44),
          SizedBox(height: 8),
          _SkeletonBubble(widthFactor: 0.44, isLeft: false, height: 44),
          SizedBox(height: 8),
          _SkeletonBubble(widthFactor: 0.58, isLeft: true, height: 64),
          SizedBox(height: 8),
          _SkeletonBubble(widthFactor: 0.40, isLeft: false, height: 44),
        ],
      ),
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  const _SkeletonBubble({
    required this.widthFactor,
    required this.isLeft,
    required this.height,
  });

  final double widthFactor;
  final bool isLeft;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
