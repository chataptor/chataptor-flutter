import 'package:chataptor_flutter/src/adapters/shared_preferences_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('read of absent key returns null', () async {
    final storage = await SharedPreferencesChataptorStorage.create();
    expect(await storage.readString('missing'), isNull);
  });

  test('write then read', () async {
    final storage = await SharedPreferencesChataptorStorage.create();
    await storage.writeString('k', 'v');
    expect(await storage.readString('k'), 'v');
  });

  test('delete removes the key', () async {
    final storage = await SharedPreferencesChataptorStorage.create();
    await storage.writeString('k', 'v');
    await storage.delete('k');
    expect(await storage.readString('k'), isNull);
  });

  test('clear wipes only chataptor-prefixed keys', () async {
    SharedPreferences.setMockInitialValues({'external_key': 'keep'});
    final storage = await SharedPreferencesChataptorStorage.create();
    await storage.writeString('a', '1');
    await storage.writeString('b', '2');

    await storage.clear();

    expect(await storage.readString('a'), isNull);
    expect(await storage.readString('b'), isNull);
    // External key preserved.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('external_key'), 'keep');
  });
}
