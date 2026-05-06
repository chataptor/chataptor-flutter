import 'package:chataptor/src/models/agent_info.dart';
import 'package:chataptor/src/models/conversation.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:test/test.dart';

void main() {
  final created = DateTime.utc(2026, 1, 1);

  test('Conversation carries required and optional fields', () {
    final conv = Conversation(
      id: 'c1',
      status: ConversationStatus.open,
      channelType: ChannelType.chat,
      unreadCount: 3,
      createdAt: created,
    );
    expect(conv.id, 'c1');
    expect(conv.status, ConversationStatus.open);
    expect(conv.channelType, ChannelType.chat);
    expect(conv.unreadCount, 3);
    expect(conv.assignedAgent, isNull);
    expect(conv.lastMessageAt, isNull);
  });

  test('copyWith overrides', () {
    final conv = Conversation(
      id: 'c1',
      status: ConversationStatus.open,
      channelType: ChannelType.chat,
      unreadCount: 0,
      createdAt: created,
    );
    final updated = conv.copyWith(
      status: ConversationStatus.closed,
      unreadCount: 5,
      assignedAgent: const AgentInfo(id: 1, name: 'Anna'),
    );
    expect(updated.status, ConversationStatus.closed);
    expect(updated.unreadCount, 5);
    expect(updated.assignedAgent?.name, 'Anna');
  });
}
