# Navigating a .NET Repo Cheaply

## Order of preference
1. **Repo map:** `CLAUDE.md`, `AGENTS.md`, or README architecture section. Trust it; verify a path only before editing.
2. **Symbol/index tools** (if connected): Serena (`serena_repl`—call `initial_instructions` once if unfamiliar—or direct `get_symbols_overview`/`find_symbol` if exposed), codebase-memory (`search_graph`, `get_code_snippet`), or LSP go-to-definition.
3. **ripgrep + targeted `Read`:** `rtk rg -n 'class OrderService\b' -g '*.cs'` (gitignore-aware; skips `bin/`/`obj/`, unlike `grep -r`/`rtk grep -r`), then `Read` ~40 lines with `offset`/`limit`.
   - **Important:** When you plan to `Edit` a file, use `Read` directly—never `cat` via Bash first, because `Edit` requires a prior `Read` and `cat` + `Read` doubles token cost.

## Quick layout facts (prefer one shot)
- Best (if `dotnet` skill is installed): `bash ~/.claude/skills/dotnet/scripts/detect-env.sh`
- Manual fallback (one combined call):
  ```bash
  git rev-parse --show-toplevel; ls *.sln *.slnx 2>/dev/null; cat global.json 2>/dev/null; grep -o '"[^"]*\.csproj"' *.slnx 2>/dev/null
  ```
Projects on disk but omitted from the solution are usually legacy—leave untouched unless asked.

## Blazor specifics
- Components split across `X.razor`, `X.razor.cs`, `X.razor.css`—open only the part needed.
- Find usages: `rtk rg -n '<ComponentName' -g '*.razor'`.
- Render mode / prerendering are configured at usage (`@rendermode`), not inside the component.

## Skip entirely
`bin/`, `obj/`, `TestResults/`, `node_modules/`, `wwwroot/lib/`, `*.min.js`, `*.Designer.cs`, `*ModelSnapshot.cs`, old `Migrations/*`, `packages.lock.json`, `*.trx`, `*.binlog`, `*.log`.

## Large non-code files
Specs/plans/tasks: `rg -n '^#|^- \[ \]' <file>` gives headings + open tasks; `Read` only the needed line range.
