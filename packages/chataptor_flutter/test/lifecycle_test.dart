import 'package:chataptor/chataptor.dart';
import 'package:chataptor/testing.dart';
import 'package:chataptor_flutter/src/lifecycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ChataptorClient makeClient(ConnectionMode mode) => ChataptorClient.internal(
        config: ChataptorConfig(
          siteId: 'abc',
          widgetKey: 'pk_x',
          apiUrl: Uri.parse('http://localhost:4000'),
          transport: TransportClientConfig(connectionMode: mode),
        ),
        transport: FakeChatTransport(),
      );

  test('foregroundActive mode disconnects on paused, reconnects on resumed',
      () async {
    final client = makeClient(ConnectionMode.foregroundActive);
    final observer = ChataptorLifecycleObserver(client: client);

    await client.connect();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(client.currentConnectionState, isA<Disconnected>());

    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(client.currentConnectionState, isA<Connected>());
  });

  test('lazy mode ignores lifecycle transitions', () async {
    final client = makeClient(ConnectionMode.lazy);
    final observer = ChataptorLifecycleObserver(client: client);

    await client.connect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(client.currentConnectionState, isA<Connected>());

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // Still connected — lazy mode is caller-driven.
    expect(client.currentConnectionState, isA<Connected>());
  });
}
