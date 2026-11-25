---
name: dotnet-token-efficient
description: Token-efficient C#/.NET command runner and repo navigator. Use before running any dotnet build, test, restore, format, or ef command (including running a test project, fixing build errors, checking DbContext pending model changes or migrations, or formatting touched files), and when mapping or configuring a .NET repo for agents.
---

# .NET Commands & Navigation (Token-Efficient)

Return only what drives the next decision. Batch independent `Read`/`Grep` calls in parallel; keep chat terse (no narrating tool calls, no pasting logs/diffs, final report ≤10 lines).

## 0. Orient (once per session)
- Read `CLAUDE.md` / `AGENTS.md` first; if it maps projects, skip `.csproj` discovery.
- Run `bash ~/.claude/skills/dotnet/scripts/detect-env.sh` once if installed; else `git rev-parse --show-toplevel; cat global.json 2>/dev/null; command -v rtk` (`"runner": "Microsoft.Testing.Platform"` → MTP; else VSTest). Details: [references/navigation.md](references/navigation.md).

## 1. Navigate cheaply
- Prefer connected symbol tools (Serena `serena_repl` / symbol tools, codebase-memory, LSP). Fallback: `rtk rg -n "<symbol>" -g '*.cs'` (gitignore-aware; never `rtk grep -r`), then `Read` with `offset`/`limit`.
- **Use `Read` directly on files you will `Edit`**—never `cat` via Bash first (`Edit` requires `Read`, so `cat` + `Read` doubles cost).
- **Never open:** `bin/`, `obj/`, `TestResults/`, `*.trx`, `*.binlog`, `*.Designer.cs`, `*ModelSnapshot.cs`, old migrations, `wwwroot/lib/`, lock files.
- Standalone fixes (without `dotnet` skill): smallest change, match sibling conventions, no `!` null-silencing, `CancellationToken` on async paths, no new warnings, no drive-by refactors.

## 2. Build (smallest target)
```bash
rtk dotnet build path/to/Proj.csproj --no-restore     # local change (no rtk: -tl:off -v q -clp:"ErrorsOnly;NoSummary")
rtk dotnet build Solution.slnx -v minimal             # cross-project or final pass only
```
Fix the **first** error per file, then rebuild. Skip extra `--no-incremental` warning grep when project has `werror`; otherwise check touched files only via `dotnet-verify.sh` (§6). Don't fix pre-existing warnings in untouched files.

## 3. Test (filtered, summary-only)
- **VSTest:** `rtk dotnet test X.Tests.csproj --no-build --filter "FullyQualifiedName~Ns.Class"`
- **MTP:** Never use `rtk dotnet test` (injects `--report-trx`). Call the summary helper directly (**never read the script**):
  ```bash
  bash ~/.claude/skills/dotnet-token-efficient/scripts/dotnet-test-summary.sh [-v] --project tests/X.Tests [--no-build] [--filter-class '*Class' | --filter-method '*Method']
  ```
  PowerShell: `scripts/dotnet-test-summary.ps1`. `-v` prints failures, exceptions, `Expected:`/`Actual:`, `.cs:line` frames (≤40 lines), and `log=` path.
- Use `--no-build` only right after building that same test project. **MTP traps:** `--filter-class` + `--filter-method` are AND-ed; `total: 0` = filter mismatch (not a pass); write flags literally in zsh.
- Testcontainers, Playwright, expected-failure noise: [references/build-test.md](references/build-test.md).

## 4. Format & EF Core
- **Format once:** `rtk dotnet format X.csproj --no-restore --include <paths>` (or let `dotnet-verify.sh` handle it). Never follow with `--verify-no-changes`.
- **EF Core:** Build once, then `--no-build --project <migrations> --startup-project <startup>` (+ `--context` if multiple) on every `dotnet ef` command. Read only the newly generated `<timestamp>_<Name>.cs`. Details: [references/ef-core.md](references/ef-core.md).

## 5. Finish (1 tool call)
```bash
bash ~/.claude/skills/dotnet-token-efficient/scripts/dotnet-verify.sh [--no-format] [--filter <expr>] <TestProj.csproj> <TestProjDirOrCsproj> [touched-files...]
```
PowerShell: `scripts/dotnet-verify.ps1` (never read the script). Auto-formats touched `.cs` files (`--no-restore`), builds + checks touched-file warnings (skips `--no-incremental` if `werror`), and runs full affected test project (`--no-build`). Don't re-run passing suites. Report exact counts (`85 total, 0 failed`), root cause/changes, and skipped/pre-existing items.

## Never
- `dotnet clean` / delete `obj/` unless phantom errors persist; paste logs/TRX/SQL/snapshots; re-run a command just to view filtered output (grep `log=` instead).

## Repo setup
CLAUDE.md block, RTK hook, skill parking, cross-platform hygiene: [references/project-setup.md](references/project-setup.md).
