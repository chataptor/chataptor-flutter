import 'package:chataptor/src/models/attachment.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:chataptor/src/models/message.dart';
import 'package:test/test.dart';

void main() {
  final timestamp = DateTime.utc(2026, 1, 1, 12);

  Message sample({
    String id = 'm1',
    String body = 'hello',
    MessageAuthor author = MessageAuthor.customer,
  }) => Message(
    id: id,
    conversationId: 'c1',
    body: body,
    author: author,
    timestamp: timestamp,
    type: MessageType.text,
    deliveryChannel: DeliveryChannel.websocket,
    status: MessageStatus.sent,
  );

  test('defaults for optional fields', () {
    final m = sample();
    expect(m.bodyTranslated, isNull);
    expect(m.sourceLanguage, isNull);
    expect(m.targetLanguage, isNull);
    expect(m.attachments, isEmpty);
    expect(m.richMetadata, isNull);
    expect(m.metadata, isEmpty);
  });

  test('equality compares every field', () {
    expect(sample(), sample());
    expect(sample(id: 'm2'), isNot(sample()));
  });

  test('copyWith overrides', () {
    final m = sample();
    final updated = m.copyWith(
      body: 'updated',
      status: MessageStatus.read,
      attachments: [
        const Attachment(
          id: 'a1',
          url: 'https://cdn/a.png',
          fileName: 'a.png',
          type: AttachmentType.image,
          sizeBytes: 1,
        ),
      ],
    );
    expect(updated.body, 'updated');
    expect(updated.status, MessageStatus.read);
    expect(updated.attachments, hasLength(1));
    expect(updated.id, 'm1');
  });
}
