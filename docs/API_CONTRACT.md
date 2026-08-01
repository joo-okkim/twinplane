# AI Teacher API Contract

This is the contract between the Flutter app and the Node.js/LLM backend.
It exists so both sides can build in parallel: the app already works end-to-end
against `MockAiTeacherRepository` (see `lib/services/mock/`), and
`HttpAiTeacherRepository` (`lib/services/http/http_ai_teacher_repository.dart`)
is a ready-to-use client for this exact contract — once the backend
implements these endpoints, switching the app over is a one-line flag change
(see "Switching the app to the real backend" below), no UI code changes.

**Keep this file and the two repository implementations in sync.** If a field
changes here, update the Dart models in `lib/models/` (and re-run
`dart run tool/dump_api_examples.dart` to refresh the examples below) in the
same change.

All request/response bodies are JSON. All example payloads in this document
were generated directly from the real Dart models, not hand-typed — see
`tool/dump_api_examples.dart`.

## Conventions

- Base URL: configurable, no fixed path prefix assumed beyond what's shown per endpoint.
- Dates: `YYYY-MM-DD` strings. Times: `HH:mm` 24h strings.
- Auth: every endpoint below except `POST /api/auth/login` requires
  `Authorization: Bearer <token>`. Missing/invalid/expired token → `401
  { "error": "..." }`. `HttpAiTeacherRepository` attaches this header on
  every request; there's no self-serve registration yet, only the 3 demo
  accounts created by the backend's `scripts/seed.js`.
- Errors: any non-2xx should return `{ "error": "message" }`; the Flutter
  client currently surfaces the raw status + body on failure (see
  `ApiException` in `http_ai_teacher_repository.dart`) — a structured error
  shape can be formalized once real failure cases are known.
- Enums are transmitted as the exact strings shown (e.g. `"FIXED_SCHEDULE"`,
  `"TIRED"`) — see each Dart enum's `wireValue` in `lib/models/` for the
  authoritative list.

## Endpoints

### `POST /api/auth/login`

Not authenticated (this is how a token is obtained). Every other endpoint
requires the returned token on `Authorization: Bearer <token>`.

**Request**

```json
{ "username": "jiyoon", "password": "5447" }
```

**Response** — `200`

```json
{ "token": "<jwt>", "studentId": 1, "name": "지윤" }
```

`401 { "error": "invalid credentials" }` on a bad username/password.

### `GET /api/student/profile`

Returns the authenticated student's profile (spec §11 `student`).

```json
{
  "studentId": 1001,
  "name": "지윤",
  "gradeLevel": "MIDDLE_2",
  "wakeUpTime": "07:00",
  "bedTime": "22:30",
  "preferredStudyStartTime": "16:30",
  "maxSelfStudyMinutes": 150,
  "maxConcentrationMinutes": 40,
  "condition": "normal",
  "conditionMemo": "학교 체육활동이 있었음"
}
```

`condition` is one of: `very_good`, `good`, `normal`, `tired`, `very_tired`, `stressed`, `sick`.

### `GET /api/student/subject-levels`

Spec §11 `subjectLevels[]`.

```json
[
  { "subject": "수학", "level": "normal", "recentAchievementRate": 68.0, "averageDelayMinutes": 15, "averageActualMinutes": 42, "recentIncompleteCount": 2 },
  { "subject": "영어", "level": "good", "recentAchievementRate": 85.0, "averageDelayMinutes": 5, "averageActualMinutes": 28, "recentIncompleteCount": 0 },
  { "subject": "과학", "level": "normal", "recentAchievementRate": 76.0, "averageDelayMinutes": 10, "averageActualMinutes": 30, "recentIncompleteCount": 1 }
]
```

### `GET /api/student/exams`

Spec §11 `exams[]`.

```json
[
  { "examName": "2학기 수학 단원평가", "subject": "수학", "examDate": "2026-08-05", "scope": "일차함수", "importance": "high" }
]
```

### `GET /api/student/performance`

