#!/usr/bin/env bash
# Compact .NET environment summary for the `dotnet` skill. Run from the repo root (or pass a path).
# Prints facts only; never prints file contents or secrets.
set -uo pipefail
root="${1:-.}"
cd "$root" 2>/dev/null || { echo "no such dir: $root"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }
# gitignore-aware file listing that always skips build output
files() { if have rg; then rg --files -g "$1" -g '!**/bin/**' -g '!**/obj/**' 2>/dev/null; else find . -name "$1" -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null; fi; }
val() { grep -hoE "<$1>[^<]+</$1>" "${@:2}" 2>/dev/null | sed -E "s#</?$1>##g" | sort -u | paste -sd, -; }

echo "## SDKs"
if have dotnet; then dotnet --list-sdks 2>/dev/null | awk '{print "- "$1}'; else echo "- dotnet NOT FOUND"; fi

echo "## global.json (applies to its folder and below)"
mapfile -t gjs < <(files 'global.json')
[[ ${#gjs[@]} -eq 0 ]] && echo "- none (SDK = latest installed, test runner = VSTest)"
for gj in "${gjs[@]}"; do
  sdk=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$gj" | head -1 | grep -oE '[0-9][^"]*')
  roll=$(grep -oE '"rollForward"[[:space:]]*:[[:space:]]*"[^"]+"' "$gj" | grep -oE '"[^"]+"$')
  runner=$(grep -oE '"runner"[[:space:]]*:[[:space:]]*"[^"]+"' "$gj" | grep -oE '"[^"]+"$')
  echo "- $gj | sdk: ${sdk:-unpinned} rollForward: ${roll:-default} | test.runner: ${runner:-VSTest(default)}"
done

mapfile -t projs < <(files '*.csproj')
mapfile -t props < <(files 'Directory.Build.props')
echo "## Solutions"; files '*.sln' | sed 's/^/- /'; files '*.slnx' | sed 's/^/- /'
echo "## Projects (${#projs[@]})"
for p in "${projs[@]}"; do
  tfm=$(val 'TargetFrameworks?' "$p")
  sdkattr=$(grep -oE '<Project Sdk="[^"]+"' "$p" | head -1 | sed -E 's/.*Sdk="([^"]+)"/\1/')
  kind=""
  grep -qiE '<UseMaui>true' "$p" && kind+=" maui"
  grep -qiE 'Microsoft\.AspNetCore\.Components\.WebAssembly' "$p" && kind+=" blazor-wasm"
  grep -qiE 'xunit\.v3' "$p" && kind+=" xunit.v3" || { grep -qiE '"xunit"|Include="xunit"' "$p" && kind+=" xunit"; }
  grep -qiE 'Include="NUnit"' "$p" && kind+=" nunit"
  grep -qiE 'MSTest' "$p" && kind+=" mstest"
  grep -qiE 'Include="TUnit' "$p" && kind+=" tunit"
  grep -qiE 'Microsoft\.EntityFrameworkCore' "$p" && kind+=" efcore"
  echo "- $p | ${tfm:-<inherited>} | ${sdkattr}${kind}"
done

echo "## Repo-wide settings"
[[ ${#props[@]} -gt 0 ]] && echo "- Directory.Build.props: ${#props[@]} | TFM: $(val 'TargetFrameworks?' "${props[@]}") | LangVersion: $(val LangVersion "${props[@]}") | Nullable: $(val Nullable "${props[@]}") | TreatWarningsAsErrors: $(val TreatWarningsAsErrors "${props[@]}")"
[[ -n "$(files 'Directory.Packages.props')" ]] && echo "- Central Package Management: yes" || echo "- Central Package Management: no"
[[ -n "$(files '.editorconfig')" ]] && echo "- .editorconfig: yes" || echo "- .editorconfig: no"
[[ -f .config/dotnet-tools.json ]] && echo "- local tools: $(grep -oE '"[a-z0-9.-]+"[[:space:]]*:[[:space:]]*\{' .config/dotnet-tools.json | grep -oE '^"[^"]+"' | tr -d '"' | paste -sd, -)"
[[ -n "$(files 'package.json' | head -1)" ]] && echo "- JS front end present: $(files 'package.json' | grep -v node_modules | head -3 | paste -sd, -)"

echo "## Token tooling"
have rtk && echo "- rtk $(rtk --version 2>/dev/null | awk '{print $2}')" || echo "- rtk MISSING"
if have curl && curl -fsS -m 2 "http://127.0.0.1:${HEADROOM_PORT:-8787}/health" >/dev/null 2>&1; then
  echo "- headroom proxy healthy (:${HEADROOM_PORT:-8787}); routed: $([[ -n "${ANTHROPIC_BASE_URL:-}" ]] && echo yes || echo NO)"
else echo "- headroom proxy NOT reachable"; fi
have serena && echo "- serena installed" || echo "- serena MISSING"
