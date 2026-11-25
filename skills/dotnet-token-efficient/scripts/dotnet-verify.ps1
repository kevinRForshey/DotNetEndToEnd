# Single-call .NET verification: format touched files -> build + touched-file warning check -> test summary (--no-build).
# Usage: dotnet-verify.ps1 [-NoFormat] [-Filter <expr>] <build-target> <test-target> [touched-file...]
param(
  [switch]$NoFormat,
  [string]$Filter = '',
  [Parameter(Mandatory = $true, Position = 0)][string]$BuildTarget,
  [Parameter(Mandatory = $true, Position = 1)][string]$TestTarget,
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$TouchedFiles
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$hasRtk = [bool](Get-Command rtk -ErrorAction SilentlyContinue)

# 1. Collect touched .cs files
$touched = @()
if ($TouchedFiles -and $TouchedFiles.Count -gt 0) {
  $touched = @($TouchedFiles | Where-Object { $_ -like '*.cs' -and (Test-Path $_) })
} else {
  $gitLines = & git status --porcelain 2>$null
  foreach ($l in $gitLines) {
    $p = ($l.Trim() -split '\s+')[-1]
    if ($p -like '*.cs' -and (Test-Path $p)) { $touched += $p }
  }
}

# 2. Format touched .cs files once
if (-not $NoFormat -and $touched.Count -gt 0) {
  $fmtLog = Join-Path ([IO.Path]::GetTempPath()) ("dotnet-fmt.{0}.log" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
  if ($hasRtk) { & rtk dotnet format $BuildTarget --no-restore --include @touched *> $fmtLog }
  else { & dotnet format $BuildTarget --no-restore --include @touched *> $fmtLog }
  if ($LASTEXITCODE -ne 0) {
    "Format: exit=$LASTEXITCODE (log=$fmtLog)"
    Get-Content $fmtLog | Where-Object { $_.Trim() -ne '' } | Select-Object -First 10
  } else {
    "Format: ok ($($touched.Count) file(s))"
    Remove-Item $fmtLog -ErrorAction SilentlyContinue
  }
} else {
  'Format: skipped'
}

# 3. Detect TreatWarningsAsErrors + MTP runner
$werror = $false
foreach ($f in @($BuildTarget, 'Directory.Build.props')) {
  if ((Test-Path $f) -and (Select-String -Path $f -Pattern '<TreatWarningsAsErrors>true' -Quiet)) { $werror = $true }
}
$isMtp = $false
$top = (& git rev-parse --show-toplevel 2>$null)
foreach ($gj in @('global.json', (if ($top) { Join-Path $top 'global.json' }))) {
  if ($gj -and (Test-Path $gj) -and (Select-String -Path $gj -Pattern 'Microsoft\.Testing\.Platform' -Quiet)) { $isMtp = $true }
}

# 4. Build (+ touched-file warning check when not werror)
$bldLog = Join-Path ([IO.Path]::GetTempPath()) ("dotnet-build.{0}.log" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
$bldFlags = @('--no-restore', '-tl:off', '-v', 'q')
if (-not $werror -and $touched.Count -gt 0) { $bldFlags += '--no-incremental' }
& dotnet build $BuildTarget @bldFlags *> $bldLog
if ($LASTEXITCODE -ne 0) {
  $rc = $LASTEXITCODE
  "BUILD FAILED (exit=$rc, log=$bldLog):"
  Get-Content $bldLog | Select-String -Pattern '([^ /\\]+\.(cs|targets)\(\d+,\d+\)|MSBUILD|[^ /\\]+proj) ?: error [A-Z0-9]*: [^\[]*' -AllMatches |
    ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | Select-Object -First 15
  exit $rc
}

if ($werror) {
  'Build: ok (werror)'
} elseif ($touched.Count -gt 0) {
  $names = $touched | ForEach-Object { [IO.Path]::GetFileName($_) }
  $warns = Get-Content $bldLog | Where-Object { $_ -match 'warning [A-Z]+\d+' } | Where-Object {
    $line = $_; $names | Where-Object { $line.Contains($_) }
  } | ForEach-Object { $_ -replace ' \[.*\]$', '' } | Sort-Object -Unique | Select-Object -First 15
  if ($warns) { 'Build: ok | NEW WARNINGS in touched files:'; $warns }
  else { 'Build: ok (0 warnings in touched files)' }
} else {
  'Build: ok'
}
Remove-Item $bldLog -ErrorAction SilentlyContinue

# 5. Test (--no-build, summary only)
if ($isMtp) {
  $tArgs = @('-v', '--project', $TestTarget, '--no-build')
  if ($Filter) {
    if ($Filter -like '--filter-*') { $tArgs += ($Filter -split '\s+') }
    else { $tArgs += @('--filter-class', $Filter) }
  }
  & (Join-Path $scriptDir 'dotnet-test-summary.ps1') @tArgs
  exit $LASTEXITCODE
} else {
  $tArgs = @($TestTarget, '--no-build')
  if ($Filter) { $tArgs += @('--filter', $Filter) }
  if ($hasRtk) { & rtk dotnet test @tArgs; exit $LASTEXITCODE }
  else { & (Join-Path $scriptDir 'dotnet-test-summary.ps1') -v @tArgs; exit $LASTEXITCODE }
}