Spec §11 `recentPerformance`.

```json
{
  "dailyAchievementRate7Days": 72.0,
  "weeklyAchievementRate": 75.0,
  "consecutiveCompletionDays": 2,
  "mostCompletedSubject": "영어",
  "leastCompletedSubject": "수학",
  "averageStartDelayMinutes": 12
}
```

### `GET /api/parent/settings`

Spec §11 `parentSettings`. Read-only to the student app (see spec §10 — the
student never edits these; the 마이 tab only displays them).

```json
{
  "planApprovalMode": "STUDENT_CONFIRM",
  "maxDailyStudyMinutes": 150,
  "allowPlanAutoAdjustment": true,
  "allowStudentTimeChange": true,
  "allowStudentQuantityChange": true,
  "requireParentApprovalForRequiredPlanDeletion": true
}
```

### `GET /api/policy/sticker`

Spec §11 `stickerPolicy` / §8.

```json
{
  "requiredPlanCompletion": 2,
  "recommendedPlanCompletion": 1,
  "onTimeBonus": 1,
  "dailyAchievement80Bonus": 3,
  "allRequiredCompletionBonus": 2
}
```

### `GET /api/policy/allowance`

Spec §11 `allowancePolicy` / §9.

```json
{
  "enabled": true,
  "period": "WEEKLY",
  "conditions": [
    { "achievementRate": 80.0, "amount": 5000 },
    { "achievementRate": 90.0, "amount": 10000 }
  ],
  "parentApprovalRequired": true
}
```

### `POST /api/plans/daily`

Generates (or regenerates) today's plan. Maps to spec §17's `CREATE_DAILY_PLAN`.

**Request**

```json
{
  "date": "2026-07-28",
  "condition": "tired"
}
```

`condition` is optional — omit it to let the backend use the student's
stored default condition. When present, it must drive the load-adjustment
rules in spec §6 (this is implemented today in
`lib/services/mock/plan_generation_logic.dart`'s `_conditionLoadMultiplier`
and `conditionForcesRequiredOnly` — use that as the reference behavior:
`tired`/`stressed` reduce load on top of the achievement-based tier;
`very_tired`/`sick` force a required-only day and set
`parentMessage.approvalRequired: true` plus a `warnings[]` entry for `sick`).

**Response** — full spec §12 shape. Every `dailyPlans[]` item needs a
stable `id` (used later by `/api/plans/modify`); everything else matches
spec §12/§13 exactly (ordering by `startTime`, `confirmedStickerReward`
always `0` here, hard-difficulty items ≤40% of the day unless condition
tightens that further, etc.):

