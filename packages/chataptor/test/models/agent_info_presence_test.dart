import 'package:chataptor/src/models/agent_info.dart';
import 'package:test/test.dart';

void main() {
  group('AgentInfo.fromJson', () {
    test('parses a fully-populated agent entry from agent:available', () {
      final agent = AgentInfo.fromJson(const {
        'id': 42,
        'name': 'Anna Kowalska',
        'avatar_url': 'https://cdn.example.com/anna.jpg',
        'initials': {'letters': 'AK', 'color': '#7C3AED'},
      });
      expect(agent.id, 42);
      expect(agent.name, 'Anna Kowalska');
      expect(agent.avatarUrl, 'https://cdn.example.com/anna.jpg');
      expect(agent.initials, isNotNull);
      expect(agent.initials!.letters, 'AK');
      expect(agent.initials!.color, '#7C3AED');
    });

    test('coerces a string id into an int', () {
      final agent = AgentInfo.fromJson(const {'id': '7', 'name': 'Joe'});
      expect(agent.id, 7);
    });

    test('survives an entry with no avatar or initials', () {
      final agent = AgentInfo.fromJson(const {'id': 1, 'name': 'Bare'});
      expect(agent.avatarUrl, isNull);
      expect(agent.initials, isNull);
    });
  });

  group('AgentInfo.listFromPresencePayload', () {
    test('parses an agent:available payload into a list', () {
      final agents = AgentInfo.listFromPresencePayload(const {
        'type': 'agent_available',
        'message': 'An agent is now available',
        'agents': [
          {
            'id': 1,
            'name': 'Anna',
            'avatar_url': 'https://cdn.example.com/anna.jpg',
            'initials': {'letters': 'AN', 'color': '#FF00AA'},
          },
          {
            'id': 2,
            'name': 'Bart',
            'initials': {'letters': 'BA', 'color': '#00AAFF'},
          },
        ],
      });
      expect(agents, hasLength(2));
      expect(agents[0].id, 1);
      expect(agents[1].name, 'Bart');
      expect(agents[1].avatarUrl, isNull);
    });

    test('returns an empty list when agents key is missing or malformed', () {
      expect(AgentInfo.listFromPresencePayload(const {}), isEmpty);
      expect(
        AgentInfo.listFromPresencePayload(const {'agents': 'not-a-list'}),
        isEmpty,
      );
    });

    test('skips entries that are not maps', () {
      final agents = AgentInfo.listFromPresencePayload(const {
        'agents': [
          {'id': 1, 'name': 'Anna'},
          'garbage',
          42,
          {'id': 2, 'name': 'Bart'},
        ],
      });
      expect(agents.map((a) => a.id), [1, 2]);
    });
  });
}
