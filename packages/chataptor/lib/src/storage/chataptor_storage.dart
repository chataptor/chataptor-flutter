/// Port abstraction over a key/value persistent store used by the SDK for
/// small, non-sensitive state (guest ID, last session metadata, etc.).
///
/// Default implementation in the pure-Dart core is in-memory only. Flutter
/// apps get a `SharedPreferences`-backed implementation via
/// `chataptor_flutter`. Merchants who need encrypted storage pass their own
/// implementation (e.g. wrapping `flutter_secure_storage`).
abstract interface class ChataptorStorage {
  /// Returns the value for [key] or `null` if the key is absent.
  Future<String?> readString(String key);

  /// Stores [value] under [key], overwriting any existing value.
  Future<void> writeString(String key, String value);

  /// Removes [key] from storage. No-op if absent.
  Future<void> delete(String key);

  /// Removes every key-value pair.
  Future<void> clear();
}
