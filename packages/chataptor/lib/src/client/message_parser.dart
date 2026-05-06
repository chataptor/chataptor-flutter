import 'package:chataptor/src/models/enums.dart';
import 'package:chataptor/src/models/message.dart';

/// Parses a single `message:received` payload from the Chataptor backend
/// into a [Message].
///
/// Missing or unknown fields fall back to sensible defaults. Designed to be
/// lenient — the SDK should never crash on slightly-unexpected server
/// responses.
Message parseIncomingMessage(Map<String, dynamic> payload) {
  final id = (payload['msg_id'] ?? payload['id'] ?? '').toString();
  final convId = (payload['conv_id'] ?? payload['conversation_id'] ?? '')
      .toString();
  final body = (payload['body_src'] ?? payload['body'] ?? '').toString();
  final bodyTranslated = payload['body_translated'] as String?;
  final sourceLanguage = payload['source_language'] as String?;
  final targetLanguage = payload['target_language'] as String?;
  final author = _parseAuthor(payload['author']);
  final timestamp = _parseTimestamp(
    payload['inserted_at'] ?? payload['timestamp'],
  );
  final channel = _parseChannel(payload['delivery_channel']);

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
