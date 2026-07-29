# Development Progress

Status tracker for the Flutter app and its handoff to the Node/LLM backend.
Update this file whenever a milestone lands so both sides know what's real,
what's mocked, and what's blocked.

## How the two sides work in parallel

- The Flutter app is fully functional today against `MockAiTeacherRepository`
  (`lib/services/mock/`) — a rule-based stand-in for the real AI, built
  directly from the AI Teacher spec's decision rules (load tiers, condition
  adjustment, modification priority ladder, no-blame review phrasing).
- Every screen talks only to the `AiTeacherRepository` interface
  (`lib/services/ai_teacher_repository.dart`), never to the mock directly.
- **[docs/API_CONTRACT.md](./API_CONTRACT.md)** is the single source of
  truth for what the backend must implement — every endpoint, JSON shape,
  and example there is generated from the real Dart models
  (`tool/dump_api_examples.dart`), not hand-typed, so it can't silently drift.
- `HttpAiTeacherRepository` (`lib/services/http/`) already implements that
  contract as a real HTTP client. Once the backend serves those endpoints,
  flip one flag (see API_CONTRACT.md's "Switching the app to the real
  backend") — no screen or provider code changes.

## Flutter app — implemented

| Area | Status | Notes |
|---|---|---|
| Data models (`lib/models/`) | Done | Mirror spec JSON fields 1:1, hand-written `toJson`/`fromJson` on every model (including response types, added when the HTTP client needed them) |
| Mock plan generation | Done | Achievement-rate load tiers, exam/deadline prioritization, hard-difficulty cap, carry-over reduction |
| Condition-aware generation | Done | tired/stressed extra reduction, very_tired/sick forced required-only + parent-approval flag (spec §6 — previously unimplemented, wired up this session) |
| Modification priority ladder | Done | Bonus→optional→shrink recommended→shrink required→split; required-item deletion gated by parent policy |
| Daily review scoring | Done | Achievement stats, subject breakdown, no-blame messaging, sticker/allowance calc |
| 홈 (Home) tab | Done | AI hero card, condition check-in, progress dashboard, NOW card, mini timeline, insight cards |
| 학습 (Plan) tab | Done | Full timeline, modification request sheet, finish-day flow |
| 보상 (Reward) tab | Done | Sticker tally, allowance ladder, policy transparency panel |
| 마이 (My) tab | Done | Read-only student profile + parent settings |
| AI 코치 quick actions | Done | Bottom-sheet wired to real modification/regenerate/reasons calls (not a chat backend) |
| HTTP client scaffold | Done | `HttpAiTeacherRepository`, `AppConfig`, startup error screen — verified end-to-end against the deployed backend |
| Login / auth gate | Done | `LoginScreen` + `AuthGate` (`lib/screens/`); token persisted via `shared_preferences`; mock mode bypasses login entirely |

## Backend status (as of the DB + auth migration)

- Real Postgres persistence + username/password login are live on the
  deployed backend (`twinplane-backend`, see its README/`db/schema.sql`).
  `MockAiTeacherRepository` is unaffected (`USE_MOCK=true`, the default,
  still skips login entirely).
- 3 demo accounts seeded via the backend's `scripts/seed.js`: `jiyoon`
  (지윤, the original mock student), `jiho` (김지호), `jia` (김지아) — all
  password `5447`. No self-serve registration yet.
- `AuthGate`/`LoginScreen` (`lib/screens/`) gate the real-HTTP path; mock
  mode is unaffected.

## Explicitly out of scope so far

- **Self-serve registration** — new accounts are created via the backend's
  `scripts/seed.js` only, no sign-up screen/endpoint.
- **AI-generated/graded assessments** — registering a homework/exam
  "scope" and having the AI generate + grade practice problems for it was
  discussed and deferred; `assignments`/`exams` already reserve a `scope`
  column for it.
- **AI chat** — the "AI 코치" floating button opens a fixed quick-action
  sheet, not a freeform LLM chat.
- **OCR homework capture** — not built.
- **Dark mode** — not built.
- **Parent-facing screens** — parent settings are shown read-only in the
  마이 tab; there's no separate parent app/portal.

## For the backend team

1. Read `docs/API_CONTRACT.md` — it has every endpoint, exact JSON shapes,
   and the specific rule files to mirror behavior from
   (`plan_generation_logic.dart`, `modification_logic.dart`, `review_logic.dart`).
2. `tool/dump_api_examples.dart` regenerates all example payloads — run it
   after any model change to keep the contract doc accurate.
3. Once your endpoints are live, hand the frontend team a base URL; no
   Flutter code changes are needed beyond the `--dart-define` flags.
4. Flag any place the real AI's behavior should diverge from the mock's
   rule-based logic (e.g. actual LLM reasoning vs. our fixed heuristics) —
   the JSON *shape* is the contract, not the specific wording/values the
   mock currently produces.
