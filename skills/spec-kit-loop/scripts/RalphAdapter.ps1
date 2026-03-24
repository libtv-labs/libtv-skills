<#
RalphAdapter.ps1 — Pluggable Ralph backend dispatcher.

Detects available backends and routes to the appropriate implementation.
Supports:
  - Ralph Orchestrator (ralph run --config hats.yml)
  - Ralph Bash (snarktank single-hat loop via ralph.sh)

Usage:
  ./RalphAdapter.ps1 -FeatureName "001-my-feature" -SpecDir "specs/001-my-feature"
                     -TasksPath "specs/001-my-feature/tasks.md"
                     -MaxIterations 20 -Backend "ralph-orchestrator"
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $FeatureName,

    [Parameter(Mandatory=$true)]
    [string] $SpecDir,

    [string] $TasksPath,

    [int]    $MaxIterations = 20,

    [ValidateSet('ralph-orchestrator', 'ralph-bash', 'auto')]
    [string] $Backend = 'auto'
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$assets = Join-Path $here "..\assets"

function Test-Command($cmd) {
    try { $null = Get-Command $cmd -ErrorAction Stop; return $true } catch { return $false }
}

function Get-AvailableBackend {
    if (Test-Command 'ralph') {
        # Ralph Orchestrator CLI is available
        return 'ralph-orchestrator'
    }
    # Fallback: check for snarktank Ralph bash scripts in project
    $ralphSh = Join-Path $SpecDir "..\scripts\ralph\ralph.sh"
    if (Test-Path $ralphSh) {
        return 'ralph-bash'
    }
    return $null
}

# Resolve backend
if ($Backend -eq 'auto') {
    $Backend = Get-AvailableBackend
    if (-not $Backend) {
        Write-Host "ERROR: No Ralph backend available. Install Ralph Orchestrator:" -ForegroundColor Red
        Write-Host "  npm install -g @ralph-orchestrator/ralph-cli" -ForegroundColor Gray
        Write-Host "Or copy snarktank Ralph scripts to scripts/ralph/ralph.sh" -ForegroundColor Gray
        exit 1
    }
    Write-Host "Auto-detected backend: $Backend" -ForegroundColor Cyan
}

# Tasks path defaults
if (-not $TasksPath) {
    $TasksPath = Join-Path $SpecDir "tasks.md"
}

switch ($Backend) {
    'ralph-orchestrator' {
        Write-Host "Using Ralph Orchestrator backend" -ForegroundColor Green

        # Generate hats.yml for this feature
        $hatsYml = @"
# Ralph Orchestrator config — generated for feature: $FeatureName
event_loop:
  starting_event: "task.start"
  max_iterations: $MaxIterations

hats:
"@

        # Load and embed hat configs from assets
        $plannerHat = Get-Content (Join-Path $assets "ralph-orchestrator\hats\planner-hat.yml") -Raw
        $builderHat = Get-Content (Join-Path $assets "ralph-orchestrator\hats\builder-hat.yml") -Raw
        $reviewerHat = Get-Content (Join-Path $assets "ralph-orchestrator\hats\reviewer-hat.yml") -Raw

        $hatsYml += "`n  planner:"
        $plannerHat -split "`n" | ForEach-Object { $hatsYml += "`n    $_" }
        $hatsYml += "`n  builder:"
        $builderHat -split "`n" | ForEach-Object { $hatsYml += "`n    $_" }
        $hatsYml += "`n  reviewer:"
        $reviewerHat -split "`n" | ForEach-Object { $hatsYml += "`n    $_" }

        # Write generated config next to spec dir
        $outYml = Join-Path $SpecDir "ralph-loop.yml"
        $hatsYml | Out-File -FilePath $outYml -Encoding UTF8

        Write-Host "Generated Ralph config: $outYml" -ForegroundColor Gray

        # Build prompt files for Ralph
        $promptsDir = Join-Path $assets "prompts"
        $env:RALPH_PROMPT_PLANNER  = Get-Content (Join-Path $promptsDir "planner-prompt.md") -Raw
        $env:RALPH_PROMPT_BUILDER  = Get-Content (Join-Path $promptsDir "builder-prompt.md") -Raw
        $env:RALPH_PROMPT_REVIEWER = Get-Content (Join-Path $promptsDir "reviewer-prompt.md") -Raw

        # Run Ralph Orchestrator
        Write-Host "Starting Ralph loop (max_iterations=$MaxIterations)..." -ForegroundColor Cyan
        ralph run --config $outYml
    }

    'ralph-bash' {
        Write-Host "Using Ralph Bash backend (snarktank pattern)" -ForegroundColor Yellow

        $ralphSh = Join-Path $SpecDir "..\scripts\ralph\ralph.sh"
        if (-not (Test-Path $ralphSh)) {
            Write-Host "ERROR: ralph.sh not found at $ralphSh" -ForegroundColor Red
            Write-Host "Copy snarktank Ralph scripts to scripts/ralph/ first." -ForegroundColor Red
            exit 1
        }

        Write-Host "Starting Ralph bash loop (max_iterations=$MaxIterations)..." -ForegroundColor Cyan
        & $ralphSh $MaxIterations
    }
}
