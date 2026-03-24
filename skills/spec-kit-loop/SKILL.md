---
name: spec-kit-loop
description: Spec-Driven Development autonomous loop using Ralph orchestration with a three-hat system (planner/builder/reviewer). Triggers when the agent encounters /speckit.implement_loop or needs to autonomously execute spec-kit tasks with quality gates until all work is complete. Use for: (1) running an autonomous implementation loop from a spec-kit feature spec, (2) replacing /speckit.implement with a self-loop that enforces SDD constitution gates, (3) continuous implementation with built-in typecheck/test quality enforcement.
---

# spec-kit-loop

## When to Use This Skill

- User says "implement_loop", "run the spec loop", "Ralph implement", "/speckit.implement_loop"
- User wants spec-kit feature tasks executed autonomously until all tasks are complete
- Replacing `/speckit.implement` with a loop that enforces SDD constitution quality gates
- Multi-iteration implementation where each work unit gets quality checks before advancing

## Quick Start

> **New here?** Choose your agent:
> - [Claude Code setup](references/setup-claude-code.md)
> - [OpenClaw agent setup](references/setup-openclaw.md)

Both guides cover: installing the skill, bootstrapping the environment, and running your first loop.

```
/speckit.implement_loop --feature 001-photo-albums --max-iterations 20
```

The skill will:
1. Detect environment tier (A/B/C)
2. Bootstrap missing components if needed
3. Run the Ralph three-hat loop until all tasks are done or max-iterations reached
4. Report: tasks completed, iterations used, lessons learned

## Bootstrapping

See [references/bootstrap-tiers.md](references/bootstrap-tiers.md) for full tier logic.

Summary:
- **Tier A**: Host fully set up — just verify with `specify check`
- **Tier B**: `uv` + `git` available, bootstrap spec-kit + Claude Code + Ralph CLI
- **Tier C**: Blank machine — install `uv`, then Tier B chain

Run bootstrap manually:
```powershell
# Detect tier
./scripts/detect-env.ps1

# Full bootstrap
./scripts/bootstrap.ps1
```

## Hat System

Three hats coordinate via Ralph Orchestrator events:

| Hat | Role | Key Output |
|-----|------|------------|
| **planner** | Pre-flight readiness, Phase -1 gate checks | Emits `plan.ready` or `plan.blocked` |
| **builder** | Implements ONE work unit, writes tests first | Emits `build.done` or `build.retry` |
| **reviewer** | Quality gates (typecheck, tests), commits, advances state | Emits `task.start` (next) or `loop.complete` |

See [references/hats.md](references/hats.md) for full hat definitions and event contracts.

## Backends

**Primary**: Ralph Orchestrator (Rust/Node, hat-based, multi-backend)
- Installed via: `npm install -g @ralph-orchestrator/ralph-cli`
- Configured via: `assets/ralph-orchestrator/hats/*.yml`

**Fallback**: snarktank Ralph (bash loop, single-hat, simpler)
- No CLI — uses `ralph.sh` copied into project
- Set `RALPH_BACKEND=ralph-bash` to force fallback

Backend selection is automatic via `RalphAdapter.ps1`:
```powershell
./scripts/RalphAdapter.ps1 -FeatureName "001-my-feature" -SpecDir "specs/001-my-feature"
```

See [references/backend-ralph-orchestrator.md](references/backend-ralph-orchestrator.md).

## Command Reference

```
/speckit.implement_loop [--feature <name>] [--max-iterations N] [--backend ralph-orchestrator|ralph-bash]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--feature` | Auto-detected | Feature name from `SPECIFY_FEATURE` env or git branch `NNN-*` |
| `--max-iterations` | 20 | Safety cap on loop iterations |
| `--backend` | `ralph-orchestrator` | Ralph backend to use |

## Key Files

| Path | Purpose |
|------|---------|
| `scripts/detect-env.ps1` | Detects tier (A/B/C) and reports what's missing |
| `scripts/bootstrap.ps1` | Provisions spec-kit + Claude Code + Ralph CLI |
| `scripts/RalphAdapter.ps1` | Backend dispatcher — routes to Orchestrator or Bash Ralph |
| `references/hats.md` | Hat definitions, triggers, publishes, checks |
| `references/bootstrap-tiers.md` | Detailed tier detection and bootstrap logic |
| `references/backend-ralph-orchestrator.md` | Ralph Orchestrator adapter details |
| `assets/ralph-orchestrator/hats/` | Ralph Orchestrator hat YAML configs |
| `assets/prompts/` | Hat instruction prompts read by Claude Code each iteration |
| `specs/{feature}/progress.md` | Append-only log of iterations, lessons, blockers |
