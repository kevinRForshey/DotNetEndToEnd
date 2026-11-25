# Build and test details

## Restore once
```
rtk dotnet restore path/to/Proj.csproj    # only on first run or after package changes
```
Then pass `--no-restore` to builds. Use `--no-build` for tests only right after a successful build of the **same** project (a stale build silently tests old code).

## Choosing the test scope
| Change | Run |
|---|---|
| One class or method | That test class: VSTest `--filter "FullyQualifiedName~Ns.Class"`, MTP `--filter-class '*Class'` |
| A new test method | `--filter-method '*MethodName'` (MTP) |
| Shared infrastructure (DI, DbContext, test fixtures) | The whole affected test project |
| Broad or cross-project | Each affected test project once, at the end |

Exclude slow suites when the repo tags them: VSTest `--filter "Category!=Integration"`. With MTP + xUnit v3, use `--filter-not-trait "Category=Integration"`. Check `--help` once per repo; flags differ by framework.

## Microsoft.Testing.Platform (MTP)
- Detect it from `global.json`: `"test": { "runner": "Microsoft.Testing.Platform" }`.
- Target a project with `dotnet test --project <dir-or-csproj>` and a solution with `--solution <sln>`.
- **rtk incompatibility:** `rtk dotnet test` injects `--report-trx`. MTP fails with *"Option '--report-trx' is provided by the 'Microsoft.Testing.Extensions.TrxReport' extension"*. Choose one:
  1. Run plain `dotnet test` through the bundled `scripts/dotnet-test-summary.sh` (or `.ps1`), or
  2. Add the `Microsoft.Testing.Extensions.TrxReport` package to the test projects (only if the team wants TRX output anyway).
- The summary lines MTP prints look like this:
  ```
  failed Ns.Class.Method(arg: 1) (812ms)
    Xunit...Exception: <message>
  Test run summary: Passed!
    total: 79
    failed: 0
    succeeded: 79
  ```
  To see why something failed, widen the grep to the exception lines: add `|Exception|Assert` to the pattern and pipe through `head -20`.

## Expected-failure noise
Tests that check validation on purpose (e.g. `Host` startup with bad options) log full stack traces such as *"Hosting failed to start ... OptionsValidationException"*. These are **not** failures. Always look at the summary counts before reading anything else.

## Testcontainers / Docker-backed tests
- Check that Docker is reachable once per session: `docker info --format '{{.OSType}}/{{.Architecture}}'`. If it isn't, run the unit-test projects only and tell the user which suites were skipped.
- The first run pulls the image (SQL Server is about 1.5 GB). Allow a long timeout and don't retry because it looks slow.
- The SQL Server image is x64-only and needs Linux containers (on Windows, Docker Desktop in Linux-containers mode).

## Playwright / browser tests
- Hard-coded `Channel = "msedge"` or `"chrome"` only works where that browser is installed. For cross-platform suites, use the bundled Chromium (`LaunchAsync(new() { Headless = true })`).
- Install the browser once per machine without PowerShell:
  ```
  B=tests/X.Tests/bin/Debug/<tfm>/.playwright
  $B/node/<os-arch>/node $B/package/cli.js install chromium      # add --with-deps on Debian/Ubuntu
  ```
  or `pwsh bin/Debug/<tfm>/playwright.ps1 install chromium`.

## TDD "red" step without compile noise
To confirm new tests fail before implementing:
1. Add the new member to the interface or class with a body of `throw new NotImplementedException();`. For a new Razor component, add a stub that has only its `[Parameter]`s.
2. Build, then run only the new tests. Expect every one to fail **for the right reason** (`NotImplementedException`, or a missing element), not because of compile errors.
3. Implement, re-run the same filter, then run the whole affected project once.

## Reading a failure
Read the assertion message and the first stack frame inside the repo's code, then that test method by line range. Don't read the whole test file or the TRX.
