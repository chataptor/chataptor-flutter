# Contributing to Chataptor Flutter SDK

Thanks for considering a contribution! This repo is open-source (MIT) and we welcome pull requests, issues, and discussion.

## Setup

```bash
git clone https://github.com/chataptor/chataptor-flutter.git
cd chataptor-flutter
dart pub global activate melos
dart pub get        # resolves the workspace
```

## Development workflow

```bash
melos run analyze       # static analysis across all packages
melos run format-check  # formatting check
melos run test          # run every package's tests
```

Every change should ship with a test. TDD is the recommended workflow — write the failing test first, then the minimal code to pass it.

## Commit conventions

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(chataptor): add ...` — new user-facing feature
- `fix(chataptor_flutter): ...` — bugfix
- `docs: ...` — documentation
- `chore: ...` — repo hygiene
- `test: ...` — test-only change
- `refactor: ...` — internal change with no behaviour impact

Do not include `Co-Authored-By` or "generated with" footers.

## CLA

Significant contributions require a signed Contributor License Agreement. The GitHub bot will prompt you on your first PR.

## Code of conduct

This project adheres to the [Code of Conduct](./CODE_OF_CONDUCT.md). By participating you agree to abide by it.
