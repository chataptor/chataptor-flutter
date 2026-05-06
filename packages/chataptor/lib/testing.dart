/// Testing helpers for merchants integrating `package:chataptor` and for
/// developers working on the SDK itself.
///
/// Import as `package:chataptor/testing.dart` from `test/` files — never
/// import these symbols from production code. Prod-exported transport port
/// lives in `package:chataptor/chataptor.dart` as `ChatTransport`.
library chataptor.testing;

// Merchant-facing: high-level fake for widget tests of the host app.
export 'src/testing/fake_chataptor_client.dart';

// SDK-developer-facing: transport-level fake for unit tests of the SDK.
export 'src/transport/fake_chat_transport.dart';

// Transport value types — needed to script `FakeChatTransport` and assert on
// the transport layer. Public-from-tests-only.
export 'src/transport/transport_types.dart'
    show
        TransportConfig,
        TransportEvent,
        MessageReceived,
        ChannelClosed,
        ChannelError,
        TransportConnectionState,
        TransportConnecting,
        TransportConnected,
        TransportReconnecting,
        TransportDisconnected,
        PushResult,
        PushOk,
        PushServerError,
        PushTimeout,
        PushDisconnected;

// Convenience in-memory adapters for `ChataptorStorage` and `ChataptorLogger`.
export 'src/storage/in_memory_storage.dart';
export 'src/logger/chataptor_logger.dart' show RecordingChataptorLogger;
