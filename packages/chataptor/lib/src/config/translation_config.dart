import 'package:meta/meta.dart';

/// First-class configuration for bidirectional auto-translation — the
/// SDK's hero feature.
///
/// Exposed at the top level of [ChataptorConfig] (not nested inside a
/// generic feature toggle) because it's the differentiator.
@immutable
class TranslationConfig {
  /// Creates a [TranslationConfig] with explicit fields. Prefer the named
  /// factories below.
  const TranslationConfig({
    required this.enabled,
    this.customerLanguage,
  });

  /// Enables auto-translation. The server translates agent messages into
  /// [customerLanguage] (or the runtime-detected locale if null) and
  /// translates outgoing customer messages into the agent's workspace
  /// language.
  factory TranslationConfig.auto({String? customerLanguage}) =>
      TranslationConfig(enabled: true, customerLanguage: customerLanguage);

  /// Disables auto-translation. Messages flow through verbatim.
  factory TranslationConfig.disabled() =>
      const TranslationConfig(enabled: false);

  /// Whether auto-translation is on.
  final bool enabled;

  /// ISO language code in which the customer wants to see messages (e.g.
  /// `pl`, `ja`). When null, the SDK asks the platform (via the Flutter
  /// layer) at runtime.
  final String? customerLanguage;

  /// Returns a copy with the given fields overridden.
  TranslationConfig copyWith({
    bool? enabled,
    String? customerLanguage,
  }) {
    return TranslationConfig(
      enabled: enabled ?? this.enabled,
      customerLanguage: customerLanguage ?? this.customerLanguage,
    );
  }
}
