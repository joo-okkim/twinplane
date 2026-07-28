# twinplane

AI Teacher — a Flutter app that generates and adapts a student's daily study
plan, tracks completion, and turns achievement into stickers/allowance
rewards. Every screen talks to an `AiTeacherRepository` interface, currently
backed by an in-app rule-based mock so the frontend is fully usable before
the real Node/LLM backend exists.

## Features

- **홈 (Home)** — AI hero card, daily condition check-in, progress dashboard,
  "NOW" card, mini timeline, insight cards.
- **학습 (Plan)** — full daily timeline, modification request sheet
  (bonus → optional → shrink recommended → shrink required → split), finish-day flow.
- **보상 (Reward)** — sticker tally, allowance ladder, policy transparency panel.
- **마이 (My)** — read-only student profile and parent settings.
- **AI 코치** — quick-action bottom sheet wired to real modification/
  regenerate/reasons calls (not a freeform chat).

Plan generation accounts for achievement-rate load tiers, exam/deadline
prioritization, a hard-difficulty cap, carry-over reduction, and same-day
condition (tired/stressed/sick) adjustments.

## Getting started

```bash
flutter pub get
flutter run
```

By default the app runs entirely against `MockAiTeacherRepository`
(`lib/services/mock/`) — no backend required.

To point it at a real backend instead:

```bash
flutter run --dart-define=USE_MOCK=false \
  --dart-define=API_BASE_URL=https://api.example.com
```

## Project structure

```
lib/
  models/      Data models mirroring the API contract 1:1
  services/    AiTeacherRepository interface + mock and HTTP implementations
  providers/   State management (Provider)
  screens/     Home, Plan, Reward, My, Daily Review
  widgets/     Shared UI components
  theme/       App colors/theme
docs/
  API_CONTRACT.md   Source of truth for backend endpoints and JSON shapes
  PROGRESS.md       Status tracker for frontend/backend handoff
tool/
  dump_api_examples.dart   Regenerates API_CONTRACT.md examples from the models
```

## Backend integration

See [docs/API_CONTRACT.md](./docs/API_CONTRACT.md) for the full endpoint
contract and [docs/PROGRESS.md](./docs/PROGRESS.md) for current status and
what's still mocked vs. real. `HttpAiTeacherRepository`
(`lib/services/http/`) already implements the contract against a real HTTP
client — flipping `USE_MOCK=false` requires no screen or provider changes.

## Status

Frontend is feature-complete against the mock backend. Not yet built: auth,
cross-day persistence, AI chat, OCR homework capture, dark mode, and a
parent-facing app.