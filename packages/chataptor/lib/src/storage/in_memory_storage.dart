import 'package:chataptor/src/storage/chataptor_storage.dart';

/// Default non-persistent [ChataptorStorage] used by the pure-Dart core.
///
/// Flutter apps replace this with a `SharedPreferences`-backed adapter at
/// `Chataptor.init` time.
class InMemoryChataptorStorage implements ChataptorStorage {
  /// Creates a new [InMemoryChataptorStorage] with an empty data map.
  InMemoryChataptorStorage();

  final Map<String, String> _data = {};

  @override
  Future<String?> readString(String key) async => _data[key];

  @override
  Future<void> writeString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}
