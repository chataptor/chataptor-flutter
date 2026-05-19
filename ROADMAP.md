# Roadmap — Chataptor Flutter SDK

Forward-looking plan. Versions before `1.0.0` follow the pre-1.0 semver
convention: minor bumps may include breaking changes (see
[`ARCHITECTURE.md`](./ARCHITECTURE.md) decision #23).

## How to read this file

- ✅ done in a tagged release
- 🟡 in scope for the named release
- ⬜ deferred — listed so it doesn't get lost

For locked architectural decisions (transport choice, license, dependency
budget, …) see [`ARCHITECTURE.md`](./ARCHITECTURE.md). This file is about
**product feature evolution**, not architecture.

## Feature parity with the production web widget

The production Chataptor web widget (embedded on chataptor.com customer
sites today) consumes a set of backend signals on the `site:X` channel
join and through subsequent broadcasts. The Flutter SDK is closing the
remaining gap version by version.

| Signal | Web widget | Flutter SDK |
|---|---|---|
| `welcome_message` (per-language) | ✅ first agent bubble | ✅ v0.1.0 |
| `header_title` (per-language) | ✅ header label | ✅ v0.1.0 |
| `agent:available` event (id, name, avatar_url, initials, color; up to 5) | ✅ avatar stack | ✅ v0.1.0 |
| `agents:offline` event | ✅ offline state | ✅ v0.1.0 |
| `offline_mode` + `offline_message` | ✅ "We're closed" UX | 🟡 v0.2.0 |
| `working_hours_enabled` + `next_available` | ✅ "Back Monday 09:00" | 🟡 v0.2.0 |
| `typing_preview_enabled` | likely ✅ | 🟡 v0.3.0 |
| Attachments (file upload, image preview) | ✅ paperclip button | 🟡 v0.4.0 (models exist) |
| Emoji picker | ✅ | 🟡 v0.4.0 |
| `widget_open_on` (`hover`/`click`) | ✅ launcher behaviour | n/a (mobile uses navigation) |

## v0.1.0 — Initial public release

First pub.dev release. Anonymous customer chat, drop-in widget,
real-time multilingual support.

✅ Shipped:
- `ChataptorClient` with anonymous identity, Phoenix Channels transport
- `ChataptorChatScreen` drop-in widget (title, theme, `showPoweredBy`)
- `ChataptorChatHeader` — avatar stack of online agents, team name from
  `SiteConfig.activeHeaderTitle`, live Online/Offline status indicator
- `welcome_message` rendered as the first agent bubble (client-side
  injection when conversation history is empty)
- Subscription to `agent:available` / `agents:offline` events;
  `onlineAgentsStream` + `currentOnlineAgents` exposed on the client
- `SiteConfig` model parsed from the site channel join payload;
  `siteConfigStream` + `currentSiteConfig` exposed on the client
- Headless demo in `examples/quickstart` consuming `siteConfigStream`
  and `onlineAgentsStream` for fully custom UIs
- `ChataptorTheme.light()` and `.matching(context)`
- EN + PL localizations
- Translation config (auto, per-customer language)
- Send guard, skeleton loader, anti-flash empty state
- Quickstart example app (default / matched / branded / headless demos)

## v0.2.0 — Identified customers + offline awareness

⬜ **Identified customers:** `CustomerIdentity.identifiedVerified` with HMAC verification hash; merchant-side recipe in docs.
⬜ **`sessionIdleTimeout`** config — auto-clearSession after N hours of inactivity.
⬜ **Offline mode + business hours UX:** consume `offline_mode` + `next_available` → block composer + show "We're back Monday 09:00 (UTC)" message in header. Honour `manual_offline` / `manual_online` overrides.
⬜ **`showAppBar: bool`** for sheet/dialog hosts that don't want their own AppBar.
⬜ **Server-controlled `showPoweredBy`** — backend flag overrides client white-label opt-out for plan tiers that require attribution.
⬜ **`ChataptorScope` documentation hardening** — clearer multi-instance examples.

## v0.3.0 — Push + typing indicators

⬜ **Push notifications:** `PushConfig.hookIn()` recipe with Firebase Messaging integration guide.
⬜ **Typing indicators** (both directions): consume `typing_preview_enabled`; surface agent typing in `ChataptorChatScreen`; emit customer-typing events from composer.
⬜ **Background reconnect resilience** under iOS aggressive socket teardown.

## v0.4.0 — Rich content

⬜ **Attachments UI:** paperclip button in composer, image thumbnails in bubbles, document fallback. Backend already supports — only client work.
⬜ **Emoji picker** in composer.
⬜ **Quick replies** rendering for bot-driven `MessageType.quickReplies`.
⬜ **Carousel cards** rendering for `MessageType.carousel`.

## v0.5.0 — i18n + a11y expansion

⬜ **10 additional locales:** `de`, `es`, `fr`, `it`, `uk`, `cs`, `pt`, `ja`, `zh`, `ar` (last one drives RTL support).
⬜ **A11y tests blocking in CI** (semantics labels enforced).
⬜ **Dark mode preset:** `ChataptorTheme.dark()` factory.
⬜ **`ChataptorChatBubble`** — floating launcher widget for hosts that don't want navigation-based mounting.
⬜ **`ChataptorChatSheet`** — bottom-sheet container variant.

## v0.6.0 — Flutter Web official

⬜ **Web officially supported** (best-effort through v0.5.0). Includes WebSocket fallback handling, browser tab visibility integration, and pana score parity with mobile.

## v1.0.0 — API stabilization

⬜ Lock public API surface; switch to strict semver.
⬜ Remove all `@experimental` annotations or graduate them.
⬜ Final dependency audit against direct-dep budget (`ARCHITECTURE.md` #25).

## Cut from scope (no current plan)

These items appeared in early discussions and were intentionally rejected.
Listed so they don't keep resurfacing:

- ❌ **Pre-chat forms / intake surveys / department routing** — backend doesn't model these. Adding to SDK = building a drawer feature. Chataptor's positioning ("real humans + AI translation layer", not "Intercom-style routed bot funnels") makes these out of character.
- ❌ **AI-generated suggested replies on welcome** — would conflict with the "you're talking to a human" promise. Quick replies are only surfaced when backend explicitly sends `MessageType.quickReplies` from a bot node.
- ❌ **End-to-end encryption** — fundamentally incompatible with server-side translation; locked in `ARCHITECTURE.md` #16.
- ❌ **`eager` / `pushOnly` connection modes** — unrealistic on mobile (iOS kills background sockets within seconds); cut in favour of `lazy` + `foregroundActive`.

## Sources

Roadmap items above are grounded in observed behaviour of the production
Chataptor web widget and the backend signals it consumes. The backend
itself is closed-source; this SDK targets the same wire protocol so
mobile experience parity tracks the web one.
