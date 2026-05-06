import 'package:chataptor/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  test('read of absent key returns null', () async {
    final storage = InMemoryChataptorStorage();
    expect(await storage.readString('missing'), isNull);
  });

  test('write then read returns same value', () async {
    final storage = InMemoryChataptorStorage();
    await storage.writeString('k', 'v');
    expect(await storage.readString('k'), 'v');
  });

  test('delete removes the key', () async {
    final storage = InMemoryChataptorStorage();
    await storage.writeString('k', 'v');
    await storage.delete('k');
    expect(await storage.readString('k'), isNull);
  });

  test('clear wipes everything', () async {
    final storage = InMemoryChataptorStorage();
    await storage.writeString('a', '1');
    await storage.writeString('b', '2');
    await storage.clear();
    expect(await storage.readString('a'), isNull);
    expect(await storage.readString('b'), isNull);
  });
}
