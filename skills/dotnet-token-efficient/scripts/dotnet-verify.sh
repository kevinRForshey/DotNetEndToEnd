#!/usr/bin/env bash
# Single-call .NET verification: format touched files -> build + touched-file warning check -> test summary (--no-build).
# Usage: dotnet-verify.sh [--no-format] [--filter <expr>] <build-target> <test-target> [touched-file...]
#   <build-target>  .csproj or .sln/.slnx to build (usually the test .csproj so app + tests compile together)
#   <test-target>   test project dir or .csproj
#   [touched-file]  optional; defaults to modified/untracked .cs files from git status
set -uo pipefail

no_format=0
filter=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-format) no_format=1; shift ;;
    --filter) filter="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,6p' "$0"; exit 0 ;;
    *) break ;;
  esac
done

build_target="${1:-}"
test_target="${2:-}"
shift $(( $# >= 2 ? 2 : $# ))
[[ -z "$build_target" || -z "$test_target" ]] && { echo "Usage: dotnet-verify.sh [--no-format] [--filter <expr>] <build-target> <test-target> [touched-file...]"; exit 2; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
have() { command -v "$1" >/dev/null 2>&1; }

# 1. Collect touched .cs files (explicit args or git status)
touched=()
if [[ $# -gt 0 ]]; then
  touched=("$@")
else
  while IFS= read -r f; do
    [[ "$f" == *.cs && -f "$f" ]] && touched+=("$f")
  done < <(git status --porcelain 2>/dev/null | awk '{print $NF}')
fi

# 2. Format touched .cs files once (skip if none or --no-format)
if (( ! no_format )) && [[ ${#touched[@]} -gt 0 ]]; then
  fmt_log="$(mktemp "${TMPDIR:-/tmp}/dotnet-fmt.XXXXXX.log")"
  if have rtk; then
    rtk dotnet format "$build_target" --no-restore --include "${touched[@]}" >"$fmt_log" 2>&1; fmt_rc=$?
  else
    dotnet format "$build_target" --no-restore --include "${touched[@]}" >"$fmt_log" 2>&1; fmt_rc=$?
  fi
  if (( fmt_rc != 0 )); then
    echo "Format: exit=$fmt_rc (log=$fmt_log)"
    grep -v '^[[:space:]]*$' "$fmt_log" | head -10
  else
    echo "Format: ok (${#touched[@]} file(s))"
    rm -f "$fmt_log"
  fi
else
  echo "Format: skipped"
fi

# 3. Detect TreatWarningsAsErrors + MTP runner
werror=0
if grep -qiE '<TreatWarningsAsErrors>true' "$build_target" Directory.Build.props 2>/dev/null; then
  werror=1
fi
is_mtp=0
gj="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/global.json"
if [[ -f "global.json" ]] && grep -q 'Microsoft\.Testing\.Platform' "global.json" 2>/dev/null; then
  is_mtp=1
elif [[ -f "$gj" ]] && grep -q 'Microsoft\.Testing\.Platform' "$gj" 2>/dev/null; then
  is_mtp=1
fi

# 4. Build (+ touched-file warning check when not werror)
bld_log="$(mktemp "${TMPDIR:-/tmp}/dotnet-build.XXXXXX.log")"
bld_flags=(--no-restore -tl:off -v q)
(( ! werror && ${#touched[@]} > 0 )) && bld_flags+=(--no-incremental)
dotnet build "$build_target" "${bld_flags[@]}" >"$bld_log" 2>&1; bld_rc=$?
if (( bld_rc != 0 )); then
  echo "BUILD FAILED (exit=$bld_rc, log=$bld_log):"
  grep -oE '([^ /]+\.(cs|targets)\([0-9]+,[0-9]+\)|MSBUILD|[^ /]+proj) ?: error [A-Z0-9]*: [^[]*' "$bld_log" | sort -u | head -15
  exit "$bld_rc"
fi

if (( werror )); then
  echo "Build: ok (werror)"
elif [[ ${#touched[@]} -gt 0 ]]; then
  grep_args=()
  for f in "${touched[@]}"; do grep_args+=(-e "$(basename "$f")"); done
  warns="$(grep -E 'warning [A-Z]+[0-9]+' "$bld_log" | grep -F "${grep_args[@]}" | sed 's/ \[.*\]$//' | sort -u | head -15)"
  if [[ -n "$warns" ]]; then
    echo "Build: ok | NEW WARNINGS in touched files:"
    printf '%s\n' "$warns"
  else
    echo "Build: ok (0 warnings in touched files)"
  fi
else
  echo "Build: ok"
fi
rm -f "$bld_log"

# 5. Test (--no-build, summary only)
if (( is_mtp )); then
  test_args=(-v --project "$test_target" --no-build)
  if [[ -n "$filter" ]]; then
    if [[ "$filter" == --filter-* ]]; then
      # shellcheck disable=SC2206
      test_args+=($filter)
    else
      test_args+=(--filter-class "$filter")
    fi
  fi
  exec bash "$script_dir/dotnet-test-summary.sh" "${test_args[@]}"
else
  test_args=("$test_target" --no-build)
  [[ -n "$filter" ]] && test_args+=(--filter "$filter")
  if have rtk; then
    exec rtk dotnet test "${test_args[@]}"
  else
    exec bash "$script_dir/dotnet-test-summary.sh" -v "${test_args[@]}"
  fi
fi
