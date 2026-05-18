import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/l10n/chataptor_localizations.dart';
import 'package:chataptor_flutter/src/theme/chataptor_theme.dart';
import 'package:flutter/material.dart';

/// Header chrome for the chat screen — mirrors the layout of the
/// production web widget (avatar stack of online agents, configured team
/// name, live Online/Offline indicator).
///
/// Designed to live inside an [AppBar.title] slot. The avatar stack
/// collapses to a `+N` overflow badge after three visible avatars to
/// preserve room for the title on small screens.
class ChataptorChatHeader extends StatelessWidget {
  /// Creates a [ChataptorChatHeader].
  const ChataptorChatHeader({
    required this.onlineAgents,
    required this.theme,
    super.key,
    this.title,
    this.avatarSize = 32,
    this.avatarStrokeWidth = 2,
  });

  /// Team name rendered as the header's primary label (e.g.
  /// `"Customer Support"`). Falls back to `"Support"` when null.
  final String? title;

  /// Agents the backend currently reports as online for this site.
  /// Pass `client.currentOnlineAgents` or bind via `onlineAgentsStream`.
  final List<AgentInfo> onlineAgents;

  /// Visual palette source.
  final ChataptorTheme theme;

  /// Diameter (logical pixels) of each avatar bubble.
  final double avatarSize;

  /// Width of the border drawn between overlapping avatars to make the
  /// stacking visually crisp.
  final double avatarStrokeWidth;

  /// Maximum number of agents rendered inline. Extras roll up into a
  /// `+N` badge.
  static const int maxVisibleAvatars = 3;

  @override
  Widget build(BuildContext context) {
    final loc = ChataptorLocalizations.of(context);
    final resolvedTitle = title ?? loc.headerDefaultTitle;
    final isOnline = onlineAgents.isNotEmpty;
    final statusLabel = isOnline ? loc.headerOnline : loc.headerOffline;
    final statusColor = isOnline
        ? const Color(0xFF22C55E)
        : const Color(0xFF9CA3AF);

    final agentCount = onlineAgents.length;
    final agentNoun = agentCount == 1 ? 'agent' : 'agents';
    final semanticsLabel = isOnline
        ? '$resolvedTitle. $agentCount $agentNoun online'
        : '$resolvedTitle. ${loc.headerOffline}';

    return Semantics(
      label: semanticsLabel,
      container: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onlineAgents.isNotEmpty) ...[
              _AvatarStack(
                agents: onlineAgents,
                size: avatarSize,
                strokeWidth: avatarStrokeWidth,
                surfaceColor: theme.surfaceColor,
                fallbackTextColor: theme.headerTextStyle.color ?? Colors.white,
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    resolvedTitle,
                    style: theme.headerTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: theme.translationLabelStyle.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.agents,
    required this.size,
    required this.strokeWidth,
    required this.surfaceColor,
    required this.fallbackTextColor,
  });

  final List<AgentInfo> agents;
  final double size;
  final double strokeWidth;
  final Color surfaceColor;
  final Color fallbackTextColor;

  @override
  Widget build(BuildContext context) {
    final visibleCount = agents.length > ChataptorChatHeader.maxVisibleAvatars
        ? ChataptorChatHeader.maxVisibleAvatars
        : agents.length;
    final overflow = agents.length - visibleCount;
    final visibleAgents = agents.take(visibleCount).toList(growable: false);
    final overlap = size * 0.35;
    final totalSlots = visibleCount + (overflow > 0 ? 1 : 0);
    final width = totalSlots == 0
        ? 0.0
        : size + (totalSlots - 1) * (size - overlap);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < visibleAgents.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: _Avatar(
                agent: visibleAgents[i],
                size: size,
                strokeWidth: strokeWidth,
                surfaceColor: surfaceColor,
                fallbackTextColor: fallbackTextColor,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visibleCount * (size - overlap),
              child: _OverflowBadge(
                count: overflow,
                size: size,
                strokeWidth: strokeWidth,
                surfaceColor: surfaceColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.agent,
    required this.size,
    required this.strokeWidth,
    required this.surfaceColor,
    required this.fallbackTextColor,
  });

  final AgentInfo agent;
  final double size;
  final double strokeWidth;
  final Color surfaceColor;
  final Color fallbackTextColor;

  @override
  Widget build(BuildContext context) {
    final url = agent.avatarUrl;
    final initials = agent.initials;
    final bgColor = initials != null
        ? _parseHex(initials.color, fallback: const Color(0xFF6750A4))
        : const Color(0xFF6750A4);
    final letters = initials?.letters ?? _initialsFromName(agent.name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(color: surfaceColor, width: strokeWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  _InitialsLabel(letters: letters, color: fallbackTextColor),
            )
          : _InitialsLabel(letters: letters, color: fallbackTextColor),
    );
  }
}

class _InitialsLabel extends StatelessWidget {
  const _InitialsLabel({required this.letters, required this.color});

  final String letters;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letters,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({
    required this.count,
    required this.size,
    required this.strokeWidth,
    required this.surfaceColor,
  });

  final int count;
  final double size;
  final double strokeWidth;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE5E7EB),
        border: Border.all(color: surfaceColor, width: strokeWidth),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Color _parseHex(String hex, {required Color fallback}) {
  var s = hex.replaceAll('#', '').trim();
  if (s.isEmpty) return fallback;
  if (s.length == 6) s = 'FF$s';
  if (s.length != 8) return fallback;
  final value = int.tryParse(s, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}

String _initialsFromName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
