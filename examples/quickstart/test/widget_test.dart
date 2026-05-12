import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuickstartApp renders Open chat button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Open chat'))),
      ),
    );
    expect(find.text('Open chat'), findsOneWidget);
  });
}
