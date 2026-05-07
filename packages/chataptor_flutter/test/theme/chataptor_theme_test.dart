import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChataptorTheme.light() has expected defaults', () {
    final theme = ChataptorTheme.light();
    expect(theme.primaryColor, isA<Color>());
    expect(theme.customerBubbleColor, isA<Color>());
    expect(theme.agentBubbleColor, isA<Color>());
    expect(theme.bubbleRadius.topLeft.x, greaterThan(0));
  });

  testWidgets('ChataptorTheme.matching uses Material primary', (tester) async {
    late ChataptorTheme theme;
    const key = Key('theme_builder');
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4)),
        home: Builder(
          key: key,
          builder: (ctx) {
            theme = ChataptorTheme.matching(ctx);
            return const SizedBox();
          },
        ),
      ),
    );
    final material = Theme.of(tester.element(find.byKey(key)));
    expect(theme.primaryColor, material.colorScheme.primary);
  });

  test('copyWith overrides individual fields', () {
    final base = ChataptorTheme.light();
    final updated = base.copyWith(primaryColor: const Color(0xFFFF0000));
    expect(updated.primaryColor, const Color(0xFFFF0000));
    expect(updated.agentBubbleColor, base.agentBubbleColor);
  });
}
