#!/usr/bin/env bash
# Compact .NET environment summary for the `dotnet` skill. Run from repo root (or pass a path).
# Prints facts + ready commands only; never prints file contents or secrets.
set -uo pipefail
root="${1:-.}"
cd "$root" 2>/dev/null || { echo "no such dir: $root"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }
files() { if have rg; then rg --files -g "$1" -g '!**/bin/**' -g '!**/obj/**' -g '!**/node_modules/**' 2>/dev/null; else find . -name "$1" -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*' 2>/dev/null; fi; }
val() { grep -hoE "<$1>[^<]+</$1>" "${@:2}" 2>/dev/null | sed -E "s#</?$1>##g" | sort -u | paste -sd, -; }

git_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo "## Repo: $git_root"
spec_dir="$(files '*spec*.md' | head -3 | paste -sd, -)"
[[ -n "$spec_dir" ]] && echo "- specs: $spec_dir"
if have dotnet; then echo "- SDKs: $(dotnet --list-sdks 2>/dev/null | awk '{print $1}' | paste -sd, -)"; else echo "- SDKs: dotnet NOT FOUND"; fi

mapfile -t gjs < <(files 'global.json')
runner_mode="VSTest"
if [[ ${#gjs[@]} -eq 0 ]]; then
  echo "- global.json: none (SDK=latest, runner=VSTest)"
else
  for gj in "${gjs[@]}"; do
    sdk=$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$gj" | head -1 | grep -oE '[0-9][^"]*')
    roll=$(grep -oE '"rollForward"[[:space:]]*:[[:space:]]*"[^"]+"' "$gj" | grep -oE '"[^"]+"$' | tr -d '"')
    runner=$(grep -oE '"runner"[[:space:]]*:[[:space:]]*"[^"]+"' "$gj" | grep -oE '"[^"]+"$' | tr -d '"')
    [[ "$runner" == "Microsoft.Testing.Platform" ]] && runner_mode="MTP"
    echo "- $gj | sdk=${sdk:-unpinned} (${roll:-default}) | runner=${runner:-VSTest}"
  done
fi

mapfile -t projs < <(files '*.csproj')
mapfile -t props < <(files 'Directory.Build.props')
slns="$( (files '*.sln'; files '*.slnx') | paste -sd, - )"
[[ -n "$slns" ]] && echo "- solutions: $slns"

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
  grep -qiE '<TreatWarningsAsErrors>true' "$p" && kind+=" werror"
  echo "- $p | ${tfm:-<inherited>} | ${sdkattr}${kind}"
done

echo "## Settings & Tooling"
[[ ${#props[@]} -gt 0 ]] && echo "- Directory.Build.props(${#props[@]}): TFM=$(val 'TargetFrameworks?' "${props[@]}") Lang=$(val LangVersion "${props[@]}") Nullable=$(val Nullable "${props[@]}") WError=$(val TreatWarningsAsErrors "${props[@]}")"
cpm=$([[ -n "$(files 'Directory.Packages.props')" ]] && echo yes || echo no)
ec=$([[ -n "$(files '.editorconfig')" ]] && echo yes || echo no)
echo "- CPM=$cpm | .editorconfig=$ec"
[[ -f .config/dotnet-tools.json ]] && echo "- local tools: $(grep -oE '"[a-z0-9.-]+"[[:space:]]*:[[:space:]]*\{' .config/dotnet-tools.json | grep -oE '^"[^"]+"' | tr -d '"' | paste -sd, -)"
js_pkg="$(files 'package.json' | head -3 | paste -sd, -)"
[[ -n "$js_pkg" ]] && echo "- JS front end: $js_pkg"

rtk_status=$(have rtk && echo "rtk $(rtk --version 2>/dev/null | awk '{print $2}')" || echo "rtk:MISSING")
if have curl && curl -fsS -m 1 "http://127.0.0.1:${HEADROOM_PORT:-8787}/health" >/dev/null 2>&1; then
  hr_status="headroom:ok(routed=$([[ -n "${ANTHROPIC_BASE_URL:-}" ]] && echo yes || echo no))"
else
  hr_status="headroom:off"
fi
serena_status=$(have serena && echo "serena:ok" || echo "serena:MISSING")
echo "- tools: $rtk_status | $hr_status | $serena_status"

if [[ "$runner_mode" == "MTP" ]]; then
  echo "- test cmd (MTP): dotnet-test-summary.sh [-v] --project <TestProjDir> [--no-build] [--filter-class '*X' | --filter-method '*Y']"
else
  echo "- test cmd (VSTest): rtk dotnet test <TestProj.csproj> [--no-build] [--filter 'FullyQualifiedName~X']"
fi
