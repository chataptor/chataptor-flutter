# Changelog

All notable changes to this package will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-MM-DD

### Added

- `Chataptor.init` / `Chataptor.instance` singleton.
- `ChataptorScope` inherited widget for multi-instance and test scenarios.
- `ChataptorLifecycleObserver` — disconnects on `paused`, reconnects on `resumed` in `foregroundActive` connection mode.
- `SharedPreferencesChataptorStorage` adapter.
- `ValueListenableStream` adapter.
- `ChataptorTheme` with `light()` and `matching(context)` factories.
- `ChataptorLocalizations` with English and Polish.
- Widgets: `ChataptorMessageBubble`, `ChataptorMessageList`, `ChataptorComposer`, `ChataptorChatScreen`.
- Transitively exports the `chataptor` core package.
