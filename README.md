# Chataptor Flutter SDK

> Real-time multilingual customer support chat for Flutter. One agent, 100 languages, zero awkward translations.

Official Flutter SDK for [Chataptor](https://chataptor.com) — adds live customer support to your mobile and web Flutter apps with built-in bidirectional auto-translation, so your support team can serve customers in any language without hiring polyglots.

## Status

**🚧 Work in progress — design phase.** Not yet published to pub.dev.

The design document lives in [`docs/specs/`](./docs/specs/) and is being iterated on before the first implementation milestone. Follow this repo to be notified when `v0.1.0` ships.

## What makes Chataptor different

- 🌍 **Real-time bidirectional auto-translation** — customer writes in Japanese, your agent reads Polish, replies in Polish, customer reads Japanese. No workflow change.
- 📘 **Translation Memory + Glossary** — terminology stays consistent across conversations, brand terms never get lost in translation.
- 📧 **Email threading + offline-first** — customer closes the app mid-conversation, agent replies, customer gets an email, replies by email, history stays unified.
- 🎨 **Pure Dart** — no native SDK wrappers. Works on iOS, Android, and Flutter Web from day one. Smaller app size, fewer platform-specific bugs.
- 🔓 **Open source, MIT** — audit the client code before shipping to production.

## Packages

This is a monorepo. Packages will be published separately to pub.dev:

- **`chataptor_flutter`** — headless core client (sockets, auth, streams, hooks).
- **`chataptor_flutter_ui`** — opinionated drop-in chat UI built on the core.

Use the UI package for a 3-line integration. Use the core directly when you want full control over the chat interface.

## Installation

> Coming with `v0.1.0`.

## License

[MIT](./LICENSE) © 2026 Chataptor

## Links

- Product: [chataptor.com](https://chataptor.com)
- API specification: coming soon
- Design document: [`docs/specs/`](./docs/specs/)
