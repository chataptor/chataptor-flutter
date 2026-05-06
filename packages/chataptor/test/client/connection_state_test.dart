import 'package:chataptor/src/client/connection_state.dart';
import 'package:test/test.dart';

void main() {
  group('ConnectionState', () {
    test('Disconnected carries a reason', () {
      const state = Disconnected(DisconnectReason.userRequested);
      expect(state.reason, DisconnectReason.userRequested);
    });

    test('Reconnecting carries attempt metadata', () {
      const state = Reconnecting(
        nextAttemptIn: Duration(seconds: 2),
        attemptNumber: 3,
      );
      expect(state.nextAttemptIn, const Duration(seconds: 2));
      expect(state.attemptNumber, 3);
    });

    test('pattern match is exhaustive', () {
      String label(ConnectionState s) => switch (s) {
        Connecting() => 'connecting',
        Connected() => 'connected',
        Reconnecting() => 'reconnecting',
        Disconnected() => 'disconnected',
      };

      expect(label(const Connecting()), 'connecting');
      expect(label(const Connected()), 'connected');
      expect(
        label(
          const Reconnecting(
            nextAttemptIn: Duration(seconds: 1),
            attemptNumber: 1,
          ),
        ),
        'reconnecting',
      );
      expect(
        label(const Disconnected(DisconnectReason.networkError)),
        'disconnected',
      );
    });

    test('equality compares concrete subtype and payload', () {
      expect(const Connected(), const Connected());
      expect(
        const Disconnected(DisconnectReason.userRequested),
        const Disconnected(DisconnectReason.userRequested),
      );
      expect(
        const Disconnected(DisconnectReason.userRequested),
        isNot(const Disconnected(DisconnectReason.networkError)),
      );
    });
  });
}
