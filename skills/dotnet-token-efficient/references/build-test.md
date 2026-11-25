# Build and Test Details

## Restore & Build Scope
- Restore only on first run or after package changes: `rtk dotnet restore path/to/Proj.csproj`. Pass `--no-restore` thereafter.
- Pass `--no-build` to tests only immediately after a successful build of that **same** test project.

## Choosing Test Scope
| Change | Run |
|---|---|
| One class or method | VSTest `--filter "FullyQualifiedName~Ns.Class"` / MTP `--filter-class '*Class'` |
| One test method | MTP `--filter-method '*MethodName'` |
| Shared infra (DI, DbContext, fixtures) | Whole affected test project |
| Broad / final verification | Each affected test project once |

Exclude slow suites when tagged: VSTest `--filter "Category!=Integration"`; MTP + xUnit v3 `--filter-not-trait "Category=Integration"` (check `--help` once per repo).

## Microsoft.Testing.Platform (MTP)
- Detected via `global.json`: `"test": { "runner": "Microsoft.Testing.Platform" }`.
- Target with `--project <dir-or-csproj>` or `--solution <sln>`.
- **rtk incompatibility:** `rtk dotnet test` adds `--report-trx`, which MTP rejects unless `Microsoft.Testing.Extensions.TrxReport` is installed. Use `scripts/dotnet-test-summary.sh [-v]` (or `.ps1`), which prints failed names, exceptions, `Expected:`/`Actual:`, test line frames, counts, build errors, and `total: 0` warnings while saving the full log to `$TMPDIR`.

## Expected-Failure Log Noise
Tests verifying failure paths (e.g., invalid options at host startup) often log full stack traces (`OptionsValidationException`) even when **passing**. Always check summary counts first.

## Testcontainers / Docker-Backed Tests
- Check Docker once per session: `docker info --format '{{.OSType}}/{{.Architecture}}'`. If unreachable, run unit tests only and report skipped suites.
- First SQL Server pull is ~1.5 GB (x64 Linux containers required)—allow a generous timeout; don't retry prematurely.

## Playwright / Browser Tests
- Avoid hard-coded `Channel = "msedge"` / `"chrome"`; use bundled Chromium (`LaunchAsync(new() { Headless = true })`).
- Install without PowerShell:
  ```bash
  B=tests/X.Tests/bin/Debug/<tfm>/.playwright
  $B/node/<os-arch>/node $B/package/cli.js install chromium   # add --with-deps on Debian/Ubuntu
  ```
  (or `pwsh bin/Debug/<tfm>/playwright.ps1 install chromium`).

## Reading a Failure
With `dotnet-test-summary.sh -v`, read the printed assertion + `Expected:`/`Actual:` + first repo frame, then `Read` that test method by line range. Grep the `log=` temp file only if more context is needed; never open full logs or `.trx` files.
