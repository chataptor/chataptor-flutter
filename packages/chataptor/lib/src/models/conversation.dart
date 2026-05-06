import 'package:chataptor/src/models/agent_info.dart';
import 'package:chataptor/src/models/enums.dart';
import 'package:meta/meta.dart';

/// The active conversation between a customer and the support team.
///
/// The SDK maintains exactly one active `Conversation` per `ChataptorClient`
/// at a time — the one the customer is currently chatting in. Historical
/// conversations are accessed via history APIs rather than kept in memory.
@immutable
class Conversation {
  /// Creates a [Conversation].
  const Conversation({
    required this.id,
    required this.status,
    required this.channelType,
    required this.unreadCount,
    required this.createdAt,
    this.assignedAgent,
    this.lastMessageAt,
  });

  /// Server-assigned conversation ID.
  final String id;

  /// Lifecycle status.
  final ConversationStatus status;

  /// Which surfaces are active on this conversation.
  final ChannelType channelType;

  /// Agent currently assigned to this conversation, if any.
  final AgentInfo? assignedAgent;

  /// Unread message count from the customer's perspective.
  final int unreadCount;

  /// When the conversation was created.
  final DateTime createdAt;

  /// Timestamp of the most recent message, or null if no messages yet.
  final DateTime? lastMessageAt;

  /// Returns a copy with the given fields overridden.
  Conversation copyWith({
    String? id,
    ConversationStatus? status,
    ChannelType? channelType,
    AgentInfo? assignedAgent,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? lastMessageAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      status: status ?? this.status,
      channelType: channelType ?? this.channelType,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Conversation &&
      other.id == id &&
      other.status == status &&
      other.channelType == channelType &&
      other.assignedAgent == assignedAgent &&
      other.unreadCount == unreadCount &&
      other.createdAt == createdAt &&
      other.lastMessageAt == lastMessageAt;

  @override
  int get hashCode => Object.hash(
    id,
    status,
    channelType,
    assignedAgent,
    unreadCount,
    createdAt,
    lastMessageAt,
  );
}
