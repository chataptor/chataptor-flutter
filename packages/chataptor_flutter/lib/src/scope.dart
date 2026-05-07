import 'package:chataptor/chataptor.dart';
import 'package:chataptor_flutter/src/chataptor.dart';
import 'package:flutter/widgets.dart';

/// Makes a [ChataptorClient] available to descendants via
/// [ChataptorScope.of]. Falls back to [Chataptor.instance] if no scope is
/// in the tree.
class ChataptorScope extends InheritedWidget {
  /// Creates a [ChataptorScope] around [child] with an explicit [client].
  const ChataptorScope({
    super.key,
    required this.client,
    required super.child,
  });

  /// The client exposed to descendants.
  final ChataptorClient client;

  /// Returns the nearest [ChataptorScope] ancestor, or a synthetic one
  /// wrapping [Chataptor.instance] if none is found. Throws
  /// [ChataptorStateError] if neither a scope nor [Chataptor.init] is
  /// available.
  static ChataptorScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ChataptorScope>();
    if (scope != null) return scope;
    return ChataptorScope(
      client: Chataptor.instance,
      child: const SizedBox.shrink(),
    );
  }

  @override
  bool updateShouldNotify(covariant ChataptorScope oldWidget) =>
      client != oldWidget.client;
}
