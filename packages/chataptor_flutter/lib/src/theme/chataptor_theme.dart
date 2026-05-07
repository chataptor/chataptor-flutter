import 'package:flutter/material.dart';

/// Visual theme for Chataptor widgets. Constructed either as a standalone
/// palette ([ChataptorTheme.light]) or derived from the ambient
/// Material [ThemeData] ([ChataptorTheme.matching]).
///
/// Dark and system presets ship in a later milestone (v0.5.0).
@immutable
class ChataptorTheme {
  /// Creates a [ChataptorTheme] with every colour and geometry explicit.
  const ChataptorTheme({
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.customerBubbleColor,
    required this.customerBubbleTextColor,
    required this.agentBubbleColor,
    required this.agentBubbleTextColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.bubbleRadius,
    required this.headerTextStyle,
    required this.bodyTextStyle,
    required this.translationLabelStyle,
  });

  /// Sensible defaults for a light-mode app. Use as a starting point.
  factory ChataptorTheme.light() => const ChataptorTheme(
    primaryColor: Color(0xFF6750A4),
    onPrimaryColor: Colors.white,
    customerBubbleColor: Color(0xFFEADDFF),
    customerBubbleTextColor: Color(0xFF21005D),
    agentBubbleColor: Color(0xFFF4F4F5),
    agentBubbleTextColor: Color(0xFF1A1A1A),
    backgroundColor: Colors.white,
    surfaceColor: Color(0xFFFAFAFA),
    bubbleRadius: BorderRadius.all(Radius.circular(18)),
    headerTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyTextStyle: TextStyle(fontSize: 14, height: 1.4),
    translationLabelStyle: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
  );

  /// Derives a [ChataptorTheme] from the ambient [ThemeData] so the SDK
  /// blends with the host app automatically.
  factory ChataptorTheme.matching(BuildContext context) {
    final material = Theme.of(context);
    final colors = material.colorScheme;
    return ChataptorTheme(
      primaryColor: colors.primary,
      onPrimaryColor: colors.onPrimary,
      customerBubbleColor: colors.primaryContainer,
      customerBubbleTextColor: colors.onPrimaryContainer,
      agentBubbleColor: colors.surfaceContainerHighest,
      agentBubbleTextColor: colors.onSurface,
      backgroundColor: colors.surface,
      surfaceColor: colors.surfaceContainerLow,
      bubbleRadius: const BorderRadius.all(Radius.circular(18)),
      headerTextStyle:
          material.textTheme.titleMedium ??
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyTextStyle:
          material.textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
      translationLabelStyle:
          material.textTheme.bodySmall?.copyWith(color: colors.outline) ??
          const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  /// Accent colour used for primary buttons.
  final Color primaryColor;

  /// Foreground colour on [primaryColor] surfaces.
  final Color onPrimaryColor;

  /// Background of customer message bubbles.
  final Color customerBubbleColor;

  /// Text colour inside customer bubbles.
  final Color customerBubbleTextColor;

  /// Background of agent message bubbles.
  final Color agentBubbleColor;

  /// Text colour inside agent bubbles.
  final Color agentBubbleTextColor;

  /// Background colour of the chat screen.
  final Color backgroundColor;

  /// Background colour of the composer/header strip.
  final Color surfaceColor;

  /// Rounded-corner geometry for bubbles.
  final BorderRadius bubbleRadius;

  /// Text style for headers (e.g. agent name).
  final TextStyle headerTextStyle;

  /// Text style for message bodies.
  final TextStyle bodyTextStyle;

  /// Text style for the "Translated from X" label.
  final TextStyle translationLabelStyle;

  /// Returns a copy with the given fields overridden.
  ChataptorTheme copyWith({
    Color? primaryColor,
    Color? onPrimaryColor,
    Color? customerBubbleColor,
    Color? customerBubbleTextColor,
    Color? agentBubbleColor,
    Color? agentBubbleTextColor,
    Color? backgroundColor,
    Color? surfaceColor,
    BorderRadius? bubbleRadius,
    TextStyle? headerTextStyle,
    TextStyle? bodyTextStyle,
    TextStyle? translationLabelStyle,
  }) {
    return ChataptorTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      customerBubbleColor: customerBubbleColor ?? this.customerBubbleColor,
      customerBubbleTextColor:
          customerBubbleTextColor ?? this.customerBubbleTextColor,
      agentBubbleColor: agentBubbleColor ?? this.agentBubbleColor,
      agentBubbleTextColor: agentBubbleTextColor ?? this.agentBubbleTextColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      bubbleRadius: bubbleRadius ?? this.bubbleRadius,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
      translationLabelStyle:
          translationLabelStyle ?? this.translationLabelStyle,
    );
  }
}
