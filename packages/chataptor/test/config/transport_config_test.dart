import 'package:chataptor/src/config/transport_config.dart';
import 'package:test/test.dart';

void main() {
  test('ConnectionMode has two entries', () {
    expect(ConnectionMode.values, [
      ConnectionMode.lazy,
      ConnectionMode.foregroundActive,
    ]);
  });

  test('ReconnectionPolicy.exponentialBackoff produces growing delays', () {
    final policy = ReconnectionPolicy.exponentialBackoff(
      initialDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(seconds: 10),
      maxAttempts: 5,
    );
    final delays = policy.delays;
    expect(delays, hasLength(5));
    expect(delays.first, const Duration(milliseconds: 100));
    expect(delays.last.inSeconds <= 10, isTrue);
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i] >= delays[i - 1], isTrue);
    }
  });

  test('TransportClientConfig has sensible defaults', () {
    const config = TransportClientConfig();
    expect(config.connectionMode, ConnectionMode.lazy);
    expect(config.heartbeatInterval, const Duration(seconds: 30));
    expect(config.reconnection.delays, isNotEmpty);
  });

  test('TransportClientConfig copyWith', () {
    const config = TransportClientConfig();
    final updated = config.copyWith(
      connectionMode: ConnectionMode.foregroundActive,
      heartbeatInterval: const Duration(seconds: 45),
    );
    expect(updated.connectionMode, ConnectionMode.foregroundActive);
    expect(updated.heartbeatInterval, const Duration(seconds: 45));
  });
}
