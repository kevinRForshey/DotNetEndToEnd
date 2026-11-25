# Spec → tasks → tests → implementation (TDD)

Use this for features and cross-cutting changes. For a one-method fix, skip the spec: write one failing regression test, make it pass, done.

Four artifacts, each one approved or proven before the next:

| Phase | Output | Gate |
|---|---|---|
| 1. Spec | `spec.md` with numbered acceptance criteria | User approves |
| 2. Tasks | `tasks.md`, each task tied to criteria and tests | User approves (can be the same turn as the spec for small features) |
| 3. Tests (red) | Acceptance tests that compile and fail for the right reason | Shown failing |
| 4. Implement (green) | Code, task by task, until every test passes | Full affected test projects pass |

## Where the files go
1. If the repo already has a convention, use it: spec-kit (`.specify/`, `specs/NNN-name/`), `docs/specs/`, ADR folders. `rg --files -g '*spec*.md' | head` finds it.
2. Otherwise: `specs/<NNN>-<kebab-name>/spec.md` and `tasks.md` at the repo root (NNN = next free number).

## 1. Spec
Clarify first (SKILL.md §1): one batched question, recommended option first. Don't ask what the code already answers. Then write the spec. **One page or less.** Template:

```markdown
# <Feature name>
Status: Draft | Approved | Done

## Problem
<2–4 lines: who needs what, and why>

## Scope
In: <bullets>   Out (non-goals): <bullets>

## Acceptance criteria
- AC1: Given <state>, when <action>, then <observable result>.
- AC2: Given ..., when <invalid input>, then <error: status code / exception / message>.
<Every criterion must be testable by an automated test. Errors and edge cases get their own ACs.>

## Contracts
<Endpoints, DTOs, public interfaces, schema changes: signatures only, no bodies. Mark breaking changes.>

## Constraints
<Auth, performance, concurrency, PII, TFM. Omit the section if none.>

## Open questions
<Must be empty before approval.>
```
Present it in a few lines (the AC list and any contract change), link the file, and **wait for approval**. Feedback changes the spec file, never just the chat.

## 2. Tasks
Write `tasks.md` next to the spec. Each task is a vertical slice one commit could hold. Order: contracts and stubs, then one or a few ACs per task, then the cross-cutting work (DI, config, migrations, docs).

```markdown
# Tasks: <Feature name>
- [ ] T1 Contracts + stubs: <types/members> throwing NotImplementedException. Files: <paths>
- [ ] T2 Acceptance tests for AC1–AC5 (red). Files: <test class path>
- [ ] T3 AC1, AC2: <what>. Files: <paths>. Tests: AC1_*, AC2_*
- [ ] T4 AC3: <what>. Depends: T3. Tests: AC3_*
- [ ] T5 Migration <Name> (if schema changes). Tests: AC4_*
```
Rules: every AC appears in at least one task; every implementation task names its tests; a task touching more than ~5 files gets split. **Wait for approval** (or bundle it with the spec approval).

## 3. Tests first (red)
- One test class per feature, e.g. `<Feature>AcceptanceTests`, in the test project that matches the layer (unit by default; integration only for an AC about HTTP, DB or the UI).
- **Name every test after its criterion:** `AC3_RejectsExpiredToken`, `AC3_ReturnsProblemDetails`. The prefix is the filter, and it works for every framework and runner:
  - VSTest: `--filter "FullyQualifiedName~AC3_"`
  - MTP: `--filter-method '*AC3_*'`
  - Whole feature: `--filter-class '*<Feature>AcceptanceTests'` (MTP) or `FullyQualifiedName~<Feature>AcceptanceTests` (VSTest)
- Good tests: one behaviour each, arrange/act/assert, assert on observable results (return value, HTTP status + body, persisted state), not on calls to private collaborators. Mock only what you don't own or what is slow (clock → `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing`, which is a new package, so ask first; HTTP → handler stub). Match the repo's test framework, assertion library and fixture style.
- Make it compile without implementing: add the T1 stubs (`throw new NotImplementedException();`, Razor components with only their `[Parameter]`s). See dotnet-token-efficient `references/build-test.md`, "TDD red step".
- Build, then run the feature's tests. **Every new test must fail, and for the right reason**: `NotImplementedException`, a wrong value, a missing element. Not a compile error, not `total: 0` (a filter typo), and not a pass (a test that passes before the code exists tests nothing; fix it).
- Tick T1 and T2. Report: `12 tests, 12 failing as expected`.

## 4. Implement task by task (green, then refactor)
For the next unticked task (`rg -n '^- \[ \]' specs/<NNN>-*/tasks.md | head -1`; don't re-read the whole file):
1. Write the least code that makes that task's tests pass. Follow SKILL.md §3.
2. Build the project, then run **only that task's filter** (`AC3_`).
3. Green: refactor if it helps (tests stay green), tick the task, and move on. Run the whole feature class every few tasks to catch regressions.
4. Red: read the assertion message and the first frame in repo code. Fix the code, not the test.

**Never weaken a test to make it pass** (loosen an assertion, add `Skip`, catch the exception, change the expected value). If a test is wrong, the spec is ambiguous or wrong: stop, say which AC and why, propose the spec change, and update spec, test and task together once approved.

**Loop guard:** the same test still failing after two different fix attempts means escalate (SKILL.md tripwires). Show the assertion, what you tried, and your hypothesis.

## 5. Finish
1. Run each affected test project once in full (not only the AC filters).
2. Format the touched files and do the warning check (dotnet-token-efficient §2, §4).
3. Set the spec's `Status: Done`. Every task is ticked, or marked `[~]` with a reason.
4. Report with a traceability table, then the usual counts:

```
| AC  | Tests                         | Result |
|-----|-------------------------------|--------|
| AC1 | AC1_CreatesOrder              | pass   |
| AC2 | AC2_Rejects..., AC2_Returns...| pass   |
Feature tests: 12/12. Orders.Tests: 214 total, 0 failed. Skipped: Playwright suite (no browser).
```

## Token notes
- The spec and tasks live in files. Don't paste them back into chat; summarise and link.
- Don't re-read the spec during phase 4. The task line holds the AC ids, and the test names hold the behaviour.
- Run per-task filters during the inner loop and full projects only at the end (dotnet-token-efficient §6).
