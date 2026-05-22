# Changelog

All notable changes to this package will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-22

### Added

- `ChataptorChatScreen.showAppBar` — opt-out of the screen's internal `AppBar` when embedding the chat inside a bottom sheet, dialog, or any host that provides its own chrome. The agent-presence header still renders inline at the top of the body so customers keep the "who's online" cue regardless of how the chat is mounted.
- Offline UX MVP — when the backend reports `OfflineMode.manualOffline` for the active site, an inline banner is rendered above the composer and the composer itself is disabled. Variant-level `offline_title` / `offline_subtitle` strings take precedence over the bundled localized fallbacks.
- `ChataptorLocalizations.offlineBannerTitle` and `offlineBannerSubtitle` for the offline banner copy (English + Polish).

### Changed

- Bumped `chataptor` dependency constraint to `^0.2.0` to pick up the new `ChataptorClient.identify()`, `ChataptorConfig.sessionIdleTimeout`, and the identified-customer attribution fix. See the [`chataptor` 0.2.0 changelog](https://pub.dev/packages/chataptor/changelog) for the full list.

## [0.1.0] - 2026-05-19

### Added

- `Chataptor.init` / `Chataptor.instance` singleton.
- `ChataptorScope` inherited widget for multi-instance and test scenarios.
- `ChataptorLifecycleObserver` — disconnects on `paused`, reconnects on `resumed` in `foregroundActive` connection mode.
- `SharedPreferencesChataptorStorage` adapter.
- `ValueListenableStream` adapter.
- `ChataptorTheme` with `light()` and `matching(context)` factories.
- `ChataptorLocalizations` with English and Polish.
- Widgets: `ChataptorMessageBubble`, `ChataptorMessageList`, `ChataptorComposer`, `ChataptorChatScreen`, `ChataptorChatHeader`.
- `ChataptorChatHeader` shows an avatar stack of currently online agents (up to 3 visible + overflow badge), the configured team name (e.g. "Customer Support") from `SiteConfig.headerTitle`, and a live Online/Offline status indicator driven by `onlineAgentsStream`. Replaces the previous hardcoded `'Support'` AppBar title in `ChataptorChatScreen`.
- Transitively exports the `chataptor` core package.
