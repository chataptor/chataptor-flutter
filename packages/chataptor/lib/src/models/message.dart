import 'package:chataptor/src/models/attachment.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:meta/meta.dart';

/// A single message in a `Conversation`.
///
/// Messages are immutable. The SDK emits a new [Message] with updated
/// [status] on delivery/read transitions rather than mutating existing
/// instances.
@immutable
class Message {
  /// Creates a [Message].
  const Message({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.author,
    required this.timestamp,
    required this.type,
    required this.deliveryChannel,
    required this.status,
    this.bodyTranslated,
    this.sourceLanguage,
    this.targetLanguage,
    this.attachments = const [],
    this.richMetadata,
    this.metadata = const {},
  });

  /// Server-assigned message ID.
  final String id;

  /// ID of the `Conversation` this message belongs to.
  final String conversationId;

  /// Body in the original author's language.
  final String body;

  /// Translated body in the target language, if translation ran.
  final String? bodyTranslated;

  /// ISO language code of [body].
  final String? sourceLanguage;

  /// ISO language code of [bodyTranslated].
  final String? targetLanguage;

  /// Who sent this message.
  final MessageAuthor author;

  /// When the server recorded this message.
  final DateTime timestamp;

  /// Files attached to this message.
  final List<Attachment> attachments;

  /// Rich type classification.
  final MessageType type;

  /// Structured metadata for quick-reply options or carousel cards. Shape
  /// matches the backend contract; SDK exposes it opaquely for now.
  final Map<String, dynamic>? richMetadata;

  /// Which transport actually delivered this message.
  final DeliveryChannel deliveryChannel;

  /// Current delivery state from the customer's perspective.
  final MessageStatus status;

  /// Arbitrary metadata attached by the merchant's beforeSend interceptor or
  /// by the server.
  final Map<String, dynamic> metadata;

  /// Returns a copy with the given fields overridden. Pass `null` for a
  /// field to leave it unchanged; if you need to clear a nullable field,
  /// use the existing field value.
  Message copyWith({
    String? id,
    String? conversationId,
    String? body,
    String? bodyTranslated,
    String? sourceLanguage,
    String? targetLanguage,
    MessageAuthor? author,
    DateTime? timestamp,
    List<Attachment>? attachments,
    MessageType? type,
    Map<String, dynamic>? richMetadata,
    DeliveryChannel? deliveryChannel,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      body: body ?? this.body,
      bodyTranslated: bodyTranslated ?? this.bodyTranslated,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
      type: type ?? this.type,
      richMetadata: richMetadata ?? this.richMetadata,
      deliveryChannel: deliveryChannel ?? this.deliveryChannel,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.id == id &&
      other.conversationId == conversationId &&
      other.body == body &&
      other.bodyTranslated == bodyTranslated &&
      other.sourceLanguage == sourceLanguage &&
      other.targetLanguage == targetLanguage &&
      other.author == author &&
      other.timestamp == timestamp &&
      _listEquals(other.attachments, attachments) &&
      other.type == type &&
      _mapEqualsNullable(other.richMetadata, richMetadata) &&
      other.deliveryChannel == deliveryChannel &&
      other.status == status &&
      _mapEquals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    body,
    bodyTranslated,
    sourceLanguage,
    targetLanguage,
    author,
    timestamp,
    Object.hashAll(attachments),
    type,
    richMetadata == null ? null : _mapHash(richMetadata!),
    deliveryChannel,
    status,
    _mapHash(metadata),
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

bool _mapEqualsNullable(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return _mapEquals(a, b);
}

int _mapHash(Map<String, dynamic> m) {
  var h = 0;
  for (final e in m.entries) {
    h = h ^ Object.hash(e.key, e.value);
  }
  return h;
}
