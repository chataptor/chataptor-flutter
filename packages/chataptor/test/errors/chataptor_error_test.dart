import 'package:chataptor/src/errors/chataptor_error.dart';
import 'package:test/test.dart';

void main() {
  group('ChataptorError subtypes', () {
    test('AuthenticationError carries message', () {
      const e = AuthenticationError('invalid widget key');
      expect(e.message, 'invalid widget key');
    });

    test('RateLimitError carries retryAfter', () {
      const e = RateLimitError('rate limited', retryAfter: Duration(seconds: 30));
      expect(e.retryAfter, const Duration(seconds: 30));
    });

    test('ValidationError carries field errors', () {
      const e = ValidationError(
        'invalid fields',
        fieldErrors: {'email': ['invalid format']},
      );
      expect(e.fieldErrors['email'], ['invalid format']);
    });

    test('pattern match is exhaustive', () {
      String kind(ChataptorError e) => switch (e) {
        AuthenticationError() => 'auth',
        NetworkError() => 'net',
        RateLimitError() => 'rate',
        ServerError() => 'server',
        ValidationError() => 'validation',
        ConnectionLostError() => 'conn_lost',
      };

      expect(kind(const AuthenticationError('x')), 'auth');
      expect(kind(const NetworkError('x')), 'net');
      expect(kind(const RateLimitError('x', retryAfter: Duration.zero)), 'rate');
      expect(kind(const ServerError('x')), 'server');
      expect(kind(const ValidationError('x', fieldErrors: {})), 'validation');
      expect(kind(const ConnectionLostError('x')), 'conn_lost');
    });
  });

  group('ChataptorStateError', () {
    test('is a StateError subtype', () {
      final e = ChataptorStateError('call init() first');
      expect(e, isA<StateError>());
      expect(e.message, 'call init() first');
    });
  });

  group('ChataptorConfigurationError', () {
    test('is an ArgumentError subtype', () {
      final e = ChataptorConfigurationError('widgetKey is empty');
      expect(e, isA<ArgumentError>());
      expect(e.message, 'widgetKey is empty');
    });
  });
}
