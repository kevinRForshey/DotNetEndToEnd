# Navigating a .NET repo cheaply

## Order of preference
1. **The repo's own map.** `CLAUDE.md`, `AGENTS.md`, or the README's architecture section. Trust it, and verify a single path only when you're about to edit it.
2. **A code-index / symbol tool**, if connected:
   - Serena: `get_symbols_overview` (a file's outline), `find_symbol` (a body by name path), `find_referencing_symbols`.
   - codebase-memory-mcp: `search_graph`, `get_code_snippet`.
   - Any LSP-backed "go to definition" or "find references".
3. **ripgrep, then a line range.** `rtk rg -n 'class OrderService\b' -g '*.cs'` (or plain `rg`; fallback `grep -rn ... --include='*.cs' .`), then read about 40 lines from that line. `rg` honors `.gitignore`, so it skips bin/obj; `grep -r` and `rtk grep -r` do not. List a type's members with `grep -n "public\|private\|protected" File.cs` before reading bodies.

## Quick layout facts (one command each)
```
git rev-parse --show-toplevel                          # repo root, may be above the .sln
ls *.sln *.slnx; grep -o '"[^"]*\.csproj"' X.slnx      # projects actually in the solution
grep -l "Microsoft.NET.Sdk.Web" -r --include='*.csproj' .   # host projects
cat global.json                                        # SDK pin + test runner
dotnet --list-sdks
bash ~/.claude/skills/dotnet/scripts/detect-env.sh     # if the dotnet skill is installed: all of the above in one call
```
Projects that exist on disk but aren't in the solution are usually legacy. Leave them alone unless asked.

## Blazor specifics
- A component is split over `X.razor`, `X.razor.cs` and `X.razor.css`. Open only the part you need.
- To find where a component is used: `rg -n '<ComponentName' -g '*.razor'`
- Render mode and prerendering are set where the component is used (`@rendermode`), not in the component itself.

## Skip entirely
`bin/`, `obj/`, `TestResults/`, `node_modules/`, `wwwroot/lib/`, `*.min.js`, `*.Designer.cs`, `*ModelSnapshot.cs`, `Migrations/*` (except the one you just created), `packages.lock.json`, `*.trx`, `*.binlog`, `*.log`.

## Large non-code files
Specs, plans and task lists: `grep -n '^#\|^- \[ \]'` gives the outline and open tasks. Then read the section you need by line range.
