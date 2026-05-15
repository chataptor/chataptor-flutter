import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Message _msg(
  String id,
  String body, {
  MessageAuthor author = MessageAuthor.agent,
}) => Message(
  id: id,
  conversationId: 'c1',
  body: body,
  author: author,
  timestamp: DateTime.utc(2026, 4, 22, 12, int.parse(id)),
  type: MessageType.text,
  deliveryChannel: DeliveryChannel.websocket,
  status: MessageStatus.sent,
);

void main() {
  testWidgets('renders a list of messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChataptorMessageList(
            messages: [_msg('1', 'first'), _msg('2', 'second')],
          ),
        ),
      ),
    );
    expect(find.text('first'), findsOneWidget);
    expect(find.text('second'), findsOneWidget);
  });

  testWidgets('shows empty state widget when no messages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChataptorMessageList(messages: [])),
      ),
    );
    expect(find.textContaining('No messages'), findsOneWidget);
  });

  testWidgets(
    'shows CircularProgressIndicator when isLoading is true and no messages',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChataptorMessageList(messages: [], isLoading: true),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('No messages'), findsNothing);
    },
  );

  testWidgets('shows messages even when isLoading is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChataptorMessageList(
            messages: [_msg('1', 'existing message')],
            isLoading: true,
          ),
        ),
      ),
    );
    expect(find.text('existing message'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
