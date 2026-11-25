# Plan: `dotnet` end-to-end development skill

## Goals
1. Token-optimized by default (RTK + Headroom + Serena, used together without overlap).
2. Modern .NET/C# idioms for the *detected* target framework (.NET 10 LTS / C# 14, .NET 11 STS / C# 15).
3. Gang of Four patterns applied when they fit the problem, never forced.
4. API and UI/UX best practices.
5. "Ask, don't guess": explicit checkpoints where Claude stops and confirms with the user.

## Layout (progressive disclosure: SKILL.md stays small, references load on demand)
Repo: `DotNetEndToEndSkill/` (GitHub `kevinRForshey/DotNetEndToEnd`). Both skills are installed as symlinks:
`~/.claude/skills/<name> -> DotNetEndToEndSkill/skills/<name>`, so edits here take effect immediately.
```
skills/
  dotnet/                         # hub: what to build and how (clarify, design, implement, review)
    SKILL.md                      # workflow, ask-don't-guess protocol, tripwires, routing table
    PLAN.md                       # this file
    references/
      spec-tdd.md                 # features: spec -> tasks -> failing tests -> implementation
      token-optimization.md       # which tool for which job (rtk / headroom / serena / Read)
      modern-csharp.md            # (planned) per-version features; verified against learn.microsoft.com
      design-patterns.md          # (planned) GoF -> idiomatic .NET mapping, "use when / don't use when"
      api.md                      # (planned) ASP.NET Core API practices
      ui-ux.md                    # (planned) UI stack(s) + accessibility (WCAG 2.2)
    scripts/
      detect-env.sh               # one-shot summary: SDKs, global.json, TFMs, test runner, tooling health
  dotnet-token-efficient/         # how to run things cheaply: navigate, build, test, format, EF Core
    SKILL.md                      # orient, navigate, code-quality rules, build + warning check, test, format, EF, finish
    references/
      navigation.md               # rg + line ranges, layout facts, Blazor specifics (shared with dotnet)
      build-test.md               # test scope, MTP vs VSTest, Testcontainers, Playwright, TDD red step
      ef-core.md                  # ask the CLI, never read generated files
      project-setup.md            # CLAUDE.md block, RTK hook, skill parking, cross-platform (shared with dotnet)
    scripts/
      dotnet-test-summary.sh      # failures + counts only; flags "filter matched nothing" and build errors
      dotnet-test-summary.ps1     # same, for PowerShell (untested: no pwsh on the dev machine)
```
Division of labour: `dotnet` triggers on feature/design work and routes to `dotnet-token-efficient` for every
build/test/format/ef command. `dotnet-token-efficient`'s description deliberately does not trigger on "changing C# code".

## Phases
### Phase 1: token optimization (environment + reference)
- [x] RTK: config created (ignore_dirs += bin/obj/TestResults/artifacts/.vs). Finding: rtk 1.2.1 grep/find/tree ignore it; `rtk rg` (gitignore-aware) is the fix
- [x] Verified: hook rewrites build/restore/grep/find only; NOT test/format/ef. Skill says to prefix those explicitly
- [x] Headroom: keep the managed ~/.profile routing (already sets ENABLE_TOOL_SEARCH=true); user chose not to switch to wrap
- [x] `references/token-optimization.md`
- [x] `scripts/detect-env.sh` (tested on ~/Projects/DDT: 0.3s, mixed net10/net11)

### Phase 2: hub SKILL.md
- [x] Workflow: Orient -> Clarify -> Design -> Implement -> Verify -> Review
- [x] Ask-don't-guess protocol + hallucination tripwires + escalation rules
- [x] Merged prior draft (MTP section, test-summary script, navigation, project setup) into `dotnet-token-efficient`
- [x] Spec-first TDD workflow (`references/spec-tdd.md`), wired into Design and the Review checklist
- [ ] User review of SKILL.md

### Phase 2b: consolidate with dotnet-token-efficient (2026-11-24)
- [x] Retired `dotnet-build-test` and `ef-core` (parked in `~/.claude/skills-archive/`); their content lives in `dotnet-token-efficient`
- [x] One copy of navigation.md / project-setup.md (in `dotnet-token-efficient`); old `dotnet` copies parked in `~/.claude/skills-archive/dotnet-references/`
- [x] Test-summary script verified on throwaway xUnit v2 (VSTest) and xUnit v3 (MTP) projects: pass, fail, -v, no-match filter, compile error, bad switch
- [x] Warning check (`--no-incremental` build, grep touched files) verified
- [ ] Run `dotnet-test-summary.ps1` under pwsh
- [ ] Run the spec-TDD workflow end to end on a real feature

### Phase 3: modern .NET reference
- [ ] Fetch and verify the "What's new" pages for .NET 10/C# 14 and .NET 11/C# 15 (no features from memory alone)

### Phase 4: design patterns reference
### Phase 5: API reference
### Phase 6: UI/UX reference (scope depends on chosen stacks)
(Testing strategy, planned as `testing.md`, is now covered by `spec-tdd.md` + `dotnet-token-efficient/references/build-test.md`.)
### Phase 7: evaluate with skill-creator (trigger accuracy + a couple of task evals)

## Decisions
- Structure: two skills. `dotnet` hub (what/how to build) + `dotnet-token-efficient` (running commands cheaply). `dotnet-build-test` and `ef-core` retired to avoid overlapping triggers
- UI stacks: Blazor, Razor Pages/MVC, MAUI, JS SPA + .NET API
- New projects: ask LTS vs STS every time; existing projects follow global.json/TFM (per project; repos can mix)
- `dotnet-token-efficient` is a full skill, not a draft. It owns build/test/format/EF and the shared navigation and setup references
- Both skills live in this repo and are symlinked into `~/.claude/skills/`
- Features use spec-first TDD; small fixes use one regression test. Tests are named `AC<n>_...` so the prefix doubles as the test filter
- Format runs once as a fix step (no follow-up `--verify-no-changes`)
