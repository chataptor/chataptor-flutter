# CLAUDE.md — Chataptor Flutter SDK

Guide for Claude Code and any engineer working in this repository. Read this before touching code.

## Project

Official Flutter SDK for [Chataptor](https://chataptor.com) — real-time multilingual customer support chat. Two packages published to pub.dev:

- **`chataptor`** — pure-Dart headless core client. Phoenix Channels transport behind a port abstraction, custom `ValueStream<T>` state exposure, sealed Dart 3 Result/Error types. Zero Flutter dependency.
- **`chataptor_flutter`** — Flutter layer on top of the core. Singleton, `ChataptorScope`, widgets, theme, localizations, lifecycle observer.

MIT license. Verified publisher target: `chataptor.com`.

## Tech stack

- **Dart SDK:** `^3.9.0` (sealed classes, pattern matching, records required — the Dart 3 features we rely on are available from Dart 3.0, but we pin 3.9 to unlock `super_sliver_list` perf work and keep the toolchain aligned with the floor Flutter that bundles Dart 3.9).
- **Flutter:** `>=3.35.0` (floor version). Flutter 3.35 is the first stable that ships Dart 3.9; older Flutter versions will fail `dart pub get` on the `^3.9.0` SDK constraint. CI matrix: `3.35.0` (pinned floor) / `stable` / `beta`.
- **Compatibility matrix** (verify before raising/lowering):

  | Flutter | Bundled Dart | Supported here |
  |---------|--------------|----------------|
  | `3.35.x` | `3.9.x` | ✅ floor |
  | `3.32.x` | `3.8.x` | ❌ blocked by Dart 3.9 floor |
  | `3.29.x` | `3.7.x` | ❌ |
  | `3.24.x` | `3.5.x` | ❌ |

- **Monorepo:** Melos 7 + native Pub Workspaces. Melos config lives inside root `pubspec.yaml` under a `melos:` key — **no separate `melos.yaml`** (that was pre-Melos-7).
- **Transport:** `phoenix_socket` hidden behind a `ChatTransport` port abstraction — concrete package types never leak to public API, swappable when community package drifts.
- **Linting:** `very_good_analysis` + `public_member_api_docs: true` (100% dartdoc on public API enforced).
- **Testing:** `package:test` for pure-Dart, `flutter_test` for UI, `mocktail` for internal mocks. Merchants get `package:chataptor/testing.dart` sub-library with `FakeChataptorClient` (merchant-facing, high-level) and `FakeChatTransport` (transport-level, for SDK development) — no Mockito required on either side.
- **NOT used (explicit YAGNI):** Freezed (forces `build_runner` on consumers), rxdart (custom `ValueStream<T>` is ~50 lines).

## Repository layout

```
chataptor-flutter/
├── packages/
│   ├── chataptor/              # pure-Dart core
│   │   ├── lib/
│   │   │   ├── chataptor.dart  # public API barrel
│   │   │   ├── testing.dart    # FakeChataptorClient, FakeChatTransport
│   │   │   └── src/            # {auth, client, config, errors, hooks,
│   │   │                       #  http, logger, models, storage, streams,
│   │   │                       #  transport, translation}
│   │   └── test/
│   └── chataptor_flutter/      # Flutter layer
│       ├── lib/
│       │   ├── chataptor_flutter.dart  # barrel (re-exports core)
│       │   └── src/            # {adapters, chataptor.dart, lifecycle,
│       │                       #  l10n, scope, theme, widgets}
│       └── test/
├── examples/
│   └── quickstart/             # minimal runnable demo
├── docs/
│   └── guides/                 # user-facing guides (getting-started, etc.)
├── .github/workflows/          # CI: ci.yml, examples-build.yml
├── pubspec.yaml                # workspace root + Melos config
├── analysis_options.yaml       # shared lints
├── ARCHITECTURE.md             # 25 locked architectural decisions
├── CLAUDE.md                   # this file
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md                # top-level aggregate
├── README.md
└── LICENSE                     # MIT
```

## Commands

From repo root:

```bash
# Single resolve for the whole workspace (Pub Workspaces feature).
dart pub get

# Quality gates (use these before committing).
melos run analyze        # dart analyze --fatal-infos on every package
melos run format-check   # dart format --set-exit-if-changed .
melos run format         # dart format . (fix mode)
melos run test           # flutter test in packages that have test/
melos run pana           # pana score check (target ≥140/160 per package)
```

Per-package:

```bash
cd packages/chataptor
flutter test                                      # all tests
flutter test test/path/to/single_test.dart        # one file
flutter test --name "specific test name"          # one test by name
dart analyze --fatal-infos                        # lint check
```

## Conventions

### Commits

Conventional Commits with package scope where applicable:

- `feat(chataptor): add ...` — new user-facing feature in core package
- `feat(chataptor_flutter): add ...` — new feature in Flutter package
- `fix(chataptor): resolve ...` — bugfix
- `chore: ...` — repo hygiene (CI, config, deps)
- `docs: ...` — documentation
- `test: ...` — test-only change (rare — usually grouped with feat/fix)
- `refactor(chataptor): ...` — internal restructuring with no behaviour change

**Rules:**
- Subject line ≤ 72 chars.
- Use HEREDOC for multi-line commit messages.
- **No** `Co-Authored-By: Claude <...>` footer.
- **No** "Generated with Claude Code" footer.

### Branches

- Trunk-based — PRs target `main`, short-lived branches (`feature/…`, `fix/…`).
- `main` has branch protection: CI + pana required before merge.
- **Never** push to `main` directly. **Never** force-push `main`.

### TDD workflow

Follow this rhythm — do not skip steps:

1. Write failing test.
2. `flutter test <path>` — verify it fails with the expected error message.
3. Write minimal implementation.
4. `flutter test <path>` — verify it passes.
5. `git commit` (test + implementation together as one commit).

No exceptions for "trivial" code.

### Dartdoc

**100% public API coverage.** The `public_member_api_docs` lint is `true` — it will fail the build if any exported symbol lacks a doc comment.

Write doc comments that explain **why** the type exists and when to use it, not just what it does. Function `fetchMessages()` — the reader can see it fetches messages from the name; tell them about pagination, error modes, and the performance shape.

## Key tech decisions — TL;DR

Locked architectural decisions. Do **not** re-litigate without new evidence. Full table in [`ARCHITECTURE.md`](./ARCHITECTURE.md).

1. **Two-package federated monorepo** — `chataptor` (pure-Dart) + `chataptor_flutter` (widgets).
2. **Customer-only persona.** Agent app is a separate product in a separate repo.
3. **No end-to-end encryption.** Fundamentally incompatible with server-side translation, multi-agent assignment, Translation Memory, PII masking, analytics. Industry pattern — no B2C support chat uses E2E.
4. **Phoenix transport via a port.** `phoenix_socket` types never leak into public API; the package can be forked or replaced without breaking consumers.
5. **`ValueStream<T>` custom, no rxdart.** Dual sync + stream access in ~50 lines with zero dependencies.
6. **Sealed Result + exceptions split.** Sealed `SendResult` / `ChataptorError` for recoverable async flows; `ChataptorStateError` / `ChataptorConfigurationError` (subclasses of `StateError` / `ArgumentError`) for programmer errors.
7. **Two connection modes only:** `lazy` (default — connect on chat open, disconnect on close) and `foregroundActive` (connect while app is in foreground). `eager` and `pushOnly` were cut as unrealistic on mobile (iOS kills background sockets within seconds).
8. **Translation is first-class top-level config** — exposed at the root of `ChataptorConfig`, not buried in `FeatureToggles`. It is the product differentiator.
9. **Hand-written immutable classes.** No Freezed — avoids forcing `build_runner` on every merchant's project.
10. **Testing sub-library in-package.** `package:chataptor/testing.dart` exports `FakeChataptorClient` and `FakeChatTransport`. Merchants skip Mockito setup entirely.
11. **EN + PL locales for v0.1.0.** Ten more locales (`de`, `es`, `fr`, `it`, `uk`, `cs`, `pt`, `ja`, `zh`, `ar`) arrive in v0.5.0.
12. **A11y `Semantics` labels from v0.1.0.** Blocking a11y tests in CI from v0.5.0.
13. **Platforms:** iOS + Android officially from v0.1.0; Flutter Web best-effort through v0.5.0, officially from v0.6.0; Desktop works as pure-Dart side effect, never promoted.
14. **MIT license. Verified publisher `chataptor.com`. OIDC-based trusted publishing** — no long-lived tokens in CI secrets.
15. **Core package direct dependencies capped at 4:** `async`, `http`, `meta`, `phoenix_socket`. `web_socket_channel` enters transitively via `phoenix_socket` — it does **not** count against the direct-dep budget. New direct deps need strong justification.

## Technical notes

### Connection lifecycle

`ConnectionMode.lazy` is the default and means *exactly* "connect when chat UI mounts, disconnect when it unmounts". Widgets that open the socket must also close it — `ChataptorChatScreen.dispose()` is responsible for calling `client.disconnect()` when the configured mode is `lazy`. The lifecycle observer (`ChataptorLifecycleObserver`) only drives connect/disconnect in `foregroundActive` mode; it is a no-op for `lazy`. Any new container widget (e.g. `ChataptorChatSheet`) must own the same `lazy`-disconnect contract.

### Widget tests

- Always call `TestWidgetsFlutterBinding.ensureInitialized()` at the top of `main()`.
- For tests touching `SharedPreferences`, call `SharedPreferences.setMockInitialValues({})` in `setUp`.
- Use `tester.pump(Duration(...))` rather than `pumpAndSettle` when async streams are involved — `pumpAndSettle` can deadlock on broadcast streams.

### Constraints

- ❌ Add dependencies to `packages/chataptor/pubspec.yaml` beyond the agreed 4. Each new dep needs a compelling justification against [`ARCHITECTURE.md`](./ARCHITECTURE.md) decision #25.
- ❌ Introduce `package:flutter/*` imports into `packages/chataptor/lib/`. Core is pure Dart.
- ❌ Skip the failing-test step in TDD.
- ❌ Push to `main`. Always PR.
- ❌ Force-push any branch someone else might have fetched.
- ❌ Re-open decisions from `ARCHITECTURE.md` without new information.
- ❌ Reference the private backend repo or agent mobile app repo by name in public artifacts (commits, PR descriptions, public docs). Both remain unnamed in this open-source project.

## Language

User-facing responses and conversation: **Polish**, preserving all diacritics (`ą ć ę ł ń ó ś ź ż`). Never substitute ASCII for accented characters.

Code, identifiers, commit messages, dartdoc, pub.dev descriptions, READMEs, guides: **English** (for pub.dev reach and international contributor accessibility).

## Related repos (not linked here on purpose)

- **Chataptor backend** — private Elixir/Phoenix repo, stays closed-source.
- **Chataptor agent mobile app** — separate private Flutter app for agents (not customers). Not in scope of this SDK.

## Last updated

2026-05-07 — repo cleanup: removed AI planning artifacts, extracted architecture decisions to `ARCHITECTURE.md`.
