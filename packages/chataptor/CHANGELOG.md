# Changelog

All notable changes to this package will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-MM-DD

### Added

- `ChataptorClient` with anonymous customer identification, connect/disconnect lifecycle, and `sendMessage` over Phoenix Channels.
- `ChatTransport` port abstraction with `PhoenixSocketTransport` reference implementation and `FakeChatTransport` test double.
- Sealed Dart 3 types: `ConnectionState`, `ChataptorError`, `SendResult`.
- Immutable domain models: `Message`, `Conversation`, `AgentInfo`, `Attachment`, `CustomerIdentity`, `MessageDraft`.
- Configuration tree: `ChataptorConfig`, `TransportClientConfig`, `TranslationConfig`, `FeatureToggles`, `AttachmentConfig`, `PushConfig`, `ChataptorHooks`.
- Adapter ports with in-memory defaults: `ChataptorStorage`, `ChataptorHttpClient`, `ChataptorLogger`.
- Testing sub-library (`package:chataptor/testing.dart`) with `FakeChataptorClient`, `FakeChatTransport`, `InMemoryChataptorStorage`, `RecordingChataptorLogger`.
- `SiteConfig` model parsed from the `site:X` channel join payload (welcome message, header title per active language, offline mode, language variants).
- `AgentInfo` model + subscriptions to backend `agent:available` / `agents:offline` events; exposed via `ChataptorClient.currentOnlineAgents` and `onlineAgentsStream`.
- Client-side injection of the configured `welcome_message` as the first agent `Message` when conversation history is empty (mirrors the web widget behaviour). Skipped on reconnect with non-empty history to avoid duplication.
