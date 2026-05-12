import 'package:chataptor/src/auth/customer_identity.dart';
import 'package:chataptor/src/config/feature_toggles.dart';
import 'package:chataptor/src/config/push_config.dart';
import 'package:chataptor/src/config/translation_config.dart';
import 'package:chataptor/src/config/transport_config.dart';
import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:chataptor/src/hooks/chataptor_hooks.dart';
import 'package:chataptor/src/http/chataptor_http_client.dart';
import 'package:chataptor/src/logger/chataptor_logger.dart';
import 'package:chataptor/src/storage/chataptor_storage.dart';
import 'package:meta/meta.dart';

/// Root configuration for `ChataptorClient`.
///
/// See the design spec (docs/specs/2026-04-22-flutter-sdk-design.md §6.1)
/// for the three intended onboarding tiers (quickstart / identified /
/// full).
@immutable
class ChataptorConfig {
  /// Creates a [ChataptorConfig].
  ///
  /// Throws [ChataptorConfigurationError] if [siteId] or [widgetKey] is
  /// empty.
  ChataptorConfig({
    required this.siteId,
    required this.widgetKey,
    Uri? apiUrl,
    this.customer = const CustomerIdentity.anonymous(),
    this.transport = const TransportClientConfig(),
    TranslationConfig? translation,
    this.features = const FeatureToggles(),
    PushConfig? push,
    this.hooks = const ChataptorHooks(),
    this.storage,
    this.httpClient,
    this.logger = const NoOpChataptorLogger(),
  }) : apiUrl = apiUrl ?? Uri.parse('https://chataptor.com'),
       translation = translation ?? TranslationConfig.auto(),
       push = push ?? PushConfig.disabled() {
    if (siteId.isEmpty) {
      throw ChataptorConfigurationError('siteId must not be empty');
    }
    if (widgetKey.isEmpty) {
      throw ChataptorConfigurationError('widgetKey must not be empty');
    }
  }

  /// Chataptor site identifier (from the Chataptor admin console).
  final String siteId;

  /// Widget API key for this site (public — safe to embed in client code).
  final String widgetKey;

  /// Base REST API URL. Defaults to `https://chataptor.com`.
  final Uri apiUrl;

  /// Customer identity.
  final CustomerIdentity customer;

  /// Transport configuration.
  final TransportClientConfig transport;

  /// Translation configuration — first class.
  final TranslationConfig translation;

  /// Feature toggles.
  final FeatureToggles features;

  /// Push configuration.
  final PushConfig push;

  /// Hook callbacks and interceptors.
  final ChataptorHooks hooks;

  /// Optional storage adapter override. If null, the SDK supplies a
  /// platform default (pure-Dart: in-memory; Flutter: SharedPreferences).
  final ChataptorStorage? storage;

  /// Optional HTTP client override.
  final ChataptorHttpClient? httpClient;

  /// Logger.
  final ChataptorLogger logger;

  /// Returns a copy with the given fields overridden.
  ChataptorConfig copyWith({
    String? siteId,
    String? widgetKey,
    Uri? apiUrl,
    CustomerIdentity? customer,
    TransportClientConfig? transport,
    TranslationConfig? translation,
    FeatureToggles? features,
    PushConfig? push,
    ChataptorHooks? hooks,
    ChataptorStorage? storage,
    ChataptorHttpClient? httpClient,
    ChataptorLogger? logger,
  }) {
    return ChataptorConfig(
      siteId: siteId ?? this.siteId,
      widgetKey: widgetKey ?? this.widgetKey,
      apiUrl: apiUrl ?? this.apiUrl,
      customer: customer ?? this.customer,
      transport: transport ?? this.transport,
      translation: translation ?? this.translation,
      features: features ?? this.features,
      push: push ?? this.push,
      hooks: hooks ?? this.hooks,
      storage: storage ?? this.storage,
      httpClient: httpClient ?? this.httpClient,
      logger: logger ?? this.logger,
    );
  }
}
