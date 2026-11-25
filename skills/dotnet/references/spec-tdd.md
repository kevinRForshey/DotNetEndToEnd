# Spec → Tasks → Tests → Implementation (TDD)

Use for features and cross-cutting changes. For a one-method fix, skip the spec: write one failing regression test, make it pass, done.

| Phase | Output | Gate |
|---|---|---|
| 1. Spec | `spec.md` with numbered ACs (`AC1`, `AC2`, ...) | User approves |
| 2. Tasks | `tasks.md`, cohesive vertical slices tied to ACs + tests | User approves (bundle with spec for small/medium features) |
| 3. Red | Acceptance tests compile and fail for the right reason | Shown failing |
| 4. Green | Implement slice by slice until all feature tests pass | Full affected test projects pass |

## File location
1. Reuse existing convention if present (from `detect-env.sh` `specs:` line, e.g. `.specify/`, `specs/NNN-name/`, `docs/specs/`).
2. Otherwise create `specs/<NNN>-<kebab-name>/spec.md` and `tasks.md` at repo root (`NNN` = next free number).

## 1. Spec (≤1 page)
Clarify first (`SKILL.md` §1), then write `spec.md`:
```markdown
# <Feature name>
Status: Draft | Approved | Done

## Problem
<2–4 lines: who needs what and why>

## Scope
In: <bullets>   Out: <bullets>

## Acceptance criteria
- AC1: Given <state>, when <action>, then <observable result>.
- AC2: Given ..., when <invalid input>, then <error: status / exception / message>.
<Every AC must be automated-testable; errors and edge cases get their own ACs.>

## Contracts
<Endpoints, DTOs, public interfaces/signatures, schema changes — signatures only, no bodies. Mark breaking changes.>

## Constraints
<Auth, perf, concurrency, PII, TFM. Omit if none.>

## Open questions
<Empty before approval.>
```
Summarize in a few lines (AC list + contract changes), link the file, and wait for approval. Apply feedback to `spec.md`, never only in chat.

## 2. Tasks (3–6 cohesive vertical slices)
Write `tasks.md` beside `spec.md`. Keep slices cohesive (don't split into 8+ micro-tasks that each trigger separate build/test cycles; split only if a slice exceeds ~5 files):
```markdown
# Tasks: <Feature name>
- [ ] T1 Contracts + stubs (`throw new NotImplementedException()`) & acceptance tests AC1–AC5 (red). Files: <paths>
- [ ] T2 AC1, AC2: <vertical slice>. Files: <paths>. Tests: AC1_*, AC2_*
- [ ] T3 AC3–AC5: <vertical slice>. Depends: T2. Tests: AC3_*..AC5_*
- [ ] T4 Cross-cutting (DI, migration, docs) + final verification.
```
Every AC appears in ≥1 task; every implementation task names its tests. Wait for approval (or bundle with spec approval).

> **Context-reset handoff (saves 50–70% quota on medium/large features):** Once `spec.md` and `tasks.md` are approved on disk, suggest running `/clear` (and switching to Sonnet if currently on Opus) before starting phase 3 so the high-turn coding loop begins from a clean ~5k context instead of carrying exploration history.

## 3. Red step (tests compile and fail for the right reason)
- One test class per feature (`<Feature>AcceptanceTests`) in the matching test project (unit by default; integration only for HTTP/DB/UI ACs).
- **Name every test after its AC:** `AC3_RejectsExpiredToken`, `AC3_ReturnsProblemDetails`.
  - VSTest: `--filter "FullyQualifiedName~AC3_"` (or `~<Feature>AcceptanceTests`)
  - MTP: `--filter-method '*AC3_*'` or `--filter-class '*<Feature>AcceptanceTests'`
- Good tests: arrange/act/assert on observable behavior (return value, HTTP status/body, persisted state), not private collaborator calls. Mock only slow/external seams (clock → 5-line inline `TimeProvider` subclass, or `FakeTimeProvider` only if `Microsoft.Extensions.TimeProvider.Testing` is already referenced; HTTP → `HttpMessageHandler` stub). Match repo test framework/assertions.
- Add T1 stubs (`throw new NotImplementedException();` or Razor stubs with `[Parameter]`s only) so tests compile without compile noise.
- Build and run the feature class in one command (`build && test --no-build --filter-class '*<Feature>AcceptanceTests'`). Verify **every new test fails for the right reason** (`NotImplementedException`, wrong value, missing element)—never compile error, `total: 0`, or accidental pass.
- Report concisely: `12 tests, 12 failing as expected`.

## 4. Green + refactor (token-efficient inner loop)
For each slice in `tasks.md`:
1. Implement the cleanest code that passes that slice's ACs (`SKILL.md` §3).
2. Chain **build + filtered test** in one shell call (`rtk dotnet build <TestProj> --no-restore && <test-cmd> --no-build --filter-class '*<Feature>AcceptanceTests'` or single AC prefix).
3. On red: read the failure message + `Expected:`/`Actual:` + first repo frame from `-v` output; fix the code, not the test.
4. On green: refactor if helpful while staying green, move to the next slice. Batch task checkoffs (`Edit` on `tasks.md`) instead of running a separate `sed` command per task.

**Never weaken a test to make it pass** (loosen assertions, `Skip`, catch expected exceptions, alter expected values). If a test is wrong, the spec is wrong: stop, propose the spec fix, and update spec/test/tasks together once approved.

**Loop guard:** Same test failing after 2 different fix attempts → escalate (`SKILL.md` tripwires) with assertion, attempts, and hypothesis.

## 5. Finish (1 tool call)
1. Run `bash ~/.claude/skills/dotnet-token-efficient/scripts/dotnet-verify.sh <TestProj.csproj> <TestProjDirOrCsproj>` (formats touched files, builds + checks touched-file warnings, runs full affected test project `--no-build`).
2. Update `spec.md` (`Status: Done`) and tick remaining tasks (`[x]` or `[~]` with reason).
3. Report traceability table + exact counts (note any pre-existing failures explicitly—never claim all pass if any fail):
```markdown
| AC  | Tests                          | Result |
|-----|--------------------------------|--------|
| AC1 | AC1_CreatesOrder               | pass   |
| AC2 | AC2_Rejects..., AC2_Returns... | pass   |
Feature tests: 12/12. Orders.Tests: 214 total, 0 failed. Skipped: Playwright (no browser).
```

## Token rules
- Don't paste `spec.md` or `tasks.md` into chat—summarize and link.
- Don't re-read `spec.md` during phase 4; test names and task lines carry the criteria.
- Prefer `--filter-class '*<Feature>AcceptanceTests'` over long multi-flag `--filter-method` lists when the feature test class is fast (<2s).
