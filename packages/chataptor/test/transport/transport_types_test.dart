import 'package:chataptor/src/transport/transport_types.dart';
import 'package:test/test.dart';

void main() {
  group('TransportConfig', () {
    test('carries url, params, heartbeat, reconnection policy', () {
      final config = TransportConfig(
        url: Uri.parse('wss://example.com/socket/websocket'),
        params: const {'widgetKey': 'pk_x', 'siteId': 'abc'},
        heartbeatInterval: const Duration(seconds: 30),
        reconnectionDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 5),
        ],
      );
      expect(config.url.toString(), 'wss://example.com/socket/websocket');
      expect(config.params['widgetKey'], 'pk_x');
      expect(config.heartbeatInterval, const Duration(seconds: 30));
      expect(config.reconnectionDelays, hasLength(3));
    });
  });

  group('TransportConnectionState', () {
    test('pattern match is exhaustive', () {
      String kind(TransportConnectionState s) => switch (s) {
        TransportConnecting() => 'connecting',
        TransportConnected() => 'connected',
        TransportReconnecting() => 'reconnecting',
        TransportDisconnected() => 'disconnected',
      };
      expect(kind(const TransportConnecting()), 'connecting');
      expect(kind(const TransportConnected()), 'connected');
      expect(
        kind(
          const TransportReconnecting(
            attemptNumber: 1,
            nextAttemptIn: Duration(seconds: 1),
          ),
        ),
        'reconnecting',
      );
      expect(
        kind(const TransportDisconnected(reason: 'closed')),
        'disconnected',
      );
    });
  });

  group('TransportEvent', () {
    test('MessageReceived carries topic + event + payload', () {
      const event = MessageReceived(
        topic: 'site:abc',
        event: 'message:received',
        payload: {'body': 'hi'},
      );
      expect(event.topic, 'site:abc');
      expect(event.event, 'message:received');
      expect(event.payload['body'], 'hi');
    });

    test('ChannelClosed carries reason', () {
      const event = ChannelClosed(topic: 'site:abc', reason: 'server');
      expect(event.reason, 'server');
    });

    test('pattern match is exhaustive', () {
      String kind(TransportEvent e) => switch (e) {
        MessageReceived() => 'msg',
        ChannelClosed() => 'closed',
        ChannelError() => 'error',
      };
      expect(
        kind(const MessageReceived(topic: 't', event: 'e', payload: {})),
        'msg',
      );
      expect(kind(const ChannelClosed(topic: 't', reason: 'r')), 'closed');
      expect(kind(const ChannelError(topic: 't', message: 'boom')), 'error');
    });
  });

  group('PushResult', () {
    test('PushOk carries response payload', () {
      const r = PushOk({'status': 'ok'});
      expect(r.response['status'], 'ok');
    });

    test('PushTimeout has a message', () {
      const r = PushTimeout();
      expect(r, isA<PushResult>());
    });

    test('PushServerError carries status and response', () {
      const r = PushServerError(reason: 'bad', response: {'error': 'x'});
      expect(r.reason, 'bad');
      expect(r.response['error'], 'x');
    });
  });
}
