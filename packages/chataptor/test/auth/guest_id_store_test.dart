import 'package:chataptor/src/auth/guest_id_store.dart';
import 'package:chataptor/src/storage/in_memory_storage.dart';
import 'package:test/test.dart';

void main() {
  test('getOrCreate returns a stable id across calls', () async {
    final storage = InMemoryChataptorStorage();
    final store = GuestIdStore(storage: storage, siteId: 'abc');
    final first = await store.getOrCreate();
    final second = await store.getOrCreate();
    expect(first, second);
  });

  test('different siteIds get different guest ids', () async {
    final storage = InMemoryChataptorStorage();
    final a = await GuestIdStore(storage: storage, siteId: 'a').getOrCreate();
    final b = await GuestIdStore(storage: storage, siteId: 'b').getOrCreate();
    expect(a, isNot(b));
  });

  test('clear deletes the stored id', () async {
    final storage = InMemoryChataptorStorage();
    final store = GuestIdStore(storage: storage, siteId: 'abc');
    final first = await store.getOrCreate();
    await store.clear();
    final second = await store.getOrCreate();
    expect(first, isNot(second));
  });

  test('generated id has expected shape', () async {
    final store = GuestIdStore(
      storage: InMemoryChataptorStorage(),
      siteId: 'abc',
    );
    final id = await store.getOrCreate();
    expect(id, startsWith('guest-'));
    expect(id.length > 10, isTrue);
  });
}
