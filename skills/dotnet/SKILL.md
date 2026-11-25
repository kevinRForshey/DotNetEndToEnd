---
name: dotnet
description: C#/.NET design, SOLID architecture, and spec-first TDD workflow for adding, changing, or refactoring code in any .NET project (ASP.NET Core APIs, Blazor, Razor Pages/MVC, MAUI, libraries, .cs/.razor/.cshtml files, HttpClient, Polly, EF Core, MediatR) or starting a new .NET app. Use for code changes, refactoring, resilience/DI wiring, or new features—even when the prompt never says ".NET". For running build/test/format/EF CLI commands or mapping/configuring a repo, use dotnet-token-efficient.
---

# .NET End-to-End

1. **Minimize turns and output:** Batch independent reads/searches/edits in parallel; keep chat terse (no narrating tool calls, no pasting diffs/specs, final report ≤10 lines + AC table for specs); load references only when triggered below.
2. **Never guess—verify or ask.**

## 0. Orient (once per session)
- Read `CLAUDE.md` / `AGENTS.md`; trust its project map.
- Run `bash ~/.claude/skills/dotnet/scripts/detect-env.sh` once (git root, specs dir, SDKs, `global.json`, per-project TFM/framework/`werror`, tooling, ready test cmd).
- Track touched projects' **TFM** (repos mix `net10.0`/`net11.0`), runner (**VSTest** vs **MTP**), and `werror`. Inspect one sibling for conventions via Serena (`serena_repl` / symbol tools) or `Read` with `offset`/`limit`—never `cat` a file you will `Edit`. Note missing token tooling once and use native fallbacks.

## 1. Clarify (before coding)
Restate task + inferred ACs in 1–3 lines. Check code first; never ask what code answers. Ask **one batched question** (recommended option first, 2–4 choices) only when unclear on: behavior/errors/edge cases, scope/public contract changes (API/DTO/schema/NuGet), non-functionals (auth/authz, perf, concurrency, multi-tenancy, PII), or UI (design system, default WCAG 2.2 AA).
- **New projects:** always ask **LTS (.NET 10, Nov 2028)** vs **STS (.NET 11)**.

## 2. Design (3-tier, proportional to risk)
- **Tiny** (1–2 files, obvious fix): 1 failing regression test → fix → verify.
- **Standard** (internal refactor / single-layer tweak, clear requirements, no new/changed public contracts or DB schema): 3–5 line inline AC checklist in chat (no spec files) → tests → implement → verify.
- **Feature / Cross-cutting** (new user-facing feature, new/changed public contracts—domain types, APIs, DTOs, schema—multi-project, ambiguous scope, or explicit spec request): [references/spec-tdd.md](references/spec-tdd.md).
- **SOLID & Patterns (pragmatic):** **S** separate domain logic from HTTP/DB/UI (no God `*Service`); **O** extend via `IEnumerable<T>`/keyed DI/Strategy/Decorator over growing switches; **L** honor contracts, default `sealed`, prefer composition; **I** small role interfaces (no 1:1 "interfaceitis"); **D** abstract I/O/volatile seams (`TimeProvider`, HTTP, storage), constructor DI only. Use GoF patterns only when forces exist; prefer built-in .NET forms. Match repo conventions (raise harmful ones explicitly).

## 3. Implement
- Gate syntax/APIs strictly on each project's TFM/LangVersion.
- **Baseline:** `<Nullable>enable</Nullable>` (no `!` silencing); async + `CancellationToken` end-to-end (no `.Result`/`.Wait()`/`async void`); valid DI lifetimes (never scoped-in-singleton); `IOptions<T>` + `ValidateOnStart`; structured logging (`ILogger` templates / `[LoggerMessage]`, never `$""`); `TimeProvider` over `DateTime.Now`; `IHttpClientFactory` + `Microsoft.Extensions.Http.Resilience` (never `new HttpClient()` or legacy Polly v7 on .NET 8+).
- **New NuGet packages:** ask first (state why BCL/existing packages don't suffice; use a 5-line `TimeProvider` subclass in tests instead of adding a test package).

## 4. Verify (fast path; load `dotnet-token-efficient` only for EF/Docker/Playwright/complex builds)
- **Inner loop:** `rtk dotnet build <Test.csproj> --no-restore` chained with filtered test: VSTest `rtk dotnet test <Test.csproj> --no-build --filter "FullyQualifiedName~X"`; MTP `bash ~/.claude/skills/dotnet-token-efficient/scripts/dotnet-test-summary.sh -v --project <TestDir> --no-build --filter-class '*X'` (never `rtk dotnet test` on MTP; never read helper scripts).
- **Finish (1 tool call):** `bash ~/.claude/skills/dotnet-token-efficient/scripts/dotnet-verify.sh <Test.csproj> <TestDirOrCsproj>` (auto-formats touched `.cs` files with `--no-restore`, builds + checks touched-file warnings if no `werror`, runs full affected test project `--no-build`).

## 5. Review & Tripwires
Verify before saying "done": ACs met (spec: AC → test table); SOLID/DI lifetimes/error paths/`CancellationToken` sound; no secrets/PII in code or logs; approved public contract changes tested; `dotnet-verify.sh` clean; report changes, exact counts (never paste logs), and anything skipped or pre-existing.

**Verify first, never guess:** repo symbols (Serena / `rtk rg`); C# 14–15 / .NET 10–11 APIs (`modern-csharp.md`, compile, or `learn.microsoft.com`); NuGet (`dotnet package search <name> --exact-match`); CLI flags (`--help` once); config keys (`rtk rg`); compressed output (`headroom_retrieve` / `rtk recall`). **Escalate** with 2–4 options (recommended first) if ≥2 tripwires fire, a check fails to resolve one, the same fix fails twice, or requirements conflict with code.

## References (load ONLY when triggered)
| Load when... | File |
|---|---|
| Tier 3 feature / cross-cutting spec-first TDD | [references/spec-tdd.md](references/spec-tdd.md) |
| Non-trivial design, switch/God-class refactor, pattern choice | [references/solid-and-patterns.md](references/solid-and-patterns.md) |
| C# 14/15 or .NET 10/11 specific syntax/APIs | [references/modern-csharp.md](references/modern-csharp.md) |
| ASP.NET Core endpoints or EF Core entities/queries | [references/api-and-data.md](references/api-and-data.md) |
| Blazor, Razor Pages/MVC, MAUI, or SPA UIs | [references/ui-ux.md](references/ui-ux.md) |
| RTK / Headroom / Serena routing or compression hashes | [references/token-optimization.md](references/token-optimization.md) |
| EF migrations, Testcontainers, Playwright, repo setup | `dotnet-token-efficient` skill |