```json
{
  "result": "success",
  "targetDate": "2026-07-28",
  "studentId": 1001,
  "planSummary": {
    "title": "오늘의 AI 학습 플랜",
    "totalStudyMinutes": 127,
    "requiredStudyMinutes": 80,
    "recommendedStudyMinutes": 47,
    "breakMinutes": 48,
    "planItemCount": 13,
    "requiredPlanCount": 7,
    "difficultyBalance": { "easy": 6, "normal": 6, "hard": 1 },
    "expectedAchievementRate": 78,
    "planConfidenceScore": 85
  },
  "dailyPlans": [
    {
      "id": "fixed-0",
      "sequence": 1,
      "planType": "fixed",
      "subject": null,
      "title": "학교",
      "description": "고정 일정이에요.",
      "startTime": "08:00",
      "endTime": "15:30",
      "durationMinutes": 450,
      "priority": "required",
      "difficulty": "normal",
      "required": true,
      "rewardEligible": false,
      "estimatedStickerReward": 0,
      "confirmedStickerReward": 0,
      "evidenceRequired": false,
      "sourceType": "FIXED_SCHEDULE",
      "sourceId": null,
      "adjustable": false,
      "adjustmentReason": null
    },
    {
      "id": "plan-2",
      "sequence": 3,
      "planType": "required",
      "subject": "수학",
      "title": "유형 문제집 42~45쪽",
      "description": "2학기 수학 단원평가 대비를 위해 일차함수 관련 내용을 학습해요.",
      "startTime": "17:00",
      "endTime": "17:25",
      "durationMinutes": 25,
      "priority": "high",
      "difficulty": "hard",
      "required": true,
      "rewardEligible": true,
      "estimatedStickerReward": 2,
      "confirmedStickerReward": 0,
      "evidenceRequired": true,
      "sourceType": "ASSIGNMENT",
      "sourceId": "501",
      "adjustable": true,
      "adjustmentReason": "수학 시험이 다가오고 있어 핵심 개념과 문제풀이 비중을 높였어요."
    }
  ],
  "generationReasons": [
    "최근 7일 달성률이 72%이어서 학습량을 10% 정도 줄여 부담을 낮췄어요.",
    "수학 시험이 다가오고 있어 핵심 개념과 문제풀이 비중을 높였어요.",
    "오늘 마감인 \"영어 단어 25개\" 과제를 우선 배치했어요.",
    "전날 컨디션을 반영해 이월된 학습은 분량을 줄여서 다시 배치했어요.",
    "어려운 과목이 너무 몰리지 않도록 일부 난이도를 조정했어요."
  ],
  "studentMessage": {
    "title": "오늘은 중요한 계획부터 차근차근 해봐요.",
    "message": "지난 학습 결과를 반영해 분량을 줄였어요. 수학부터 먼저 시작해서 중요한 계획을 하나씩 완료해봅시다.",
    "tone": "encouraging"
  },
  "parentMessage": {
    "summary": "최근 달성률과 수학 미완료 이력을 반영해 총 자기주도 학습시간을 127분으로 조정했습니다.",
    "attentionItems": ["전날 미완료 학습이 있어 분량을 줄여 재배치했습니다.", "수학 달성률이 최근 낮은 편입니다."],
    "approvalRequired": false
  },
  "rewardForecast": {
    "estimatedPlanStickerReward": 9,
    "dailyBonusStickerPossible": 5,
    "maximumEstimatedStickerReward": 14,
    "allowancePolicyExists": true,
    "allowancePeriod": "WEEKLY",
    "currentWeeklyAchievementRate": 75.0,
    "targetAchievementRate": 80.0,
    "expectedAllowance": 5000,
    "currency": "KRW",
    "parentApprovalRequired": true,
    "message": "이번 주 달성률이 80% 이상이면 5000원 용돈 지급 후보가 됩니다."
  },
  "carryOverDecisions": [
    {
      "sourcePlanItemId": "801",
      "decision": "REDUCE_AND_CARRY_OVER",
      "originalQuantity": "30분 분량",
      "adjustedQuantity": "15분 분량",
      "reason": "전날 컨디션을 반영해 이월된 학습은 분량을 줄여서 다시 배치했어요."
    }
  ],
  "warnings": [],
  "validation": {
    "fixedScheduleConflict": false,
    "exceedsMaximumStudyTime": false,
    "bedTimeConflict": false,
    "insufficientBreakTime": false,
    "excessiveHardTasks": false,
    "excessiveCarryOver": false,
    "valid": true
  }
}
```

*(Full example with all 13 plan items: run `dart run tool/dump_api_examples.dart` — trimmed here for length.)*

### `POST /api/plans/modify`

Spec §14. **Never blindly honor the request** — apply the priority ladder
(remove bonus → remove optional → shrink recommended → shrink required →
split → move to another day), and block required-item removal behind
`PARENT_APPROVAL_REQUIRED` when `parentSettings.requireParentApprovalForRequiredPlanDeletion`
is true. Reference implementation: `lib/services/mock/modification_logic.dart`.

**Request**

```json
{
  "planItemId": "plan-2",
  "reason": "TIRED",
  "freeText": null
}
```

`reason` is one of: `TIRED`, `TOO_MUCH`, `WRONG_TIME`, `DONT_WANT`.

**Response**

