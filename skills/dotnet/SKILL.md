---
name: dotnet
description: End-to-end C#/.NET development workflow - clarifying requirements, designing (including Gang of Four patterns where they fit), implementing with modern C# for the project's target framework (.NET 10 LTS / .NET 11 STS), building ASP.NET Core APIs and UIs (Blazor, Razor Pages/MVC, MAUI, SPA + API), spec-first TDD (spec → tasks → failing tests → implementation), verifying and reviewing - with minimal token use and explicit check-ins instead of guesses. Use when building, changing, designing, or reviewing features in a .NET/C# codebase, or starting a new .NET project. For build/test/format and EF Core commands, use dotnet-token-efficient.
---

# .NET end to end

Two rules sit above everything else in this skill:
1. **Spend tokens on decisions, not on output.** See [references/token-optimization.md](references/token-optimization.md).
2. **Never guess. Verify it or ask.** A wrong guess costs more than a question.

## 0. Orient (once per session, per repo)
1. Read the repo's `CLAUDE.md` / `AGENTS.md`. If it maps the projects, trust that map.
2. Run `bash ~/.claude/skills/dotnet/scripts/detect-env.sh` from the repo root. It lists SDKs, **every** `global.json` (they are often nested next to the `.sln`), each project's TFM and kind (web/razor/maui/test framework/efcore), and token-tooling health.
3. Note for the rest of the session:
   - The **TFM of each project you will touch**. Repos can mix `net10.0` and `net11.0`, and the language features you may use follow the project, not the repo.
   - The test runner (VSTest or MTP) and the test framework.
   - Existing conventions: one sample of each relevant layer (endpoint, service, component, test). Read a symbol, not a file (navigation: [dotnet-token-efficient/references/navigation.md](../dotnet-token-efficient/references/navigation.md)).
4. If token tooling is reported missing or unhealthy, tell the user once and continue with native fallbacks.

## 1. Clarify: before writing code
Restate the task in 1–3 lines along with the acceptance criteria you infer. **Ask** (one batched question, with a recommended option first) when any of these is unclear:
- Behavior: inputs, outputs, error cases, edge cases, who calls it.
- Scope: which projects and layers. Is a public contract (API, DTO, DB schema, NuGet package API) allowed to change?
- Non-functional: auth/authorization, performance targets, concurrency, multi-tenancy, PII/PHI handling.
- UI: an existing design system or component library? Accessibility target (default WCAG 2.2 AA)?
- **New projects:** always ask LTS (.NET 10, supported to Nov 2028) vs STS (.NET 11). Never pick for the user.

Don't ask about things the codebase already answers. Look first, and say what you found.

## 2. Design: proportional to risk
- **Small change** (one method, an obvious fix): skip formal design and follow existing patterns.
- **Feature or cross-cutting change:** use the spec-first TDD workflow in [references/spec-tdd.md](references/spec-tdd.md): `spec.md` with numbered acceptance criteria (approve) → `tasks.md` (approve) → acceptance tests that fail for the right reason → implement task by task until they pass. The design choices below go in the spec's Contracts section.
- **Patterns:** use a GoF pattern only when its forces are actually present (e.g. Strategy for interchangeable algorithms chosen at runtime, Decorator for cross-cutting behavior over an interface registered in DI). Name the pattern, the force it resolves, and the simpler alternative you rejected. Prefer the built-in .NET form (DI, `IOptions<T>`, middleware, `IEnumerable<IHandler>`, events/`IObservable<T>`) over hand-rolled scaffolding. If no pattern fits, use none.
- Match the conventions already in the codebase over textbook preferences. If you think a convention is harmful, raise it. Don't silently diverge.

## 3. Implement
- Use language and library features available to **that project's TFM/LangVersion**. If you aren't sure a feature or API exists in that version, verify it (tripwires below).
- Baseline for modern .NET: nullable enabled, async all the way down with `CancellationToken` passed through, DI with constructor injection (primary constructors where the codebase uses them), `IOptions<T>` with validation, structured logging (`ILogger` message templates, never string interpolation), `TimeProvider` instead of `DateTime.Now` in testable code, no `.Result`/`.Wait()`.
- Small, reviewable increments. Build after each meaningful step (`dotnet-token-efficient` skill).
- New NuGet packages: **ask first**. Say which package and why, and whether the BCL or an already-referenced package can do the job.

## 4. Verify
Follow the `dotnet-token-efficient` skill: build the smallest target, run filtered tests, then run each affected test project once at the end. Write or extend tests for new behavior, matching the repo's test framework and style.

## 5. Review before you say "done"
- [ ] Acceptance criteria from step 1 (or the spec) are met. Say how each was verified (for specs: the AC → test table).
- [ ] No unverified API, package, flag or config key remains (tripwires).
- [ ] Error paths handled. No swallowed exceptions. Cancellation flows through.
- [ ] No secrets, connection strings or PII in code or logs.
- [ ] Public contract changes were approved and are reflected in tests and docs.
- [ ] Touched files formatted once (`rtk dotnet format <proj> --include <paths>`) and no new warnings in them (dotnet-token-efficient §2).
- [ ] Report: what changed, test counts, and anything skipped or still uncertain. Never claim a check you didn't run.

## Hallucination tripwires: stop and verify, or ask
If you're about to rely on any of these and haven't **verified it in this session**, verify it first:
| About to... | Verify by |
|---|---|
| Call a type or member in *this* codebase | Serena `find_symbol` / `rtk rg` |
| Use a framework API, attribute or overload | Compile it, or check learn.microsoft.com (WebFetch). Highest risk: .NET 11 / C# 15 features |
| Use a NuGet package or version | `dotnet package search <name> --exact-match` / the existing `PackageReference`s |
| Use a CLI flag (`dotnet`, `dotnet ef`, MTP filters) | `<command> --help`, once per repo |
| Use a config key / `appsettings` section | `rtk rg` the key in the repo, or the docs |
| Describe content that was compressed away | `headroom_retrieve` / `rtk recall` (never infer it) |

**Escalate to the user** (stop, share your plan and the open assumptions, and ask) when:
- two or more tripwires fire for the same piece of work, or one can't be resolved by checking;
- you notice you have retried the same failing approach twice;
- the plan depends on how something "probably" works;
- requirements and the existing code disagree.

How to ask: say what you checked, the specific question, 2–4 options with your recommendation first, and what each choice implies. Batch questions. Don't drip-feed them.

## References (load only when needed)
| Topic | File |
|---|---|
| Spec → tasks → failing tests → implementation (features) | [references/spec-tdd.md](references/spec-tdd.md) |
| Token routing: rtk / headroom / serena, compression markers | [references/token-optimization.md](references/token-optimization.md) |
| Navigating a .NET repo cheaply (Blazor specifics) | [dotnet-token-efficient/references/navigation.md](../dotnet-token-efficient/references/navigation.md) |
| Preparing a repo for LLM work (CLAUDE.md block, RTK, hygiene) | [dotnet-token-efficient/references/project-setup.md](../dotnet-token-efficient/references/project-setup.md) |
| Build / test / format | `dotnet-token-efficient` skill |
| EF Core migrations | `dotnet-token-efficient` skill |
