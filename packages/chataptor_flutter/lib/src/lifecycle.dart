import 'package:chataptor/chataptor.dart';
import 'package:flutter/widgets.dart';

/// Observes [AppLifecycleState] and toggles [ChataptorClient.connect] /
/// [ChataptorClient.disconnect] when the client is configured for
/// [ConnectionMode.foregroundActive].
///
/// In [ConnectionMode.lazy] the observer is a no-op — the chat UI itself
/// drives connection.
class ChataptorLifecycleObserver with WidgetsBindingObserver {
  /// Creates a [ChataptorLifecycleObserver] attached to [client].
  ChataptorLifecycleObserver({required this.client});

  /// The client whose lifecycle we drive.
  final ChataptorClient client;

  /// Registers the observer with [WidgetsBinding]. Call once during
  /// [Chataptor.init].
  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Deregisters the observer.
  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (client.config.transport.connectionMode !=
        ConnectionMode.foregroundActive) {
      return;
    }
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        client.disconnect();
      case AppLifecycleState.resumed:
        client.connect();
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }
}
