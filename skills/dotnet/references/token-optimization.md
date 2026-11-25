# Token Optimization: Tool Routing & Compression Recovery

Three layers work together without overlap:
- **RTK:** shrinks CLI output before it enters context (Bash hook + explicit `rtk` prefix).
- **Headroom:** compresses requests in transit (local proxy `:8787`) and caches prompts; invisible except for compression markers.
- **Serena:** C# language server—reads single symbols instead of whole files.

## Routing table
| Job | Use | Avoid |
|---|---|---|
| Repo/SDK/TFM/runner/tooling facts | `bash ~/.claude/skills/dotnet/scripts/detect-env.sh` once | `dotnet --info`, reading every `.csproj`, `cat global.json` |
| Find type/method/callers | Serena (`serena_repl` / `initial_instructions`, or `find_symbol`/`get_symbols_overview` if directly exposed) | Whole-file reads or `ToolSearch` guessing nonexistent tool names |
| Text search | `rtk rg -n "pattern" -g '*.cs'` (gitignore-aware) | `rtk grep -r` (ignores `ignore_dirs`, scans `bin/`/`obj/`) |
| File search | `rtk rg --files -g '*.csproj'` | `rtk find` (descends into `bin/`/`obj/`) |
| Inspect code to **edit** | `Read` directly (with `offset`/`limit` on large files) | `cat` via Bash + `Read` again (pays twice; `Edit` requires `Read`) |
| Inspect read-only code | Serena symbol body or `Read` with `offset`/`limit` | Reading 1,000-line files for one method |
| Build / restore | `dotnet build ... --no-restore` (hook rewrites to `rtk`) | `--verbosity detailed`, `-bl` |
| Test (VSTest) | `rtk dotnet test ...` (explicit; hook does **not** rewrite) | Bare `dotnet test` |
| Test (MTP) | `dotnet-test-summary.sh [-v] ...` (`dotnet-token-efficient`) | `rtk dotnet test` (injects `--report-trx`, breaks MTP) |
| Format | `rtk dotnet format <proj> --include <paths>` (explicit) | Bare `dotnet format`, or follow-up `--verify-no-changes` |
| Long logs / JSON | `rtk log <file>`, `rtk err <cmd>`, `rtk json --keys-only <file>` | `cat` |

## Compression markers: retrieve, never guess
- Headroom: `[N items compressed... hash=abc123]` → call `headroom_retrieve` with that hash.
- RTK: `[+N hidden: rtk recall <hash>]` → run `rtk recall <hash>`.

Rule: if your decision depends on elided content, **retrieve it**—never infer what was "probably" there. If irrelevant, move on without retrieving.

## High-leverage habits
- Batch independent `Read` / search calls in parallel; chain dependent shell commands (`format && build && test --no-build`).
- Never re-read a file you just edited to verify the edit.
- Never open `bin/`, `obj/`, `TestResults/`, `*.Designer.cs`, `*ModelSnapshot.cs`, `*.resx`, `*.trx`, or lock files.
- Write large outputs to `$TMPDIR` and `grep` them. Check savings occasionally with `rtk gain` / `headroom savings`.