```json
{
  "modificationStatus": "APPLIED",
  "updatedItem": {
    "id": "plan-2",
    "sequence": 3,
    "planType": "required",
    "subject": "수학",
    "title": "유형 문제집 42~45쪽",
    "description": "2학기 수학 단원평가 대비를 위해 일차함수 관련 내용을 학습해요.",
    "startTime": "17:00",
    "endTime": "17:25",
    "durationMinutes": 25,
    "priority": "high",
    "difficulty": "normal",
    "required": true,
    "rewardEligible": true,
    "estimatedStickerReward": 2,
    "confirmedStickerReward": 0,
    "evidenceRequired": true,
    "sourceType": "ASSIGNMENT",
    "sourceId": "501",
    "adjustable": true,
    "adjustmentReason": "필수 계획은 삭제 대신 난이도를 낮춰서 조정했어요."
  },
  "message": "필수 계획은 삭제 대신 난이도를 낮춰서 조정했어요.",
  "reason": "필수 계획은 삭제 대신 난이도를 낮춰서 조정했어요."
}
```

`modificationStatus` is one of: `APPLIED` (`updatedItem` set), `REMOVED`
(`updatedItem` is `null` — the client deletes the item locally), or
`PARENT_APPROVAL_REQUIRED` (`updatedItem` is `null` — the client shows a
"부모님 확인이 필요해요" dialog with `message` and makes no change).

### `POST /api/reviews/daily`

Spec §15/§16. Never blames the student; completed items are listed first.
Reference implementation: `lib/services/mock/review_logic.dart`.

**Request**

```json
{
  "date": "2026-07-28",
  "completions": [
    { "planItemId": "plan-2", "completed": true, "actualMinutes": 25 },
    { "planItemId": "plan-3", "completed": true, "actualMinutes": 30 }
  ]
}
```

Only `rewardEligible` plan items (i.e. not `fixed`/`break`) are submitted.

**Response**

```json
{
  "result": "success",
  "studentId": 1001,
  "reviewDate": "2026-07-28",
  "achievement": {
    "totalPlanCount": 6,
    "completedPlanCount": 6,
    "overallAchievementRate": 100,
    "requiredAchievementRate": 100,
    "onTimeCompletionRate": 100,
    "totalPlannedMinutes": 127,
    "totalActualMinutes": 127
  },
  "subjectResults": [
    { "subject": "수학", "plannedMinutes": 60, "actualMinutes": 60, "achievementRate": 100, "analysis": "계획한 시간 내에 완료했습니다." }
  ],
  "completedWell": ["오늘 필수 계획을 완료했어요.", "\"유형 문제집 42~45쪽\"을(를) 완료했어요."],
  "improvementPoints": [],
  "studentMessage": "오늘 필수 계획을 완료했어요. 오늘 정말 잘 해냈어요. 이 흐름 그대로 내일도 이어가봐요!",
  "parentMessage": "전체 달성률은 100%, 필수 계획 달성률은 100%입니다. 계획한 시간 내에 완료했습니다.",
  "rewardResult": {
    "earnedStickerCount": 15,
    "dailyBonusApplied": true,
    "weeklyAchievementRate": 79.0,
    "allowanceCandidate": false,
    "expectedAllowance": null,
    "currency": "KRW",
    "parentApprovalRequired": true
  }
}
```

`rewardResult.parentApprovalRequired` must always be `true` — the AI never
confirms an allowance payout itself (spec §9).

### `POST /api/assessments/generate`

