# EF Core CLI Without Reading Generated Files

For EF Core query/modeling best practices (`AsNoTracking`, projections, `IEntityTypeConfiguration`, concurrency, SQL safety), see `dotnet/references/api-and-data.md`.

## Never open
- `*.Designer.cs`, `*ModelSnapshot.cs`, or old migrations (often thousands of lines; the CLI answers the same questions).
- Read **only** the newly generated `<timestamp>_<Name>.cs` to inspect `Up`/`Down`.

## Locate quickly
- DbContext: `rtk rg -l ': DbContext' -g '*.cs'`
- Entity config: `rtk rg -n 'Entity<Order>|IEntityTypeConfiguration<Order>' -g '*.cs'`, then `Read` only that line range.
- Startup project: `.csproj` referencing `Microsoft.EntityFrameworkCore.Design`. Migrations project: contains `Migrations/`.

## Tooling rules
- Check `dotnet-ef`: `dotnet tool list` (local; run `dotnet tool restore` once) or `dotnet tool list -g`.
- Always pass `--project <migrations> --startup-project <startup>` (plus `--context <Name>` if multiple) to avoid error retries.
- Build once, then pass `--no-build` to every `dotnet ef` command.
- If `IDesignTimeDbContextFactory` reads an env var, set it inline for that command only.

## Ask the CLI
```bash
dotnet ef migrations list --no-build ...                        # existing + applied
dotnet ef migrations has-pending-model-changes --no-build ...   # model vs snapshot drift (EF 8+)
dotnet ef dbcontext info --no-build ...                         # provider, db, context
sql="$(mktemp "${TMPDIR:-/tmp}/ef.XXXXXX.sql")"                 # PowerShell: $sql = New-TemporaryFile
dotnet ef migrations script <From> <To> --idempotent --no-build -o "$sql" ...
grep -nE 'DROP|ALTER COLUMN|RENAME' "$sql"                      # inspect, never print full SQL
```

## Schema change flow
1. Edit entity / `IEntityTypeConfiguration<T>`.
2. Build migrations project once.
3. `dotnet ef migrations add <Name> --no-build ...`
4. `Read` only the new `<timestamp>_<Name>.cs` — verify no unintended `Drop*` or rename-as-drop+add.
5. Undo safely with `dotnet ef migrations remove --no-build ...` (never hand-edit `*ModelSnapshot.cs`).

## Safety
Run `dotnet ef database update` only against clearly local/dev databases; ask first if the connection string looks shared, staging, or production.
