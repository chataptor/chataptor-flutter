import 'package:chataptor/chataptor.dart';
import 'package:chataptor/src/client/message_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseIncomingMessage', () {
    test('parses agent text message with translation', () {
      final msg = parseIncomingMessage({
        'msg_id': 123,
        'conv_id': 42,
        'body_src': 'Hello',
        'body_translated': 'Cześć',
        'source_language': 'en',
        'target_language': 'pl',
        'author': 'agent',
        'inserted_at': '2026-04-22T12:00:00Z',
        'delivery_channel': 'websocket',
      });

      expect(msg.id, '123');
      expect(msg.conversationId, '42');
      expect(msg.body, 'Hello');
      expect(msg.bodyTranslated, 'Cześć');
      expect(msg.sourceLanguage, 'en');
      expect(msg.targetLanguage, 'pl');
      expect(msg.author, MessageAuthor.agent);
      expect(msg.deliveryChannel, DeliveryChannel.websocket);
      expect(msg.timestamp, DateTime.parse('2026-04-22T12:00:00Z'));
      expect(msg.status, MessageStatus.delivered);
    });

    test('defaults author to customer when unknown', () {
      final msg = parseIncomingMessage({
        'msg_id': 1,
        'conv_id': 2,
        'body_src': 'x',
        'author': 'who-knows',
        'inserted_at': '2026-04-22T12:00:00Z',
        'delivery_channel': 'websocket',
      });
      expect(msg.author, MessageAuthor.customer);
    });

    test('uses current UTC when inserted_at missing', () {
      final msg = parseIncomingMessage({
        'msg_id': 1,
        'conv_id': 2,
        'body_src': 'x',
        'author': 'agent',
        'delivery_channel': 'websocket',
      });
      // Timestamp is within a few seconds of now.
      expect(
        msg.timestamp.difference(DateTime.now().toUtc()).abs().inSeconds < 5,
        isTrue,
      );
    });

    test('unwraps {message: {...}} wrapper sent by backend', () {
      final msg = parseIncomingMessage({
        'message': {
          'msg_id': 123,
          'conv_id': 42,
          'body_src': 'Hello',
          'author': 'agent',
          'inserted_at': '2026-04-22T12:00:00Z',
          'delivery_channel': 'websocket',
        },
      });
      expect(msg.id, '123');
      expect(msg.conversationId, '42');
      expect(msg.body, 'Hello');
      expect(msg.author, MessageAuthor.agent);
    });

    test('reads translation from translation sub-object when body_translated'
        ' absent', () {
      // Backend stores translations in message_translations table and
      // serializes them as a `translation` sub-object in serialize_message/1.
      // The top-level `body_translated` is only populated by legacy paths.
      final msg = parseIncomingMessage({
        'msg_id': 42,
        'conv_id': 7,
        'body_src': 'Dzień dobry',
        'author': 'agent',
        'inserted_at': '2026-04-22T12:00:00Z',
        'delivery_channel': 'websocket',
        'translation': {
          'translatedText': 'Good morning',
          'sourceLanguage': 'pl',
          'targetLanguage': 'en',
          'translatedBy': 'openai',
        },
      });

      expect(msg.bodyTranslated, 'Good morning');
      expect(msg.sourceLanguage, 'pl');
      expect(msg.targetLanguage, 'en');
    });

    test('body_translated takes precedence over translation sub-object', () {
      final msg = parseIncomingMessage({
        'msg_id': 1,
        'conv_id': 2,
        'body_src': 'Hello',
        'body_translated': 'Cześć',
        'source_language': 'en',
        'target_language': 'pl',
        'author': 'agent',
        'inserted_at': '2026-04-22T12:00:00Z',
        'delivery_channel': 'websocket',
        'translation': {
          'translatedText': 'IGNORED',
          'sourceLanguage': 'xx',
          'targetLanguage': 'yy',
        },
      });

      expect(msg.bodyTranslated, 'Cześć');
      expect(msg.sourceLanguage, 'en');
      expect(msg.targetLanguage, 'pl');
    });
  });
}
