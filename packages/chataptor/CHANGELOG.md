# Changelog

All notable changes to this package will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-22

### Added

- `ChataptorClient.identify()` — migrates the active session to a new `CustomerIdentity` (e.g., after the customer signs in). Reconnects when the client is currently `Connected` so the next channel join carries the updated identity. Throws `ChataptorStateError` when invoked during `Connecting` / `Reconnecting` — call only when the connection is stable.
- `FakeChataptorClient.identify()` stub + `recorded.identifyCalls` for asserting that a host-app sign-in flow invoked identify.
- `ChataptorConfig.sessionIdleTimeout` — when set, the SDK persists `last_activity_at` on every send / receive and clears the stored guest session at the start of the next `connect()` if the gap exceeds the timeout. Idle expiry takes precedence over `identify()`'s continuity guarantee.
- `SiteConfig.nextAvailable` — best-effort UTC timestamp parsed from the backend's `site_config` payload indicating when an agent is next expected to be available. Always `null` when the backend has not computed or chosen to expose this value.
- `clearSession()` now also removes the persisted `last_activity_at` stamp so the next `connect()` starts on a clean slate.

### Changed

- `guestId` is now always sent on socket connect — even for identified customers — so conversation continuity is preserved when a customer migrates from anonymous to identified mid-session via `identify()`.
- Identified customer attributes are now packed into a single `customerData` map on socket connect (`{email, name, hash?, ...customData}`) instead of separate top-level `customerEmail` / `customerName` keys.
- `connect()` now sends `customerName` / `customerEmail` in the `conversation:create` payload when the customer is identified, so the conversation gets the right attribution from the first message.
- `ChataptorClient.internal` and the default constructor now share a single in-memory storage instance between the client's own state and the internal `GuestIdStore` when no storage adapter is provided. Previously two separate `InMemoryChataptorStorage` instances were silently created.

## [0.1.0] - 2026-05-19

### Added

- `ChataptorClient` with anonymous customer identification, connect/disconnect lifecycle, and `sendMessage` over Phoenix Channels.
- `ChatTransport` port abstraction with `PhoenixSocketTransport` reference implementation and `FakeChatTransport` test double.
- Sealed Dart 3 types: `ConnectionState`, `ChataptorError`, `SendResult`.
- Immutable domain models: `Message`, `Conversation`, `AgentInfo`, `Attachment`, `CustomerIdentity`, `MessageDraft`.
- Configuration tree: `ChataptorConfig`, `TransportClientConfig`, `TranslationConfig`, `FeatureToggles`, `AttachmentConfig`, `PushConfig`, `ChataptorHooks`.
- Adapter ports with in-memory defaults: `ChataptorStorage`, `ChataptorHttpClient`, `ChataptorLogger`.
- Testing sub-library (`package:chataptor/testing.dart`) with `FakeChataptorClient`, `FakeChatTransport`, `InMemoryChataptorStorage`, `RecordingChataptorLogger`.
- `SiteConfig` model parsed from the `site:X` channel join payload (welcome message, header title per active language, offline mode, language variants).
- `AgentInfo` model (with `AgentInitials`) + subscriptions to backend `agent:available` / `agents:offline` events; exposed via `ChataptorClient.currentOnlineAgents` and `onlineAgentsStream`.
- Client-side injection of the configured `welcome_message` as the first agent `Message` when conversation history is empty (mirrors the web widget behaviour). Skipped on reconnect with non-empty history to avoid duplication.
