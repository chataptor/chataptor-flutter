import 'package:chataptor/src/models/agent_info.dart';
import 'package:test/test.dart';

void main() {
  test('AgentInitials equality', () {
    const a = AgentInitials(letters: 'AN', color: '#FF00AA');
    const b = AgentInitials(letters: 'AN', color: '#FF00AA');
    expect(a, b);
  });

  test('AgentInfo carries id, name, optional avatar and initials', () {
    const info = AgentInfo(
      id: 7,
      name: 'Anna',
      initials: AgentInitials(letters: 'AN', color: '#123456'),
    );
    expect(info.id, 7);
    expect(info.name, 'Anna');
    expect(info.initials?.letters, 'AN');
    expect(info.avatarUrl, isNull);
  });

  test('AgentInfo copyWith', () {
    const info = AgentInfo(id: 1, name: 'Anna');
    final updated = info.copyWith(avatarUrl: 'https://cdn/a.jpg');
    expect(updated.avatarUrl, 'https://cdn/a.jpg');
    expect(updated.name, 'Anna');
  });
}
