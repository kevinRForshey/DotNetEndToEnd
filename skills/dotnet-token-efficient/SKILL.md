---
name: dotnet-token-efficient
description: Token-efficient C#/.NET workflow - navigating code, writing changes that pass review, building, testing (VSTest/MTP), formatting and EF Core migrations. Use before running any dotnet build/test/restore/format/ef command, or when exploring or setting up a .NET repo.
---

# .NET, end to end, with minimal tokens

The goal: every command and every file read should return only what you need to make the next decision. Output you don't need still costs tokens, and it pushes earlier, useful context out of the window.

## 0. Orient once (first .NET task in a session)
- Find the git root: `git rev-parse --show-toplevel`. It may be **above** the solution folder, and specs, docs or scripts may live there.
- Read the repo's `CLAUDE.md` / `AGENTS.md` first. If it maps the projects, don't rediscover the layout by reading `.csproj` files.
- Note three facts and reuse them for the rest of the session:
  1. **Test runner:** if `global.json` contains `"test": {"runner": "Microsoft.Testing.Platform"}`, it's MTP; otherwise VSTest.
  2. **Test framework:** xUnit v2 or v3, NUnit or MSTest (check the test `.csproj` package references once).
  3. **Is `rtk` on PATH?** (`command -v rtk`). It compresses command output.
- Details: [references/navigation.md](references/navigation.md).

## 1. Navigate without reading whole files
- Prefer a symbol/code-index tool if one is connected (Serena `find_symbol` / `get_symbols_overview`, codebase-memory `search_graph` / `get_code_snippet`, or the IDE's). Otherwise use `grep -n` for the symbol, then read only that line range.
- Never open `bin/`, `obj/`, `TestResults/`, `*.trx`, `*.binlog`, `*.Designer.cs`, `*ModelSnapshot.cs`, old migrations, `wwwroot/lib/`, or lock files.
- Read a test method by line range, not the whole test file.

## 1b. Write code the repo would accept
- Match the conventions of the nearest existing code (naming, file-scoped namespaces, primary constructors, `var`, result/exception style). Read one sibling file's outline, not a style guide.
- Respect `<Nullable>enable</Nullable>`: no `!` to silence warnings; handle the null case or change the type.
- Introduce **no new warnings** (check in §2). If the repo sets `TreatWarningsAsErrors` or analyzer severities in `.editorconfig`, they are the rules.
- Async all the way: accept and pass `CancellationToken`, no `.Result`/`.Wait()`, no `async void` outside event handlers.
- Register services with the lifetime of their dependencies (never inject scoped into singleton). Prefer the framework's abstractions (`IOptions<T>`, `ILogger<T>`, `TimeProvider`, `IHttpClientFactory`).
- Smallest change that solves the task; no drive-by refactors. Add or update a test that fails without the change.

## 2. Build: smallest target that proves the change
```
rtk dotnet build path/to/Proj.csproj --no-restore     # one project
rtk dotnet build Solution.slnx -v minimal             # only for cross-project changes, or once at the end
```
Without rtk: `dotnet build X.csproj --no-restore -tl:off -v q -clp:"ErrorsOnly;NoSummary"`.
- Compile errors cascade. Fix the **first** error in each file, then rebuild.
- Don't report or fix warnings you didn't cause, unless asked. To check you caused none, build once without error-only filtering and keep only warnings in the files you touched:
  ```
  dotnet build X.csproj --no-restore --no-incremental -tl:off -v q 2>&1 | grep -E 'warning [A-Z]+[0-9]+' | grep -F -e Foo.cs -e Bar.cs | sed 's/ \[.*\]$//' | sort -u
  ```
  `--no-incremental` makes the compiler re-report warnings an up-to-date build would hide. No output means clean.

## 3. Test: filtered, summary-only
**VSTest** (no MTP opt-in):
```
rtk dotnet test X.Tests.csproj --no-build --filter "FullyQualifiedName~Namespace.ClassName"
```
Use `--no-build` only right after a successful build of that **same** test project; otherwise drop it. A stale build silently tests old code.
**Microsoft.Testing.Platform** (`global.json` opt-in). `rtk dotnet test` adds `--report-trx`, which MTP rejects unless the project references `Microsoft.Testing.Extensions.TrxReport`. Run plain `dotnet test` and keep only the summary:
```
dotnet test --project tests/X.Tests --filter-class '*ClassName' 2>&1 \
  | grep -E '^failed |^\s+(total|failed|succeeded|skipped):' | sed 's/ ([0-9]*ms)//'
```
Or use the bundled helper, which also flags `total: 0` and compile errors and keeps the full log in a temp file:
`scripts/dotnet-test-summary.sh [-v] <dotnet test args>` (PowerShell: `scripts/dotnet-test-summary.ps1`). `-v` adds exception lines.

MTP + xUnit v3 traps:
- `--filter-class` and `--filter-method` in one run are **AND-ed**. Mixing two unrelated filters matches nothing.
- **`total: 0` means the filter matched nothing.** It is not a pass. Fix the filter.
- In zsh, `$FILTER` holding `--filter-class X` is passed as ONE argument (no word splitting). Write the flags literally or use an array.

More (Testcontainers, Playwright, expected-failure log noise, the TDD "red" step): [references/build-test.md](references/build-test.md).

## 4. Format only what you touched
```
rtk dotnet format X.csproj --include path/one/ path/two/File.cs     # whitespace + style + analyzers, fixed in place
```
Run it **once**, before finishing, on the smallest project that contains your files. Don't follow it with a `--verify-no-changes` run: that reloads the whole workspace to confirm what the fix just did (leave verify to CI, or use it alone when you must not edit). Without rtk, drop the prefix. On a large solution where the analyzer pass is slow, `dotnet format whitespace` + `dotnet format style` cover most of it.

## 5. EF Core: ask the CLI, don't read generated files
Build once, then add `--no-build` to every `dotnet ef` command, and always pass `--project` / `--startup-project` (and `--context` if there are several). Read only the migration you just generated. Details: [references/ef-core.md](references/ef-core.md).

## 6. Finish
- After filtered runs pass, run **each affected test project once**. Don't "double-check" by re-running the whole suite.
- Report counts (e.g. `85 total, 0 failed`), not logs. If something was skipped (no Docker, no browser), say so.

## Never
- `dotnet clean` or deleting `obj/`, unless a rebuild leaves phantom errors.
- Printing build logs, TRX files, migration SQL or snapshots into the conversation. Write them to a temp file and `grep` it.
- Re-running a command just to see output you already filtered away. Re-run with a wider filter instead.

## Setting a repo up for this
For a CLAUDE.md block to paste in, the RTK hook, parking unused skills, and cross-platform settings: [references/project-setup.md](references/project-setup.md).
