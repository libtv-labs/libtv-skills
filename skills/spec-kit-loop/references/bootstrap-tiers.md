# Bootstrap Tiers

The skill targets three environment tiers. Detection runs before any bootstrap action.

## Tier Detection Logic

```
detect-env.ps1 checks each component:
  git, specify, claude, ralph    (Tier A requirements)
  uv, npm                        (Tier B+ requirements)
```

Tier is the **lowest** available:
- Tier **A** → everything present, ready to run
- Tier **B** → `uv` + `git` available, bootstrap spec-kit + Claude + Ralph
- Tier **C** → minimal, install `uv` first then chain to Tier B

## Tier A — Fully Set Up

```powershell
# Just verify
specify check
./RalphAdapter.ps1 -FeatureName "001-my-feature" -SpecDir "specs/001-my-feature"
```

## Tier B — uv + git available

Installs spec-kit, Claude Code, Ralph Orchestrator CLI in sequence:

```powershell
# 1. Install spec-kit (Python CLI via uv)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# 2. Initialize project (if not already)
specify init . --ai claude --skip-tls

# 3. Install Claude Code
npm install -g @anthropic-ai/claude-code

# 4. Install Ralph Orchestrator CLI
npm install -g @ralph-orchestrator/ralph-cli

# 5. Verify
specify check
```

## Tier C — Blank Machine

Install `uv` first, then chain to Tier B:

```powershell
# Windows
irm https://astral.sh/uv/install.ps1 | iex

# Linux/macOS
curl -LsSf https://astral.sh/uv/install.sh | sh

# Then re-run bootstrap — will now be Tier B and continue
./bootstrap.ps1
```

## Component Checklist

| Component | Source | Tier |
|-----------|--------|------|
| `git` | System package manager | A |
| `uv` | https://astral.sh/uv/install.ps1 | B |
| `npm` | nodejs.org or system package manager | B |
| `specify-cli` | `uv tool install specify-cli --from git+...` | B |
| `Claude Code` | `npm install -g @anthropic-ai/claude-code` | B |
| `Ralph Orchestrator CLI` | `npm install -g @ralph-orchestrator/ralph-cli` | B |

## Running Bootstrap

```powershell
# Detect current tier
./scripts/detect-env.ps1 -Verbose

# Run full bootstrap (detects tier, runs only needed steps)
./scripts/bootstrap.ps1
```

## CI / Headless Environments

For Tier B/C in CI, set required env vars to skip interactive prompts:

```powershell
$env:GH_TOKEN = "your-github-token"
./bootstrap.ps1
```

`specify init` accepts `--github-token` and `--skip-tls` for CI use.
