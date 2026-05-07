import 'package:chataptor/testing.dart';
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Chataptor.reset();
  });

  testWidgets('ChataptorScope.of returns the provided client', (tester) async {
    final client = ChataptorClient.internal(
      config: ChataptorConfig(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
      ),
      transport: FakeChatTransport(),
    );
    ChataptorClient? found;

    await tester.pumpWidget(
      MaterialApp(
        home: ChataptorScope(
          client: client,
          child: Builder(
            builder: (ctx) {
              found = ChataptorScope.of(ctx).client;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(found, client);
  });

  testWidgets('ChataptorScope.of falls back to Chataptor.instance', (
    tester,
  ) async {
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: FakeChatTransport(),
    );

    ChataptorClient? found;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            found = ChataptorScope.of(ctx).client;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(found, Chataptor.instance);
  });
}
