import 'package:meta/meta.dart';

/// A message composed locally by the customer that has not (yet) been
/// successfully delivered to the server.
///
/// Attached to [SendFailure] so the caller can retry transmission without
/// re-collecting user input.
@immutable
class MessageDraft {
  /// Creates a [MessageDraft].
  const MessageDraft({
    required this.body,
    this.metadata = const {},
  });

  /// The plain-text body the user typed.
  final String body;

  /// Arbitrary merchant-supplied metadata to attach to the eventual [Message].
  final Map<String, dynamic> metadata;

  /// Returns a copy with the given fields overridden.
  MessageDraft copyWith({
    String? body,
    Map<String, dynamic>? metadata,
  }) {
    return MessageDraft(
      body: body ?? this.body,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MessageDraft &&
      other.body == body &&
      _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(body, _mapHash(metadata));
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key)) return false;
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash(Map<String, dynamic> m) {
  var h = 0;
  for (final entry in m.entries) {
    h = h ^ Object.hash(entry.key, entry.value);
  }
  return h;
}
