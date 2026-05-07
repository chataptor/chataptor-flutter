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
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );
    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    transport.inject.replyFor(
      topic: 'site:abc',
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

  testWidgets('foregroundActive mode does NOT disconnect on dispose', (
    tester,
  ) async {
    final transport = FakeChatTransport();
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
