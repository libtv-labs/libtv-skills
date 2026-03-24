<#
detect-env.ps1 — Probe the current machine and return the available environment tier.

Tier A: Everything set up (specify + git + Claude Code + ralph CLI)
Tier B: uv + git present, spec-kit/Claude/Ralph need installation
Tier C: Minimal — install uv, then chain to Tier B

Returns a tier report object with:
  .Tier          — A, B, or C
  .Checks        — hashtable of individual check results
  .Missing       — array of missing components
  .BootstrapPath — the tier bootstrap script to run
#>

param(
    [switch] $Verbose
)

$checks = @{}

function Test-Command($cmd) {
    try {
        $null = Get-Command $cmd -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Tier A checks
$checks['git']           = Test-Command 'git'
$checks['specify']       = Test-Command 'specify'
$checks['claude']        = Test-Command 'claude'
$checks['ralph']         = Test-Command 'ralph'

# Tier B pre-reqs
$checks['uv']            = Test-Command 'uv'
$checks['npm']            = Test-Command 'npm'

# Determine tier
if ($checks['git'] -and $checks['specify'] -and $checks['claude'] -and $checks['ralph']) {
    $tier = 'A'
} elseif ($checks['uv'] -and $checks['git']) {
    $tier = 'B'
} else {
    $tier = 'C'
}

# Collect missing components per tier
$missing = @()
if (-not $checks['git'])           { $missing += 'git' }
if (-not $checks['uv'])            { $missing += 'uv' }
if (-not $checks['npm'])           { $missing += 'npm' }
if (-not $checks['specify'])       { $missing += 'specify-cli' }
if (-not $checks['claude'])        { $missing += 'Claude Code' }
if (-not $checks['ralph'])         { $missing += 'Ralph Orchestrator CLI' }

$result = @{
    Tier     = $tier
    Checks   = $checks
    Missing  = $missing
}

if ($Verbose) {
    Write-Host "=== Environment Detection ===" -ForegroundColor Cyan
    foreach ($k in $checks.Keys) {
        $val = $checks[$k]
        $color = if ($val) { 'Green' } else { 'Red' }
        Write-Host "  $($k): " -NoNewline -ForegroundColor Gray
        Write-Host "$val" -ForegroundColor $color
    }
    Write-Host ""
    Write-Host "Tier: " -NoNewline -ForegroundColor Gray
    Write-Host $tier -ForegroundColor Yellow
    Write-Host "Missing: " -NoNewline -ForegroundColor Gray
    Write-Host "$($missing -join ', ')" -ForegroundColor $(if ($missing.Count -eq 0) { 'Green' } else { 'Yellow' })
}

# Output tier as exit code / structured data
switch ($tier) {
    'A' { $result.BootstrapPath = $null }
    'B' { $result.BootstrapPath = 'TierB' }
    'C' { $result.BootstrapPath = 'TierC' }
}

# Also output as JSON for machine parsing
$json = $result | ConvertTo-Json -Compress
Write-Output $json

return $result
