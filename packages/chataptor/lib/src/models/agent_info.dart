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

/// Public information about a support agent — either the one assigned to
/// the active conversation, or a member of the currently-online agent
/// pool surfaced via `ChataptorClient.currentOnlineAgents`.
@immutable
class AgentInfo {
  /// Creates an [AgentInfo].
  const AgentInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.initials,
  });

  /// Parses a single agent entry as serialized by the backend's
  /// `agent:available` Phoenix event (also used in the assigned-agent
  /// payload on the conversation channel). Tolerates both `int` and
  /// `String` IDs.
  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int
        ? rawId
        : (rawId is String ? int.tryParse(rawId) ?? 0 : 0);
    final initialsRaw = json['initials'];
    AgentInitials? initials;
    if (initialsRaw is Map) {
      final initialsMap = Map<String, dynamic>.from(initialsRaw);
      initials = AgentInitials(
        letters: (initialsMap['letters'] as String?) ?? '',
        color: (initialsMap['color'] as String?) ?? '',
      );
    }
    return AgentInfo(
      id: id,
      name: (json['name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      initials: initials,
    );
  }

  /// Parses the `agents:` list from an `agent:available` event payload
  /// into a typed list of [AgentInfo]. Skips entries that are not maps so
  /// the caller does not need to defensively unwrap the broadcast payload.
  static List<AgentInfo> listFromPresencePayload(Map<String, dynamic> json) {
    final raw = json['agents'];
    if (raw is! List) return const [];
    final out = <AgentInfo>[];
    for (final entry in raw) {
      if (entry is Map) {
        out.add(AgentInfo.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return out;
  }

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
