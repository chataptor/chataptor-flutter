import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/adapters/shared_preferences_storage.dart';
import 'package:chataptor_flutter/src/lifecycle.dart';

/// Singleton entry point for Flutter apps.
///
/// 99% of merchants call [Chataptor.init] once at app start and thereafter
/// access the SDK via [Chataptor.instance]. Multi-instance scenarios
/// construct [ChataptorClient] directly — see the spec §6.1.
class Chataptor {
  Chataptor._();

  static ChataptorClient? _client;
  static ChataptorLifecycleObserver? _lifecycleObserver;

  /// The process-wide [ChataptorClient]. Throws [ChataptorStateError] if
  /// [init] has not been called.
  static ChataptorClient get instance {
    final c = _client;
    if (c == null) {
      throw ChataptorStateError(
        'Chataptor.instance accessed before Chataptor.init()',
      );
    }
    return c;
  }

  /// Whether [init] has been called.
  static bool get isInitialized => _client != null;

  /// Initialises the SDK singleton.
  ///
  /// Tier 1 quickstart: supply [siteId] and [widgetKey]. Tier 2 adds
  /// [customer]. Tier 3 passes a full [config] directly (set [config] and
  /// leave the ergonomic params null).
  ///
  /// Tests may pass a [transport] override to inject a `FakeChatTransport`.
  /// Production code never does.
  static Future<void> init({
    String? siteId,
    String? widgetKey,
    CustomerIdentity? customer,
    Uri? apiUrl,
    ChataptorConfig? config,
    ChatTransport? transport,
  }) async {
    if (_client != null) {
      throw ChataptorStateError(
        'Chataptor.init called twice — call Chataptor.reset() first',
      );
    }

    final effectiveConfig =
        config ??
        ChataptorConfig(
          siteId: siteId ?? _required('siteId'),
          widgetKey: widgetKey ?? _required('widgetKey'),
          apiUrl: apiUrl,
          customer: customer ?? const CustomerIdentity.anonymous(),
        );

    final storage =
        effectiveConfig.storage ??
        await SharedPreferencesChataptorStorage.create();

    _client = transport == null
        ? ChataptorClient(config: effectiveConfig.copyWith(storage: storage))
        : ChataptorClient.internal(
            config: effectiveConfig.copyWith(storage: storage),
            transport: transport,
            storage: storage,
          );

    _lifecycleObserver = ChataptorLifecycleObserver(client: _client!)..attach();
  }

  /// Tears down the singleton. Use between tests or when logging out a
  /// multi-tenant host app.
  static void reset() {
    _lifecycleObserver?.detach();
    _lifecycleObserver = null;
    final existing = _client;
    _client = null;
    existing?.dispose();
  }

  static String _required(String name) => throw ChataptorConfigurationError(
    'Chataptor.init: $name is required when config is not supplied',
  );
}
