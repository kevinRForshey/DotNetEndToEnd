# Setting up a .NET repo for token-efficient LLM work

## 1. A CLAUDE.md / AGENTS.md block to paste in
Keep it short. Every line is loaded into every session.
```markdown
## Working notes for agents
- Solution: `Solution.slnx`. Active projects: <list>. Folders not in the solution are legacy; don't read or change them.
- Build: `rtk dotnet build Solution.slnx -v minimal`. Build a single project when the change is local.
- Test: <VSTest|MTP>. Run only the affected test project with a filter. <If MTP: use plain `dotnet test --project ...`
  piped to the summary filter; `rtk dotnet test` adds --report-trx, which MTP rejects.>
- Docker-backed tests: <which projects>. Docker must be running.
- Navigate C# with <Serena / codebase-memory / grep + line ranges>, not whole-file reads.
- Generated files never to open: `*.Designer.cs`, `*ModelSnapshot.cs`, old migrations.
```
Move long how-to material (coding guidelines, DDD rules) into a separate file that CLAUDE.md links to with "read before X". Then it loads only when it's needed.

## 2. RTK (output compression)
[RTK](https://github.com/rtk-ai/rtk) wraps common CLIs and trims their output. Its Claude Code hook rewrites some Bash commands automatically. In `~/.claude/settings.json`:
```json
"hooks": {
  "PreToolUse": [
    { "matcher": "Bash", "hooks": [ { "type": "command", "command": "rtk hook claude" } ] }
  ]
}
```
- Verified for rtk 1.2.1: the hook rewrites `dotnet build`/`restore`, `grep` and `find`. It does **not** rewrite `dotnet test`, `dotnet format` or `dotnet ef`, so call `rtk dotnet test`/`rtk dotnet format` explicitly, **except under MTP** (see build-test.md). Check any command with `rtk hook check "<cmd>"`.
- `~/.config/rtk/config.toml` `ignore_dirs` is not applied by `rtk grep`/`find`/`tree` in 1.2.1. Use `rtk rg` for gitignore-aware search.
- Hooks that rewrite commands can conflict with Claude Code's auto-mode review. If a rewritten command is blocked, run it without the rewrite or approve it manually.

## 3. Keep the skill list small
Every installed skill's name and description is sent on every turn. Park the ones a repo doesn't use:
```
.claude/skills/            # active
.claude/skills-archive/    # parked; move a folder back to enable it
```
If the repo also serves GitHub Copilot, mirror the active set in `.github/skills/`.

## 4. Cross-platform hygiene (saves "works on my machine" debugging loops)
- `.gitattributes`: `* text=auto eol=lf`, with `*.ps1 *.cmd *.bat text eol=crlf`. Make `.editorconfig`'s `end_of_line` match.
- `global.json`: pin the SDK (`"sdk": {"version": "x.y.z", "rollForward": "latestFeature"}`) next to the test-runner setting.
- Give bash next to each PowerShell command in quickstarts (`cp` / `Copy-Item`, `export` / `$env:`, `openssl rand -base64 32` / `[Convert]::ToBase64String(...)`).
- Browser tests use Playwright's bundled Chromium, not a hard-coded Edge or Chrome channel.
- Tooling that ships only `.ps1` scripts (e.g. spec-kit installed with `--script ps`) needs a bash counterpart on Linux. Check upstream for official bash versions before porting by hand.

## 5. Permissions that avoid prompt churn
Allow-list read-only commands that run often (`git status`, `git diff`, `dotnet --list-sdks`, `docker info`, `grep`, `ls`) in `.claude/settings.json`, so each one isn't a round trip through a permission prompt.
