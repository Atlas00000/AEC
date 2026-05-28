# Sync AEC tester presets: repo presets/tester/ -> Terminal MQL5/Profiles/Tester/
# Strategy Tester "Load" dropdown reads Profiles/Tester only (not Experts/AEC/presets/).

param(
    [string]$TerminalId = "D0E8209F77C8CF37AD8BF550E51FF075",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Experts/AEC/scripts/ -> Experts/AEC/
$repoRoot = Split-Path $PSScriptRoot -Parent
$src = Join-Path $repoRoot "presets\tester"
if (-not (Test-Path $src)) {
    throw "Source not found: $src"
}

$dest = Join-Path $env:APPDATA "MetaQuotes\Terminal\$TerminalId\MQL5\Profiles\Tester"
if (-not (Test-Path $dest)) {
    throw "MT5 Profiles/Tester not found: $dest`nCheck TerminalId or install path."
}

$sets = Get-ChildItem -Path $src -Filter "AEC*.set" -File
if ($sets.Count -eq 0) {
    Write-Warning "No AEC*.set files in $src"
    exit 0
}

$new = 0
$updated = 0
$same = 0

foreach ($f in $sets) {
    $target = Join-Path $dest $f.Name
    if ($WhatIf) {
        Write-Host "[whatif] $($f.Name) -> $dest"
        continue
    }
    if (-not (Test-Path $target)) {
        Copy-Item -LiteralPath $f.FullName -Destination $target -Force
        $new++
        continue
    }
    $srcHash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
    $dstHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
    if ($srcHash -eq $dstHash) {
        $same++
        continue
    }
    Copy-Item -LiteralPath $f.FullName -Destination $target -Force
    $updated++
}

if (-not $WhatIf) {
    Write-Host ""
    Write-Host "Synced AEC presets -> $dest"
    Write-Host "  Total in repo: $($sets.Count)  |  New: $new  |  Updated: $updated  |  Unchanged: $same"
    Write-Host ""
    Write-Host "T74/T75 (EDGE-AI-8):"
    @(
        "AEC.P10-F_p5f-long-range_EDGE-AI-8-T74.set",
        "AEC.P11-A_regime-gate_EDGE-AI-8-T75.set"
    ) | ForEach-Object {
        $p = Join-Path $dest $_
        if (Test-Path $p) { Write-Host "  OK  $_" } else { Write-Host "  MISSING  $_" }
    }
}