이해도 확인 (comprehension check). Offered once a `rewardEligible`,
`evidenceRequired` plan item is marked complete (see `plan_item_tile.dart`'s
teal 이해도 확인 pill). The request deliberately carries only the plan item
id — the backend resolves subject/scope itself (see
`AssessmentGenerateRequest`'s doc comment) so a client can't request a quiz
for scope it doesn't own, and generates the questions with Claude from that
scope. `MockAiTeacherRepository` returns 5 canned questions per subject
instead of calling a real LLM, so `USE_MOCK=true` stays deterministic for
dev/tests — the real backend does not need to match the mock's specific
question wording, only this JSON shape.

**Request**

```json
{
  "planItemId": "plan-2"
}
```

**Response** — `200`. `correctAnswer`/`explanation` are withheld until
submission — see `POST /api/assessments/{id}/submit` below.

```json
{
  "assessmentId": 1,
  "subject": "수학",
  "scope": "2학기 수학 단원평가 대비를 위해 일차함수 관련 내용을 학습해요.",
  "questions": [
    {
      "id": 101,
      "sequence": 1,
      "type": "multiple_choice",
      "question": "수학 학습 범위(2학기 수학 단원평가 대비를 위해 일차함수 관련 내용을 학습해요.)와 가장 관련 있는 활동은 무엇일까요?",
      "choices": [
        "오늘 배운 내용 복습하기",
        "관련 없는 영상 시청하기",
        "다른 과목 숙제하기",
        "아무것도 하지 않기"
      ]
    },
    {
      "id": 103,
      "sequence": 3,
      "type": "short_answer",
      "question": "오늘 \"2학기 수학 단원평가 대비를 위해 일차함수 관련 내용을 학습해요.\" 범위에서 배운 내용을 한 문장으로 설명해보세요.",
      "choices": []
    }
  ]
}
```

`type` is one of: `multiple_choice`, `short_answer`. `choices` is empty for
`short_answer` questions.

*(Full 5-question example: run `dart run tool/dump_api_examples.dart`.)*

### `POST /api/assessments/{id}/submit`

`{id}` is the `assessmentId` from the generate response above. Grades the
student's answers — for `short_answer`, this requires real LLM judgment
(the mock always marks short answers correct, which the real backend must
not do). Reference implementation for the response shape:
`lib/services/mock/mock_ai_teacher_repository.dart`'s `submitAssessment`.

**Request**

```json
{
  "answers": [
    { "questionId": 101, "answer": "오늘 배운 내용 복습하기" },
    { "questionId": 103, "answer": "일차함수는 기울기와 절편으로 그래프를 그릴 수 있어요." }
  ]
}
```

**Response** — `200`

```json
{
  "assessmentId": 1,
  "score": 100,
  "totalQuestions": 5,
  "results": [
    {
      "id": 101,
      "sequence": 1,
      "type": "multiple_choice",
      "question": "수학 학습 범위(2학기 수학 단원평가 대비를 위해 일차함수 관련 내용을 학습해요.)와 가장 관련 있는 활동은 무엇일까요?",
      "choices": [
        "오늘 배운 내용 복습하기",
        "관련 없는 영상 시청하기",
        "다른 과목 숙제하기",
        "아무것도 하지 않기"
      ],
      "studentAnswer": "오늘 배운 내용 복습하기",
      "isCorrect": true,
      "correctAnswer": "오늘 배운 내용 복습하기",
      "explanation": "학습한 범위를 스스로 복습하는 것이 이해도를 높이는 가장 좋은 방법이에요.",
      "feedback": "정답이에요!"
    }
  ]
}
```

`score` is out of 100 (percentage), not a raw correct-answer count.

*(Full 5-result example: run `dart run tool/dump_api_examples.dart`.)*

## Switching the app to the real backend

No UI or provider code needs to change — only how `main.dart` picks a
repository:

```
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://your-api.example.com
```

`lib/config/app_config.dart` reads these two `--dart-define` values;
`lib/main.dart` then constructs `HttpAiTeacherRepository` instead of
`MockAiTeacherRepository` and calls `initialize()` once at startup (which
fetches the 6 GET endpoints above and caches them for the session — see
`HttpAiTeacherRepository.initialize()`). If the server is unreachable at
startup, the app shows a "서버에 연결하지 못했어요" screen instead of crashing.

## Regenerating the examples in this file

```
dart run tool/dump_api_examples.dart
```

This runs the real mock repository and prints every request/response above
so they always reflect the actual Dart model shapes — copy fresh output in
here whenever a model changes.
