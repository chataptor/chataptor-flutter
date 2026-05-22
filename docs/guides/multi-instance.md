# Running multiple Chataptor sites in one app

Most apps only ever talk to one Chataptor site, and the singleton
`Chataptor.instance` is enough. Resellers, white-label hosts, and any
app that serves more than one brand from the same binary need
something more: separate clients with separate configs, side by side.

The SDK supports this through `ChataptorScope` — a Flutter
`InheritedWidget` that scopes a `ChataptorClient` to a subtree.
`ChataptorChatScreen` and the other drop-in widgets resolve the client
to use via `ChataptorScope.of(context)`, walking up the tree to the
nearest scope.

## The shape

```dart
ChataptorClient brandAClient;
ChataptorClient brandBClient;

@override
void initState() {
  super.initState();
  brandAClient = ChataptorClient(
    config: ChataptorConfig(
      siteId: 'brand-a-site-id',
      widgetKey: 'pk_brand_a',
    ),
  );
  brandBClient = ChataptorClient(
    config: ChataptorConfig(
      siteId: 'brand-b-site-id',
      widgetKey: 'pk_brand_b',
    ),
  );
}

@override
void dispose() {
  brandAClient.dispose();
  brandBClient.dispose();
  super.dispose();
}
```

Wrap each subtree with its own scope:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    home: Navigator(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/brand-a/support':
            return MaterialPageRoute(
              builder: (_) => ChataptorScope(
                client: brandAClient,
                child: const ChataptorChatScreen(),
              ),
            );
          case '/brand-b/support':
            return MaterialPageRoute(
              builder: (_) => ChataptorScope(
                client: brandBClient,
                child: const ChataptorChatScreen(),
              ),
            );
        }
        return null;
      },
    ),
  );
}
```

## What you skip

- **Do not call `Chataptor.init`.** That sets up the *singleton*, which
  is mutually exclusive with the per-scope pattern. If both are present
  in the tree, `ChataptorScope.of` returns the scope, but you've paid
  for two unrelated identity stores and two SharedPreferences keys for
  nothing.
- **Do not share `ChataptorConfig` across clients.** Each client owns
  its own `siteId`, `widgetKey`, customer identity, and storage
  namespace — the config is intentionally immutable and one-to-one
  with a client.

## Storage isolation

The default Flutter storage adapter is `SharedPreferencesStorage`,
which writes guest IDs and session metadata under the SDK's own keys.
Two clients on two different `siteId`s will not clobber each other:
the keys already include the `siteId`. You only need a custom storage
adapter when you want fully separate encrypted stores per brand —
e.g., wrapping `flutter_secure_storage` with a brand-specific prefix.

## Lifecycle and connection modes

Each client owns its own connection. With the default
`ConnectionMode.lazy`, a client connects when its chat screen mounts
and disconnects when it unmounts. Mounting brand A's chat does **not**
incidentally connect brand B's client.

If you use `ConnectionMode.foregroundActive`, the lifecycle observer
manages each client independently — register two observers, one per
client, in your top-level state.

## Testing

`FakeChatTransport` is per-instance: build one fake per client and
hand each to its own client via the test-only `ChataptorClient.internal`
constructor — `ChataptorClient.internal(config: ..., transport: fake)`.
The public `ChataptorClient(config: ...)` constructor always uses the
real Phoenix transport; reach for `.internal` only in tests. Drop-in
widget tests work the same way — wrap the widget you want to test in
`ChataptorScope` with the matching client.

## See also

- [Getting started](./getting-started.md)
- [Architecture decisions](../../ARCHITECTURE.md) — decision #1 explains
  the two-package split that makes per-scope clients cheap.
