# Ralph Orchestrator Backend Adapter

RalphAdapter.ps1 selects Ralph Orchestrator when the `ralph` CLI is available. This document details how the adapter integrates with Ralph Orchestrator's hat system.

## Ralph Orchestrator Architecture

Ralph Orchestrator is a Rust + Node.js application that:
1. Loads a `hats.yml` config describing hats, triggers, and events
2. Runs an event loop driven by hat publishes
3. Spawns Claude Code (or other backend CLI) per hat activation
4. Shows a TUI with iteration progress, active hat, and output

Key concepts:
- **Hat**: A named persona with `triggers` (events that activate it), `publishes` (events it emits), and `instructions`
- **Event**: A string signal (`task.start`, `plan.ready`, etc.) that routes between hats
- **Config**: `hats.yml` — the complete orchestration blueprint

## How the Adapter Connects

```
RalphAdapter.ps1
    │
    ├── Reads hat YAML templates from assets/ralph-orchestrator/hats/
    ├── Reads hat prompts from assets/prompts/*.md
    ├── Generates per-feature ralph-loop.yml
    │       (embeds prompts as Ralph env vars or inline instructions)
    │
    └── Executes: ralph run --config specs/{feature}/ralph-loop.yml
```

Ralph Orchestrator natively supports env var interpolation in hat instructions, so the adapter passes hat prompts as `RALPH_PROMPT_*` environment variables.

## Ralph Orchestrator Installation

```powershell
npm install -g @ralph-orchestrator/ralph-cli
```

Verify:
```powershell
ralph --version
ralph doctor   # validates environment
```

## Ralph CLI Subcommands Used

| Command | Use |
|---------|-----|
| `ralph init --backend claude` | Initialize a project with default Ralph config |
| `ralph run --config <yml>` | Run the hat loop from a config file |
| `ralph run --continue` | Resume an interrupted session |
| `ralph doctor` | Validate prerequisites (auth, CLI tools) |
| `ralph web` | Start web dashboard (optional, for monitoring) |

## hats.yml Structure

Generated per-feature from the adapter. Template sources in `assets/ralph-orchestrator/hats/`:

```yaml
event_loop:
  starting_event: "task.start"
  max_iterations: 20

hats:
  planner:
    name: "Planner"
    triggers: ["task.start"]
    publishes: ["plan.ready", "plan.blocked"]
    instructions: |
      # Loaded from RALPH_PROMPT_PLANNER env var or inline
      ...
  builder:
    name: "Builder"
    triggers: ["plan.ready"]
    publishes: ["build.done", "build.retry"]
    instructions: |
      ...
  reviewer:
    name: "Reviewer"
    triggers: ["build.done"]
    publishes: ["task.start", "loop.complete"]
    instructions: |
      ...
```

## Backend Fallback: snarktank Ralph

If `ralph` CLI is not found, RalphAdapter falls back to the snarktank Ralph bash pattern:

- Loop script: `scripts/ralph/ralph.sh`
- Single hat (no event system) — just spawn Claude Code, implement next unchecked task, commit, repeat
- `prd.json` style tracking (simpler than Ralph Orchestrator's event system)
- Limited compared to Orchestrator but requires no npm install

Set `RALPH_BACKEND=ralph-bash` to force fallback.

## MCP Server Mode

Ralph Orchestrator can also run as an MCP server:

```powershell
ralph mcp serve --workspace-root /path/to/repo
```

This allows Claude Desktop or other MCP clients to interact with Ralph programmatically. The skill does not currently use MCP mode but it is available for advanced integrations.

## Key Limitations

1. **Ralph Orchestrator >= 0.8 required** for hat env var interpolation
2. **Single workspace root** per Ralph MCP/server instance — multi-repo projects need one instance per repo
3. **Backend CLI must be authenticated** — run `claude auth` before first use
4. **Hat prompts are Claude Code prompt files** — they use Claude Code's `/prompt` format, not generic text
