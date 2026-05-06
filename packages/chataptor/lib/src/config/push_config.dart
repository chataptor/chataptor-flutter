import 'package:meta/meta.dart';

/// Platform identifier when registering a push token.
enum PushPlatform {
  /// Firebase Cloud Messaging — use for both Android and iOS apps that
  /// receive iOS pushes via FCM APNs forwarding.
  fcm,

  /// Native Apple Push Notification service — use for iOS apps that have
  /// their own APNs pipeline (not via Firebase). Server support for this
  /// variant lands in v2+.
  apnsDirect,
}

/// How the SDK participates in push notification delivery.
enum PushMode {
  /// SDK ignores pushes entirely. Default.
  disabled,

  /// Merchant wires up Firebase (or another push provider) themselves and
  /// hands the resulting device token to
  /// `ChataptorClient.registerPushToken`. The SDK forwards it to the
  /// Chataptor backend, which delivers pushes while the customer's socket
  /// is offline.
  hookIn,
}

/// Configuration for push notification delivery.
@immutable
class PushConfig {
  /// Creates a [PushConfig] with an explicit [mode]. Prefer the named
  /// factories.
  const PushConfig._(this.mode);

  /// Disables push integration entirely.
  factory PushConfig.disabled() => const PushConfig._(PushMode.disabled);

  /// Enables the merchant-owned hook-in flow.
  factory PushConfig.hookIn() => const PushConfig._(PushMode.hookIn);

  /// Active mode.
  final PushMode mode;
}
