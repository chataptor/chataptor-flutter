# Architecture — Chataptor Flutter SDK

This document records the 25 locked architectural decisions for the Chataptor Flutter SDK.
Before suggesting an alternative: if the decision is already here, don't re-litigate it
unless new information has emerged (upstream deprecation, new Dart feature, etc.).

## Decision table

| # | Area | Decision |
|---|------|----------|
| 1 | Packaging | Federated monorepo with two packages: `chataptor` (pure Dart) + `chataptor_flutter` (Flutter layer) |
| 2 | Persona | Customer-only. Agent persona = separate product (not in this repo). |
| 3 | License | MIT |
| 4 | Publishing | Pub.dev verified publisher `chataptor.com`, OIDC trusted publishing, no long-lived tokens |
| 5 | Source control | Public repo `github.com/chataptor/chataptor-flutter`. The Chataptor backend is a separate closed-source codebase out of scope for this SDK; the SDK speaks to it over the standard Phoenix Channels wire protocol. |
| 6 | Monorepo tooling | Melos 7.x + native Dart Pub Workspaces (complementary) |
| 7 | Dart SDK floor | `^3.9.0` |
| 8 | Flutter floor | `>=3.35.0` (first stable bundling Dart 3.9), tested pinned-floor + `stable` + `beta` in CI |
| 9 | Transport | `phoenix_socket` hidden behind `ChatTransport` port abstraction |
| 10 | State pattern | `ValueStream<T>` dual sync+stream (custom, no rxdart dep); `ValueListenable` adapter in Flutter layer |
| 11 | Error model | Sealed Result for recoverable errors, exceptions for programmer errors |
| 12 | Connection modes | Two: `lazy` (default), `foregroundActive` |
| 13 | Identification | Three modes (anonymous, identifiedUnverified, identifiedVerified) + mid-session `identify()` migration |
| 14 | Push notifications | Hook-in pattern (`PushConfig.disabled()` / `.hookIn()`), merchant configures Firebase |
| 15 | Translation | First-class top-level config (not in `FeatureToggles`) |
| 16 | E2E encryption | Not supported — incompatible with server-side translation, multi-agent, Translation Memory, PII masking, analytics. Industry pattern: no B2C support chat uses E2E. |
| 17 | Long list rendering | `super_sliver_list` + `RepaintBoundary` per bubble |
| 18 | JSON parsing isolates | Only for batch/history >10 KB; per-message parsing on main thread |
| 19 | Immutable models | Plain Dart 3 classes with manual `copyWith` (no Freezed — avoids build_runner on consumers) |
| 20 | Testing: mocking | Mocktail internally; ship `chataptor/testing.dart` sub-library with `FakeChataptorClient` + `FakeChatTransport` |
| 21 | Linting | `very_good_analysis` + `public_member_api_docs: true` |
| 22 | Accessibility | First-class, tests blocking from v0.5.0+ |
| 23 | Versioning | Semver pre-1.0 convention (minor bumps for breaking); `@experimental` annotation on unstable APIs |
| 24 | CHANGELOG | keep-a-changelog format, auto-generated from Conventional Commits by Melos |
| 25 | Core package direct deps | ≤4: `phoenix_socket`, `http`, `meta`, `async`. `web_socket_channel` is transitive via `phoenix_socket` and does **not** count against the budget. New direct deps need strong justification. |

## Toolchain compatibility

Record of which Flutter versions satisfy the Dart 3.9 floor. Verify before raising or lowering.

| Flutter | Bundled Dart | Supported here |
|---------|--------------|----------------|
| `3.35.x` | `3.9.x` | ✅ floor — CI pins `3.35.0` |
| `3.32.x` | `3.8.x` | ❌ — fails `dart pub get` on `^3.9.0` constraint |
| `3.29.x` | `3.7.x` | ❌ |
| `3.24.x` | `3.5.x` | ❌ |

If a future Flutter bundles Dart 3.10+, this table and decisions #7 and #8 must be revisited together — floor bumps are a breaking change for merchants pinning their Flutter SDK.
