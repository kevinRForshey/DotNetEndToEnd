#!/usr/bin/env bash
# Run `dotnet test` (safe under MTP, where `rtk dotnet test` injects --report-trx) and print only failures + counts.
# Usage: dotnet-test-summary.sh [-v] <dotnet test args...>
#   -v  also show exception, Expected/Actual, and repo .cs line frames (capped at 40 lines)
# Exit code is dotnet test's. Full log is kept in $TMPDIR for grepping if needed.
set -uo pipefail
verbose=0; [[ "${1:-}" == "-v" ]] && { verbose=1; shift; }
log="$(mktemp "${TMPDIR:-/tmp}/dotnet-test.XXXXXX.log")"
dotnet test "$@" >"$log" 2>&1; rc=$?
if (( verbose )); then
  out_fail="$(grep -E '^failed |^\s*Failed [A-Za-z_]|Exception|Assert|Expected:|Actual:|Values differ|^\s+at .*\.cs:(line )?[0-9]+' "$log" \
    | grep -vE '^\s+at (Xunit|System|Microsoft\.Testing)\.' \
    | sed -E 's/ \(?\[?[0-9]+ ?ms[])]?//; s/^ +//' \
    | head -40)"
else
  out_fail="$(grep -E '^failed |^\s*Failed [A-Za-z_]' "$log" | grep -v 'Failed!' | sed -E 's/ \(?\[?[0-9]+ ?ms[])]?//; s/^ *//')"
fi
[[ -n "$out_fail" ]] && printf '%s\n' "$out_fail"
out_sum="$(grep -E '^\s*(total|failed|succeeded|skipped):|Test run summary|^\s*(Passed|Failed|Skipped)!|Total tests' "$log" | sed 's/^ *//' | sort -u)"
[[ -n "$out_sum" ]] && printf '%s\n' "$out_sum"
errs="$(grep -oE '([^ /]+\.(cs|targets)\([0-9]+,[0-9]+\)|MSBUILD|[^ /]+proj) ?: error [A-Z0-9]*: [^[]*' "$log" | sort -u | head -15)"
[[ -n "$errs" ]] && { echo "BUILD ERRORS:"; printf '%s\n' "$errs"; }
grep -qE '^\s*total:\s*0\b|No test matches the given testcase filter' "$log" && echo "WARNING: the filter matched nothing (not a pass)."
if (( rc != 0 )) && [[ -z "$out_fail" && -z "$out_sum" && -z "$errs" ]]; then
  echo "ERROR OUTPUT:"
  grep -v '^[[:space:]]*$' "$log" | head -15
fi
echo "exit=$rc log=$log"
exit $rc
