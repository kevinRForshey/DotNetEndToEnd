# Plan: `dotnet` end-to-end development skill

## Goals
1. Token-optimized by default (RTK + Headroom + Serena, used together without overlap).
2. Modern .NET/C# idioms for the *detected* target framework (.NET 10 LTS / C# 14, .NET 11 STS / C# 15).
3. Gang of Four patterns applied when they fit the problem, never forced.
4. API and UI/UX best practices.
5. "Ask, don't guess": explicit checkpoints where Claude stops and confirms with the user.

## Layout (progressive disclosure: SKILL.md stays small, references load on demand)
```
dotnet/
  SKILL.md                      # hub: workflow, ask-don't-guess protocol, routing table
  references/
    token-optimization.md       # which tool for which job (rtk / headroom / serena / Read)
    modern-csharp.md            # per-version features; verified against learn.microsoft.com
    design-patterns.md          # GoF -> idiomatic .NET mapping, "use when / don't use when"
    api.md                      # ASP.NET Core API practices
    ui-ux.md                    # UI stack(s) + accessibility (WCAG 2.2)
    testing.md                  # test strategy, MTP vs VSTest, filters
  scripts/
    detect-env.sh               # one-shot compact summary: SDKs, global.json, TFMs, test runner, tooling health
```

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
- [x] Merged prior draft: MTP section + details.md + dotnet-test-summary.sh into dotnet-build-test; navigation.md + project-setup.md into dotnet/references
- [ ] User review of SKILL.md

### Phase 3: modern .NET reference
- [ ] Fetch and verify the "What's new" pages for .NET 10/C# 14 and .NET 11/C# 15 (no features from memory alone)

### Phase 4: design patterns reference
### Phase 5: API reference
### Phase 6: UI/UX reference (scope depends on chosen stacks)
### Phase 7: evaluate with skill-creator (trigger accuracy + a couple of task evals)

## Decisions
- Structure: `dotnet` hub + keep `dotnet-build-test` and `ef-core` as separate skills
- UI stacks: Blazor, Razor Pages/MVC, MAUI, JS SPA + .NET API
- New projects: ask LTS vs STS every time; existing projects follow global.json/TFM (per project; repos can mix)
- Prior draft found: ~/Projects/DotNetEndToEndSkill/skills/dotnet-token-efficient (MTP gotchas, setup guide). Merged (draft folder left untouched)
