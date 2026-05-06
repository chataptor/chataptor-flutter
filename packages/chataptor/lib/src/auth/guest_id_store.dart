import 'dart:math';

import 'package:chataptor/src/storage/chataptor_storage.dart';

/// Manages the device-stable anonymous guest ID used when the customer has
/// not provided an identified [CustomerIdentity].
///
/// The guest ID is scoped per [siteId] so two shops on the same device do
/// not share a conversation history.
class GuestIdStore {
  /// Creates a [GuestIdStore].
  GuestIdStore({required this.storage, required this.siteId});

  /// Storage adapter backing the store.
  final ChataptorStorage storage;

  /// Site the guest ID is scoped to.
  final String siteId;

  String get _key => 'chataptor.guest_id.$siteId';

  /// Returns the existing guest ID for this site or allocates one on first
  /// call and persists it.
  Future<String> getOrCreate() async {
    final existing = await storage.readString(_key);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generate();
    await storage.writeString(_key, generated);
    return generated;
  }

  /// Deletes the stored guest ID — subsequent [getOrCreate] returns a fresh
  /// one.
  Future<void> clear() => storage.delete(_key);

  String _generate() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'guest-$hex';
  }
}
