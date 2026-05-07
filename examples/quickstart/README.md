# Quickstart Example

Minimal Flutter app demonstrating how to integrate Chataptor in three steps.

## Run

```bash
cd examples/quickstart
flutter pub get
flutter run
```

> This sample uses placeholder credentials (`demo-site` / `pk_demo_key`).
> Swap for your real site ID and widget key from the Chataptor admin console
> before connecting to a live backend.

## What it does

1. `Chataptor.init(siteId, widgetKey)` in `main()`.
2. A button pushes `ChataptorChatScreen` via `Navigator.push`.
3. The screen manages its own socket connection and message list.
