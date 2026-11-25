# EF Core without reading generated files

## Never open
- `*.Designer.cs`, `*ModelSnapshot.cs`, or old migrations. They are generated, often thousands of lines long, and the CLI answers the same questions.
- The only migration worth reading is the `<timestamp>_<Name>.cs` you just generated, to check `Up`/`Down`.

## Find things by searching
- DbContext: `grep -rln ": DbContext" --include='*.cs' .`
- Entity config: `grep -rn "Entity<Order>\|IEntityTypeConfiguration<Order>" --include='*.cs' .`, then read only that block.
- Startup project: the `.csproj` that references `Microsoft.EntityFrameworkCore.Design`. Migrations project: the one containing `Migrations/`.

## Tooling
- Check how `dotnet-ef` is installed: `dotnet tool list` (local manifest) or `dotnet tool list -g`. For a local tool, run `dotnet tool restore` once.
- Always pass `--project <migrations> --startup-project <startup>` (plus `--context X` if there are several contexts), so a command doesn't fail and need a retry.
- Build once, then add `--no-build` to every `dotnet ef` call. Without it, each one prints full build output.
- If the repo uses an `IDesignTimeDbContextFactory` driven by an environment variable, set it for that one command only.

## Ask the CLI
```
dotnet ef migrations list --no-build ...                        # what exists, what's applied
dotnet ef migrations has-pending-model-changes --no-build ...   # model differs from snapshot? (EF 8+)
dotnet ef dbcontext info --no-build ...                         # provider, database, context
sql="$(mktemp "${TMPDIR:-/tmp}/ef.XXXXXX.sql")"                 # PowerShell: $sql = New-TemporaryFile
dotnet ef migrations script <From> <To> --idempotent --no-build -o "$sql" ...
grep -nE 'DROP|ALTER COLUMN|RENAME' "$sql"                      # inspect, don't print
```

## Making a schema change
1. Edit the entity or configuration.
2. Build the migrations project.
3. `dotnet ef migrations add <Name> --no-build ...`
4. Read only the new `<timestamp>_<Name>.cs`. Look for unintended drops or renames (a rename can be read as a drop plus an add).
5. If the repo checks in SQL scripts, generate the idempotent script to the repo path it uses and `grep` it; don't print it.
6. To undo: `dotnet ef migrations remove --no-build ...`. Never hand-edit the snapshot.

## Safety
Run `dotnet ef database update` only against a clearly local or dev database. Ask first if the connection string looks shared, staging or production.
