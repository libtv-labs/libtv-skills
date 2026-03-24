<#
bootstrap.ps1 — Self-provision spec-kit, Claude Code, and Ralph Orchestrator CLI.

Detects current tier via detect-env.ps1, then executes only the missing steps.
Safe to re-run — each step is idempotent where possible.
#>

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]] $RemainingArgs
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== spec-kit-loop bootstrap ===" -ForegroundColor Cyan

# Run detection
Write-Host "`n[1/2] Detecting environment..." -ForegroundColor Gray
$envResult = & "$here\detect-env.ps1" -Verbose

if ($envResult.Missing.Count -eq 0 -and $envResult.Tier -eq 'A') {
    Write-Host "Environment is fully set up (Tier A). Nothing to bootstrap." -ForegroundColor Green
    Write-Host "Run /speckit.implement_loop to start the implementation loop." -ForegroundColor Gray
    return
}

# ─── Tier C: Install uv first ───────────────────────────────────────────────
if ($envResult.Tier -eq 'C') {
    Write-Host "`n[Bootstrap/Tier C] Installing uv..." -ForegroundColor Yellow
    if (-not (Test-Command 'uv')) {
        Write-Host "  Downloading uv installer..." -ForegroundColor Gray
        # Windows PowerShell bootstrap
        irm https://astral.sh/uv/install.ps1 | iex
        # Refresh PATH for current session
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Host "  uv installed." -ForegroundColor Green
    } else {
        Write-Host "  uv already present." -ForegroundColor Green
    }
}

# ─── Tier B: Install spec-kit, Claude Code, Ralph CLI ───────────────────────
Write-Host "`n[Bootstrap/Tier B] Provisioning missing components..." -ForegroundColor Yellow

$missing = $envResult.Missing

if ('npm' -in $missing) {
    Write-Host "  npm is required but missing. Please install Node.js from https://nodejs.org" -ForegroundColor Red
    Write-Host "  Then re-run this bootstrap script." -ForegroundColor Red
    exit 1
}

if ('specify-cli' -in $missing) {
    Write-Host "  Installing spec-kit (specify-cli)..." -ForegroundColor Gray
    uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
    Write-Host "  specify-cli installed." -ForegroundColor Green
}

if ('Claude Code' -in $missing) {
    Write-Host "  Installing Claude Code..." -ForegroundColor Gray
    npm install -g @anthropic-ai/claude-code
    Write-Host "  Claude Code installed." -ForegroundColor Green
}

if ('Ralph Orchestrator CLI' -in $missing) {
    Write-Host "  Installing Ralph Orchestrator CLI..." -ForegroundColor Gray
    npm install -g @ralph-orchestrator/ralph-cli
    Write-Host "  Ralph Orchestrator CLI installed." -ForegroundColor Green
}

# ─── Verify ─────────────────────────────────────────────────────────────────
Write-Host "`n[2/2] Verifying installation..." -ForegroundColor Gray
$verify = & "$here\detect-env.ps1"

if ($verify.Tier -eq 'A') {
    Write-Host "`nBootstrap complete. Environment is Tier A." -ForegroundColor Green
    Write-Host "Run /speckit.implement_loop to start." -ForegroundColor Gray
} else {
    Write-Host "`nBootstrap incomplete. Missing: $($verify.Missing -join ', ')" -ForegroundColor Red
    Write-Host "Please address the above and re-run bootstrap." -ForegroundColor Red
    exit 1
}
