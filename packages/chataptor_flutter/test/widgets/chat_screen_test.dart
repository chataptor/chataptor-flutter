import 'package:chataptor/testing.dart';
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Chataptor.reset();
  });

  testWidgets('renders composer and empty state initially', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );
    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ChataptorComposer), findsOneWidget);
    expect(find.textContaining('No messages'), findsOneWidget);
  });

  testWidgets('sending a message updates the list', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );
    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    transport.inject.replyFor(
      topic: 'conversation:conv1',
      event: 'message:send',
      result: const PushOk({'msg_id': 1}),
    );
    await tester.enterText(find.byType(TextField), 'ciao');
    await tester.pump(); // rebuild so _canSend becomes true
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ciao'), findsOneWidget);
  });

  testWidgets('lazy mode (default) disconnects the client on dispose', (
    tester,
  ) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );

    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(Chataptor.instance.currentConnectionState, isA<Connected>());

    // Unmount the screen — lazy mode must disconnect.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(Chataptor.instance.currentConnectionState, isA<Disconnected>());
  });

  testWidgets(
    'shows loading indicator instead of empty state while connecting',
    (tester) async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      await Chataptor.init(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
        transport: transport,
      );

      await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
      // First frame — connecting, no messages → spinner shown.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('No messages'), findsNothing);
      // Drain pending timer from FakeChatTransport.connect.
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets(
    'shows cached messages immediately on second mount — no empty flash',
    (tester) async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('conversation:conv1', {
        'messages': [
          {
            'msg_id': 5,
            'conv_id': 'c1',
            'body_src': 'Cześć!',
            'author': 'agent',
            'inserted_at': '2026-05-12T10:00:00Z',
            'delivery_channel': 'websocket',
          },
        ],
      });

      await Chataptor.init(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
        transport: transport,
      );

      // First mount — load history.
      await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Cześć!'), findsOneWidget);

      // Navigate away — lazy mode disconnects.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(milliseconds: 100));

      // Second mount — first rendered frame must show cached messages.
      await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
      expect(find.text('Cześć!'), findsOneWidget);
      expect(find.textContaining('No messages'), findsNothing);
      // Drain pending timer from the second connect().
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  testWidgets('foregroundActive mode does NOT disconnect on dispose', (
    tester,
  ) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      config: ChataptorConfig(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
        transport: const TransportClientConfig(
          connectionMode: ConnectionMode.foregroundActive,
        ),
      ),
      transport: transport,
    );

    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(milliseconds: 100));

    // In foregroundActive mode, the lifecycle observer owns the socket —
    // the screen must not close it on its own.
    expect(Chataptor.instance.currentConnectionState, isA<Connected>());
  });
}
