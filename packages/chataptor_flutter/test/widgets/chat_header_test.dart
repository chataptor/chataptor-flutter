import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _agentAnna = AgentInfo(
  id: 1,
  name: 'Anna',
  initials: AgentInitials(letters: 'AN', color: '#7C3AED'),
);
const _agentViktor = AgentInfo(
  id: 2,
  name: 'Viktor',
  initials: AgentInitials(letters: 'VI', color: '#0F766E'),
);
const _agentMaria = AgentInfo(
  id: 3,
  name: 'Maria',
  initials: AgentInitials(letters: 'MA', color: '#DB2777'),
);
const _agentBart = AgentInfo(
  id: 4,
  name: 'Bart',
  initials: AgentInitials(letters: 'BA', color: '#F59E0B'),
);
const _agentLeo = AgentInfo(
  id: 5,
  name: 'Leo',
  initials: AgentInitials(letters: 'LE', color: '#2563EB'),
);

Future<void> _pumpHeader(
  WidgetTester tester, {
  required List<AgentInfo> agents,
  String? title,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: ChataptorChatHeader(
            title: title,
            onlineAgents: agents,
            theme: ChataptorTheme.light(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ChataptorChatHeader', () {
    testWidgets('shows the provided title text', (tester) async {
      await _pumpHeader(tester, agents: const [], title: 'Customer Support');
      expect(find.text('Customer Support'), findsOneWidget);
    });

    testWidgets('falls back to "Support" when no title is provided', (
      tester,
    ) async {
      await _pumpHeader(tester, agents: const []);
      expect(find.text('Support'), findsOneWidget);
    });

    testWidgets('renders "Offline" when no agents are online', (tester) async {
      await _pumpHeader(tester, agents: const [], title: 'Help');
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('renders "Online" with one agent in the stack', (tester) async {
      await _pumpHeader(tester, agents: const [_agentAnna]);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('AN'), findsOneWidget);
    });

    testWidgets('stacks up to 3 agent initials when 3 are online', (
      tester,
    ) async {
      await _pumpHeader(
        tester,
        agents: const [_agentAnna, _agentViktor, _agentMaria],
      );
      expect(find.text('AN'), findsOneWidget);
      expect(find.text('VI'), findsOneWidget);
      expect(find.text('MA'), findsOneWidget);
      // No overflow badge when count == 3.
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('shows "+N" overflow badge when more than 3 agents online', (
      tester,
    ) async {
      await _pumpHeader(
        tester,
        agents: const [
          _agentAnna,
          _agentViktor,
          _agentMaria,
          _agentBart,
          _agentLeo,
        ],
      );
      // First 3 inline, last 2 collapsed into "+2".
      expect(find.text('AN'), findsOneWidget);
      expect(find.text('VI'), findsOneWidget);
      expect(find.text('MA'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      // The hidden agents' initials are NOT rendered separately.
      expect(find.text('BA'), findsNothing);
      expect(find.text('LE'), findsNothing);
    });

    testWidgets('exposes a11y label summarising who is available', (
      tester,
    ) async {
      await _pumpHeader(
        tester,
        agents: const [_agentAnna, _agentViktor],
        title: 'Help center',
      );
      // Use bySemanticsLabel to assert a screen-reader-friendly summary.
      expect(
        find.bySemanticsLabel(
          RegExp('Help center.*2 agents? online', dotAll: true),
        ),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
