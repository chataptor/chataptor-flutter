import 'package:http/http.dart' as http;

/// Port abstraction over the HTTP client used for REST calls (uploads, push
/// token registration, history pagination).
///
/// Default implementation wraps `package:http`'s `Client` directly.
/// Merchants may pass a custom implementation to inject Dio, cert pinning,
/// or auth interceptors.
abstract interface class ChataptorHttpClient {
  /// Performs a request and returns the response.
  Future<http.Response> send(http.Request request);

  /// Releases any underlying resources.
  void close();
}

/// Default [ChataptorHttpClient] backed by `package:http`'s `Client`.
class DefaultChataptorHttpClient implements ChataptorHttpClient {
  /// Creates a [DefaultChataptorHttpClient] wrapping a fresh [http.Client].
  DefaultChataptorHttpClient([http.Client? inner])
      : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.Response> send(http.Request request) async {
    final streamed = await _inner.send(request);
    return http.Response.fromStream(streamed);
  }

  @override
  void close() => _inner.close();
}
