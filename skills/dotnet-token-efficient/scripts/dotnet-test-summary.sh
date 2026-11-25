#!/usr/bin/env bash
# Run `dotnet test` (works under MTP, where `rtk dotnet test` breaks) and print only failures + summary counts.
# Usage: dotnet-test-summary.sh [-v] <dotnet test args...>
#   -v  also show exception/assert lines under each failure (first 40 lines)
# Exit code is dotnet test's. Full log is kept in $TMPDIR for grepping if needed.
set -uo pipefail
verbose=0; [[ "${1:-}" == "-v" ]] && { verbose=1; shift; }
log="$(mktemp "${TMPDIR:-/tmp}/dotnet-test.XXXXXX.log")"
dotnet test "$@" >"$log" 2>&1; rc=$?
if (( verbose )); then
  grep -E '^failed |^\s*Failed [A-Za-z_]|Exception|Assert|^\s+at .*\.Tests?\.' "$log" | sed -E 's/ \(?\[?[0-9]+ ?ms[])]?//' | head -40
else
  grep -E '^failed |^\s*Failed [A-Za-z_]' "$log" | grep -v 'Failed!' | sed -E 's/ \(?\[?[0-9]+ ?ms[])]?//' | sed 's/^ *//'
fi
grep -E '^\s*(total|failed|succeeded|skipped):|Test run summary|^\s*(Passed|Failed|Skipped)!|Total tests' "$log" | sed 's/^ *//' | sort -u
errs="$(grep -oE '([^ /]+\.cs\([0-9]+,[0-9]+\)|MSBUILD|[^ /]+proj) ?: error [A-Z]+[0-9]+: [^[]*' "$log" | sort -u | head -15)"
[[ -n "$errs" ]] && { echo "BUILD ERRORS:"; echo "$errs"; }
grep -qE '^\s*total:\s*0\b|No test matches the given testcase filter' "$log" && echo "WARNING: the filter matched nothing (not a pass)."
echo "exit=$rc log=$log"
exit $rc
