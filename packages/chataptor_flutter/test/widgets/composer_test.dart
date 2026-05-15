import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders input and send button with a11y labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChataptorComposer(onSend: (_) async {})),
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send_rounded), findsOneWidget);
  });

  testWidgets('calls onSend with trimmed text and clears input', (
    tester,
  ) async {
    String? sent;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChataptorComposer(
            onSend: (text) async {
              sent = text;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '  hello  ');
    await tester.pump(); // rebuild so _canSend becomes true
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(sent, 'hello');

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('send button is disabled when empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChataptorComposer(onSend: (_) async {})),
      ),
    );
    final sendButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(sendButton.onPressed, isNull);
  });

  testWidgets('send button is disabled when enabled is false even with text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChataptorComposer(enabled: false, onSend: (_) async {}),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    final sendButton = tester.widget<IconButton>(find.byType(IconButton));
    expect(sendButton.onPressed, isNull);
  });
}
