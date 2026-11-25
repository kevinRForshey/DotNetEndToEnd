# Run `dotnet test` (works under MTP, where `rtk dotnet test` breaks) and print only failures + summary counts.
# Usage: dotnet-test-summary.ps1 [-v] <dotnet test args...>
#   -v  also show exception/assert lines under each failure (first 40 lines)
# Exit code is dotnet test's. Full log is kept in the temp folder for grepping if needed.
$verbose = $false
$testArgs = @($args)
if ($testArgs.Count -gt 0 -and $testArgs[0] -eq '-v') { $verbose = $true; $testArgs = @($testArgs | Select-Object -Skip 1) }
$log = Join-Path ([IO.Path]::GetTempPath()) ("dotnet-test.{0}.log" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
& dotnet test @testArgs *> $log
$rc = $LASTEXITCODE
$lines = Get-Content $log
$stripMs = { ($_ -replace ' \(?\[?\d+ ?ms[\])]?', '').TrimStart() }
if ($verbose) {
  $lines | Where-Object { $_ -match '^failed |^\s*Failed [A-Za-z_]|Exception|Assert|^\s+at .*\.Tests?\.' } | ForEach-Object $stripMs | Select-Object -First 40
} else {
  $lines | Where-Object { $_ -match '^failed |^\s*Failed [A-Za-z_]' -and $_ -notmatch 'Failed!' } | ForEach-Object $stripMs
}
$lines | Where-Object { $_ -match '^\s*(total|failed|succeeded|skipped):|Test run summary|^\s*(Passed|Failed|Skipped)!|Total tests' } |
  ForEach-Object { $_.TrimStart() } | Sort-Object -Unique
$errs = $lines | Select-String -Pattern '([^ /\\]+\.cs\(\d+,\d+\)|MSBUILD|[^ /\\]+proj) ?: error [A-Z]+\d+: [^\[]*' -AllMatches |
  ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | Select-Object -First 15
if ($errs) { 'BUILD ERRORS:'; $errs }
if ($lines -match '^\s*total:\s*0\b|No test matches the given testcase filter') { 'WARNING: the filter matched nothing (not a pass).' }
"exit=$rc log=$log"
exit $rc
