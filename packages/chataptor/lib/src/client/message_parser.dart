import 'package:chataptor/src/models/enums.dart';
import 'package:chataptor/src/models/message.dart';

/// Parses a single `message:received` payload from the Chataptor backend
/// into a [Message].
///
/// Missing or unknown fields fall back to sensible defaults. Designed to be
/// lenient — the SDK should never crash on slightly-unexpected server
/// responses.
Message parseIncomingMessage(Map<String, dynamic> payload) {
  // Backend wraps the message object: {message: {...}} — unwrap tolerantly.
  final raw = payload['message'] is Map
      ? (payload['message'] as Map).cast<String, dynamic>()
      : payload;
  final id = (raw['msg_id'] ?? raw['id'] ?? '').toString();
  final convId = (raw['conv_id'] ?? raw['conversation_id'] ?? '').toString();
  final body = (raw['body_src'] ?? raw['body'] ?? '').toString();
  // Backend stores translations in message_translations table and serializes
  // them as a `translation` sub-object. The top-level `body_translated` is
  // only set by legacy paths, so fall back to the sub-object when absent.
  final translationSub = raw['translation'] as Map?;
  final bodyTranslated =
      (raw['body_translated'] as String?) ??
      (translationSub?['translatedText'] as String?);
  final sourceLanguage =
      (raw['source_language'] as String?) ??
      (translationSub?['sourceLanguage'] as String?);
  final targetLanguage =
      (raw['target_language'] as String?) ??
      (translationSub?['targetLanguage'] as String?);
  final author = _parseAuthor(raw['author']);
  final timestamp = _parseTimestamp(raw['inserted_at'] ?? raw['timestamp']);
  final channel = _parseChannel(raw['delivery_channel']);

  return Message(
    id: id,
    conversationId: convId,
    body: body,
    bodyTranslated: bodyTranslated,
    sourceLanguage: sourceLanguage,
    targetLanguage: targetLanguage,
    author: author,
    timestamp: timestamp,
    type: MessageType.text,
    deliveryChannel: channel,
    status: MessageStatus.delivered,
  );
}

MessageAuthor _parseAuthor(Object? raw) {
  switch (raw) {
    case 'agent':
      return MessageAuthor.agent;
    case 'bot':
      return MessageAuthor.bot;
    case 'customer':
    default:
      return MessageAuthor.customer;
  }
}

DeliveryChannel _parseChannel(Object? raw) {
  switch (raw) {
    case 'email':
      return DeliveryChannel.email;
    case 'api':
      return DeliveryChannel.api;
    case 'websocket':
    default:
      return DeliveryChannel.websocket;
  }
}

DateTime _parseTimestamp(Object? raw) {
  if (raw is String) {
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      // fall through
    }
  }
  return DateTime.now().toUtc();
}
