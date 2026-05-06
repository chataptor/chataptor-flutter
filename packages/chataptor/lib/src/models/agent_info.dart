import 'package:meta/meta.dart';

/// Fallback visual representation of an agent when no avatar is available.
@immutable
class AgentInitials {
  /// Creates an [AgentInitials] pair.
  const AgentInitials({required this.letters, required this.color});

  /// One to three uppercase letters to display.
  final String letters;

  /// Background color as a hex string (e.g. `#FF00AA`).
  final String color;

  @override
  bool operator ==(Object other) =>
      other is AgentInitials &&
      other.letters == letters &&
      other.color == color;

  @override
  int get hashCode => Object.hash(letters, color);
}

/// Public information about the support agent currently assigned to the
/// conversation.
@immutable
class AgentInfo {
  /// Creates an [AgentInfo].
  const AgentInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.initials,
  });

  /// Server-assigned agent ID.
  final int id;

  /// Agent's display name shown to the customer.
  final String name;

  /// URL of the agent's avatar image, if any.
  final String? avatarUrl;

  /// Fallback initials to render when [avatarUrl] is null or fails to load.
  final AgentInitials? initials;

  /// Returns a copy with the given fields overridden.
  AgentInfo copyWith({
    int? id,
    String? name,
    String? avatarUrl,
    AgentInitials? initials,
  }) {
    return AgentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AgentInfo &&
      other.id == id &&
      other.name == name &&
      other.avatarUrl == avatarUrl &&
      other.initials == initials;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl, initials);
}
