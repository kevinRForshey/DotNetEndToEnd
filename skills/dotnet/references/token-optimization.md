# Token optimization: which tool for which job

Three layers work together, each with its own job:
- **RTK** shrinks *command output* before it reaches context (Bash hook + explicit `rtk` prefixes).
- **Headroom** compresses *the request* in transit (local proxy on :8787) and caches prompts. It is invisible except for compression markers.
- **Serena** lets you read *one symbol* instead of a whole file (C# language server).

## Routing table
| Job | Use | Not |
|---|---|---|
| Environment / SDK / TFM facts | `bash ~/.claude/skills/dotnet/scripts/detect-env.sh` once per session | `dotnet --info`, reading every `.csproj` |
| Find a type / method / its callers | Serena `find_symbol`, `find_referencing_symbols`, `get_symbols_overview` | Reading whole files |
| Text search | `rtk rg -n "pattern" -g '*.cs'` (honors `.gitignore`, so skips bin/obj) | `rtk grep -r` (searches bin/obj; RTK `ignore_dirs` is not applied) |
| Find files | `rtk rg --files -g '*.csproj'` | `rtk find` (descends into bin/obj) |
| Read code | Serena symbol body, or `Read` with `offset`/`limit` | Reading a 1,000-line file to see one method |
| Build / restore | `dotnet build ...` (the hook rewrites it to `rtk dotnet build`) | `--verbosity detailed`, `-bl` |
| Test (VSTest) | **`rtk dotnet test ...`**, written explicitly | bare `dotnet test` (the hook does **not** rewrite it) |
| Test (MTP: `global.json` `test.runner` = Microsoft.Testing.Platform) | plain `dotnet test --project X` piped to a summary grep (see `dotnet-token-efficient`) | `rtk dotnet test`: it adds `--report-trx`, which MTP rejects without `Microsoft.Testing.Extensions.TrxReport` |
| Format | **`rtk dotnet format ...`**, written explicitly | bare `dotnet format` (not rewritten) |
| EF Core | the `dotnet-token-efficient` skill | reading snapshots or Designer files |
| Long logs | `rtk log <file>` or `rtk err <cmd>` | `cat` |
| JSON (appsettings, launchSettings) | `rtk json <file>` or `rtk json --keys-only` | printing the whole file |

Build and test scope rules are in the `dotnet-token-efficient` skill. Load it before any build or test.

## Compression markers: recover, never guess
Output can come back with content elided:
- Headroom: `[N items compressed... hash=abc123]` → call `headroom_retrieve` with that hash.
- RTK: `[+N hidden: rtk recall <hash>]` → run `rtk recall <hash>`.

Rule: if the answer depends on the elided part, **retrieve it**. Never infer what "probably" was in it. If it doesn't matter, move on without retrieving. Skipping a retrieve saves tokens, but guessing at elided content is how hallucinations start.

## Habits
- Restore once, then pass `--no-restore` / `--no-build` to later commands.
- Write very large outputs to the session scratchpad and search them. Don't print them.
- Never read `bin/`, `obj/`, `TestResults/`, `*.Designer.cs`, `*ModelSnapshot.cs`, `*.resx` or lock files (settings.json denies most of these).
- Don't re-read a file you just edited to check the edit.
- Measure occasionally: `rtk gain`, `headroom savings`.
