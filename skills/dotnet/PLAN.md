# Plan: `dotnet` End-to-End Development Skill

## Goals
1. Token-optimized by default (compact SKILL.md, strict progressive disclosure, RTK + Headroom + Serena, zero duplicate reads/builds).
2. Accurate modern .NET/C# idioms gated by detected per-project TFM (.NET 10 LTS / C# 14, .NET 11 STS / C# 15).
3. Pragmatic SOLID principles & GoF patterns mapped to idiomatic .NET (never forced).
4. ASP.NET Core API, EF Core, and UI/UX best practices.
5. "Ask, don't guess": explicit checkpoints + hallucination tripwires.

## Layout (progressive disclosure)
Repo: `DotNetEndToEndSkill/` (symlinked into `~/.claude/skills/<name>`):
```
skills/
  dotnet/                         # hub: clarify, design (SOLID/patterns), implement, review
    SKILL.md                      # compact workflow, SOLID/modern baseline, fast-path verify, tripwires, routing table
    PLAN.md                       # this file
    references/
      spec-tdd.md                 # features: spec -> cohesive tasks -> red tests -> green slices
      solid-and-patterns.md       # pragmatic SOLID in C#/.NET, GoF -> .NET idioms, DI lifetimes & guardrails
      modern-csharp.md            # verified universal + C# 14/.NET 10 LTS + C# 15/.NET 11 STS reference
      api-and-data.md             # ASP.NET Core API + EF Core query/modeling best practices
      ui-ux.md                    # Blazor / Razor / MAUI / SPA UI + WCAG 2.2 AA
      token-optimization.md       # RTK / Headroom / Serena routing, Read-before-Edit, compression hash recovery
    scripts/
      detect-env.sh               # one-shot repo manifest: git root, specs, SDKs, global.json, TFMs, werror, ready test cmd
  dotnet-token-efficient/         # command runner & repo navigator
    SKILL.md                      # orient, navigate, build/warn-check, test (VSTest/MTP), format, EF CLI, chained finish
    references/
      navigation.md               # symbol tools, rg + Read offset/limit, Blazor, skip-list
      build-test.md               # test scope, MTP, Testcontainers, Playwright, failure reading
      ef-core.md                  # EF CLI commands without reading generated files
      project-setup.md            # CLAUDE.md template, RTK hook, skill parking, cross-platform hygiene
    scripts/
      dotnet-test-summary.sh      # MTP-safe summary: failures, Expected/Actual, repo frames, counts, build errors
      dotnet-test-summary.ps1     # PowerShell equivalent
      dotnet-verify.sh            # 1-call finish: format touched files -> build + touched-file warn check -> test summary
      dotnet-verify.ps1           # PowerShell equivalent
```

## Status
- [x] Phase 1: Token optimization (RTK + Headroom + Serena routing, `detect-env.sh`)
- [x] Phase 2: Hub `SKILL.md` + `spec-tdd.md` + consolidation with `dotnet-token-efficient`
- [x] Phase 3: Verified modern .NET reference (`references/modern-csharp.md`, verified against Microsoft Learn for C# 14/.NET 10 and C# 15/.NET 11)
- [x] Phase 4: SOLID & design patterns reference (`references/solid-and-patterns.md`)
- [x] Phase 5: ASP.NET Core API & EF Core data reference (`references/api-and-data.md`)
- [x] Phase 5b: Token-efficiency & accuracy pass (deduplicated both `SKILL.md`s, sharpened shorter trigger descriptions, upgraded `detect-env.sh` + `dotnet-test-summary.{sh,ps1}` with `Expected:`/`Actual:`, batched TDD slices, chained finish checks, `Read`-before-`Edit` rule)
- [x] Phase 6: UI/UX reference (`references/ui-ux.md` — Blazor, Razor/MVC, MAUI, SPA+API, WCAG 2.2 AA)
- [ ] Phase 7: Re-run trigger evals + noisy-repo benchmarks (`ShopNoisy`) and verify `dotnet-test-summary.ps1` under `pwsh`
