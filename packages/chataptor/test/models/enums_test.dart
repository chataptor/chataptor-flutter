import 'package:chataptor/src/models/enums.dart';
import 'package:test/test.dart';

void main() {
  test('MessageAuthor values', () {
    expect(MessageAuthor.values, [
      MessageAuthor.customer,
      MessageAuthor.agent,
      MessageAuthor.bot,
    ]);
  });

  test('MessageType values', () {
    expect(MessageType.values, [
      MessageType.text,
      MessageType.quickReplies,
      MessageType.carousel,
    ]);
  });

  test('MessageStatus values', () {
    expect(MessageStatus.values, [
      MessageStatus.pending,
      MessageStatus.sent,
      MessageStatus.delivered,
      MessageStatus.read,
      MessageStatus.failed,
    ]);
  });

  test('DeliveryChannel values', () {
    expect(DeliveryChannel.values, [
      DeliveryChannel.websocket,
      DeliveryChannel.email,
      DeliveryChannel.api,
    ]);
  });

  test('AttachmentType values', () {
    expect(AttachmentType.values, [
      AttachmentType.image,
      AttachmentType.document,
      AttachmentType.audio,
      AttachmentType.video,
    ]);
  });

  test('ConversationStatus values', () {
    expect(ConversationStatus.values, [
      ConversationStatus.open,
      ConversationStatus.closed,
    ]);
  });

  test('ChannelType values', () {
    expect(ChannelType.values, [
      ChannelType.chat,
      ChannelType.email,
      ChannelType.hybrid,
    ]);
  });
}
