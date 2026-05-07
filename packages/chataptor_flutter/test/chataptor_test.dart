import 'package:chataptor/testing.dart';
import 'package:chataptor_flutter/chataptor_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Chataptor.reset();
  });

  test('init constructs a ChataptorClient and exposes instance', () async {
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: FakeChatTransport(),
    );
    expect(Chataptor.instance, isNotNull);
    expect(Chataptor.instance.config.siteId, 'abc');
  });

  test('calling init twice is an error', () async {
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: FakeChatTransport(),
    );
    expect(
      () => Chataptor.init(
        siteId: 'abc',
        widgetKey: 'pk_x',
        apiUrl: Uri.parse('http://localhost:4000'),
        transport: FakeChatTransport(),
      ),
      throwsA(isA<ChataptorStateError>()),
    );
  });

  test('accessing instance before init throws', () {
    expect(() => Chataptor.instance, throwsA(isA<ChataptorStateError>()));
  });

  test('reset allows re-init', () async {
    await Chataptor.init(
      siteId: 'abc',
      widgetKey: 'pk_x',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: FakeChatTransport(),
    );
    Chataptor.reset();
    await Chataptor.init(
      siteId: 'def',
      widgetKey: 'pk_y',
      apiUrl: Uri.parse('http://localhost:4000'),
      transport: FakeChatTransport(),
    );
    expect(Chataptor.instance.config.siteId, 'def');
  });
}
