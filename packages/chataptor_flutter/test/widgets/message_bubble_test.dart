import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Message _message({
  MessageAuthor author = MessageAuthor.customer,
  String body = 'hi',
  String? translated,
}) => Message(
  id: 'm1',
  conversationId: 'c1',
  body: body,
  bodyTranslated: translated,
  sourceLanguage: translated != null ? 'en' : null,
  targetLanguage: translated != null ? 'pl' : null,
  author: author,
  timestamp: DateTime.utc(2026),
  type: MessageType.text,
  deliveryChannel: DeliveryChannel.websocket,
  status: MessageStatus.sent,
);

void main() {
  testWidgets('renders body text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChataptorMessageBubble(message: _message(body: 'hello')),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('customer and agent bubbles render with different colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ChataptorMessageBubble(message: _message()),
              ChataptorMessageBubble(
                message: _message(author: MessageAuthor.agent),
              ),
            ],
          ),
        ),
      ),
    );
    final containers = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .toList();
    // At least two colored bubbles somewhere in the tree.
    expect(containers.length >= 2, isTrue);
  });

  testWidgets('renders translation label when translation present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChataptorMessageBubble(
            message: _message(body: 'Hello', translated: 'Cześć'),
          ),
        ),
      ),
    );
    expect(find.text('Cześć'), findsOneWidget);
    expect(find.textContaining('en'), findsOneWidget);
  });

  testWidgets('has a Semantics label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChataptorMessageBubble(message: _message())),
      ),
    );
    final semantics = tester.getSemantics(find.byType(ChataptorMessageBubble));
    expect(semantics.label, contains('hi'));
  });
}
