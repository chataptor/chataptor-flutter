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

  testWidgets('send button is disabled while connecting', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );

    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    // First frame — still connecting, no text yet → send disabled.
    // (enterText would trigger a pump that completes the fake transport, so we
    // check the button state right after mount before any additional pumps.)
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.send_rounded),
          )
          .onPressed,
      isNull,
    );
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('send button is enabled after Connected', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );

    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100)); // connection done
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();

    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.send_rounded),
          )
          .onPressed,
      isNotNull,
    );
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

  testWidgets('shows "Powered by Chataptor" branding by default', (
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

    expect(find.textContaining('chataptor.com'), findsOneWidget);
  });

  testWidgets('branding is hidden when showPoweredBy is false', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );
    await tester.pumpWidget(
      const MaterialApp(home: ChataptorChatScreen(showPoweredBy: false)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Powered by Chataptor'), findsNothing);
  });

  testWidgets('custom title appears in AppBar', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );
    await tester.pumpWidget(
      const MaterialApp(home: ChataptorChatScreen(title: 'Acme Support')),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Acme Support'), findsOneWidget);
    expect(find.text('Chataptor'), findsNothing);
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
      // First frame — connecting, no messages → skeleton shown, not spinner.
      expect(find.byKey(const ValueKey('chataptor-skeleton')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
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

  testWidgets('showAppBar defaults to true — AppBar is rendered', (
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

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(ChataptorChatHeader), findsOneWidget);
  });

  testWidgets('showAppBar: false — no AppBar, header renders inline', (
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

    await tester.pumpWidget(
      const MaterialApp(home: ChataptorChatScreen(showAppBar: false)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppBar), findsNothing);
    // Header still surfaces so hosts (sheet/dialog) keep agent presence UX.
    expect(find.byType(ChataptorChatHeader), findsOneWidget);
    // No close button when host owns the chrome.
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets(
    'manualOffline: composer send is disabled and offline banner renders',
    (tester) async {
      final transport = FakeChatTransport();
      transport.inject.conversationCreated('site:abc', 'conv1');
      transport.inject.joinPayload('site:abc', {
        'site_config': {
          'widget_language': 'en',
          'offline_mode': 'manual_offline',
          'language_variants': [
            {
              'language_code': 'en',
              'is_default': true,
              'offline_title': "We're offline",
              'offline_subtitle': 'Leave a message and we will get back.',
            },
          ],
        },
      });
      await Chataptor.init(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
        transport: transport,
      );

      await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Composer send button must be disabled — even with text — when offline.
      await tester.enterText(find.byType(TextField), 'hi');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.send_rounded),
            )
            .onPressed,
        isNull,
      );

      // Offline banner surfaces the variant-supplied copy.
      expect(find.text("We're offline"), findsOneWidget);
      expect(
        find.text('Leave a message and we will get back.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('manualOffline without variant copy: banner falls back to l10n', (
    tester,
  ) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    transport.inject.joinPayload('site:abc', {
      'site_config': {'offline_mode': 'manual_offline'},
    });
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );

    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    // Default English fallback strings.
    expect(find.textContaining('Currently offline'), findsOneWidget);
  });

  testWidgets('auto mode renders no offline banner', (tester) async {
    final transport = FakeChatTransport();
    transport.inject.conversationCreated('site:abc', 'conv1');
    transport.inject.joinPayload('site:abc', {
      'site_config': {'offline_mode': 'auto'},
    });
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: transport,
    );

    await tester.pumpWidget(const MaterialApp(home: ChataptorChatScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Currently offline'), findsNothing);
  });

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
