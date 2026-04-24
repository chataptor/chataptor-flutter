# Chataptor Flutter SDK

> Real-time multilingual customer support chat for Flutter. One agent, many languages, zero awkward translations.

Official Flutter SDK for [Chataptor](https://chataptor.com) — adds live customer support to your mobile and web Flutter apps with built-in bidirectional auto-translation, so your support team can serve customers in any language without hiring polyglots.

## Status

**🚧 Work in progress — design phase.** Not yet published to pub.dev.

The design document lives in [`docs/specs/`](./docs/specs/) and the `v0.1.0` implementation plan in [`docs/plans/`](./docs/plans/). Follow this repo to be notified when `v0.1.0` ships.

## Why Chataptor

- 🌍 **Real-time bidirectional auto-translation** — customer writes in Japanese, your agent reads Polish, replies in Polish, customer reads Japanese. No workflow change.
- 📘 **Translation Memory + Glossary** — terminology stays consistent across conversations, brand terms never get lost in translation.
- 📧 **Email threading** — customer closes the app mid-conversation, agent replies, customer gets an email, replies by email, history stays unified on the backend.
- 🎨 **Pure Dart** — no native SDK wrappers. Smaller app size, fewer platform-specific bugs. Officially iOS + Android from day one; Flutter Web is best-effort through `v0.5.0` and officially supported from `v0.6.0`.
- 🔓 **Open source, MIT** — audit the client code before shipping to production.

## Packages

This is a monorepo. Packages will be published separately to pub.dev:

| Package | Purpose |
|---------|---------|
| [`chataptor`](./packages/chataptor) | Pure-Dart headless core — sockets, auth, streams, hooks. |
| [`chataptor_flutter`](./packages/chataptor_flutter) | Flutter widgets + singleton built on top of the core. |

Most integrators only need `chataptor_flutter` — it transitively re-exports the core. Use the core directly when you want full control over the chat interface (custom UI, headless integrations, server-side tests).

## Installation

> Coming with `v0.1.0`.

## License

[MIT](./LICENSE) © 2026 Chataptor

## Links

- Product: [chataptor.com](https://chataptor.com)
- Design spec: [`docs/specs/`](./docs/specs/)
- Implementation plan: [`docs/plans/`](./docs/plans/)
