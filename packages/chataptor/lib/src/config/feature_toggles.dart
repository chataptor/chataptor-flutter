import 'package:chataptor/src/models/enums.dart';
import 'package:meta/meta.dart';

/// Configuration for file attachment handling.
///
/// Attachments are a v0.4.0 feature — until then the composer does not
/// expose a picker and the backend upload wiring is not implemented. The
/// default is therefore `enabled: false`; the type exists ahead of its
/// features so `ChataptorConfig` does not have to change shape when
/// attachments land.
@immutable
class AttachmentConfig {
  /// Creates an [AttachmentConfig]. `enabled` defaults to `false`;
  /// merchants may opt in experimentally but the composer will not
  /// honour it until v0.4.0.
  const AttachmentConfig({
    this.enabled = false,
    this.maxSizeMB = 10,
    this.allowedTypes = const {AttachmentType.image, AttachmentType.document},
  });

  /// Whether the composer exposes an attachment picker. Honoured from
  /// v0.4.0; ignored before then (no picker widget exists yet).
  final bool enabled;

  /// Maximum size per attachment in megabytes.
  final int maxSizeMB;

  /// Which [AttachmentType]s are accepted.
  final Set<AttachmentType> allowedTypes;

  @override
  bool operator ==(Object other) =>
      other is AttachmentConfig &&
      other.enabled == enabled &&
      other.maxSizeMB == maxSizeMB &&
      _setEq(other.allowedTypes, allowedTypes);

  @override
  int get hashCode =>
      Object.hash(enabled, maxSizeMB, Object.hashAllUnordered(allowedTypes));
}

bool _setEq<T>(Set<T> a, Set<T> b) {
  if (a.length != b.length) return false;
  for (final v in a) {
    if (!b.contains(v)) return false;
  }
  return true;
}

/// Boolean-ish toggles for features that can be disabled per-integration.
@immutable
class FeatureToggles {
  /// Creates a [FeatureToggles] with sensible defaults (everything on).
  const FeatureToggles({
    this.typingIndicators = true,
    this.readReceipts = true,
    this.emojiSubstitution = true,
    this.attachments = const AttachmentConfig(),
  });

  /// Whether the SDK emits/receives typing indicators.
  final bool typingIndicators;

  /// Whether the SDK marks messages as read and receives read updates.
  final bool readReceipts;

  /// Whether the composer converts ASCII sequences (`:)` → 🙂) before
  /// sending.
  final bool emojiSubstitution;

  /// Attachment configuration.
  final AttachmentConfig attachments;

  /// Returns a copy with the given fields overridden.
  FeatureToggles copyWith({
    bool? typingIndicators,
    bool? readReceipts,
    bool? emojiSubstitution,
    AttachmentConfig? attachments,
  }) {
    return FeatureToggles(
      typingIndicators: typingIndicators ?? this.typingIndicators,
      readReceipts: readReceipts ?? this.readReceipts,
      emojiSubstitution: emojiSubstitution ?? this.emojiSubstitution,
      attachments: attachments ?? this.attachments,
    );
  }
}
