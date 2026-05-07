import 'package:chataptor/chataptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default Flutter-side [ChataptorStorage] — writes to `SharedPreferences`
/// under a `chataptor.` key prefix so [clear] only wipes SDK state and
/// leaves the host app's other preferences untouched.
class SharedPreferencesChataptorStorage implements ChataptorStorage {
  SharedPreferencesChataptorStorage._(this._prefs);

  /// Async factory — resolves the shared [SharedPreferences] instance.
  static Future<SharedPreferencesChataptorStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesChataptorStorage._(prefs);
  }

  final SharedPreferences _prefs;

  static const String _prefix = 'chataptor.';

  @override
  Future<String?> readString(String key) async {
    return _prefs.getString('$_prefix$key');
  }

  @override
  Future<void> writeString(String key, String value) async {
    await _prefs.setString('$_prefix$key', value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove('$_prefix$key');
  }

  @override
  Future<void> clear() async {
    final ourKeys = _prefs
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in ourKeys) {
      await _prefs.remove(k);
    }
  }
}
