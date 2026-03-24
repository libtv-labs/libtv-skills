# Quick Start — spec-kit-loop with Claude Code

## Prerequisites

- Claude Code installed: `npm install -g @anthropic-ai/claude-code`
- Authenticated: `claude auth` (or `claude login`)
- Git repository initialized: `git init` (or existing repo)
- uv installed (for spec-kit bootstrap): `irm https://astral.sh/uv/install.ps1 | iex`

---

## Step 1 — Install the Skill

Copy the skill directory into Claude Code's skills folder:

```bash
# macOS / Linux
cp -r /path/to/spec-kit-loop ~/.claude/skills/spec-kit-loop

# Windows (PowerShell)
Copy-Item -Recurse "G:\dev\projects\agent-skills-collections\spec-kit-loop" `
  "$env:USERPROFILE\.claude\skills\spec-kit-loop"
```

Verify it's installed:

```
claude
> /skills list
# You should see: spec-kit-loop
```

---

## Step 2 — Initialize a spec-kit Project

If you don't have one yet:

```bash
mkdir my-feature-project
cd my-feature-project
git init

# Install spec-kit CLI if missing
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Initialize with Claude Code as the AI backend
specify init . --ai claude --skip-tls
```

This creates the `.claude/` command structure. The `/speckit.*` commands become available in Claude Code.

---

## Step 3 — Bootstrap the Environment

```bash
# Inside your spec-kit project
./spec-kit-loop/scripts/bootstrap.ps1
```

Or from Claude Code terminal:

```
/shell Run bootstrap.ps1 to provision spec-kit and Ralph
```

The bootstrap detects your tier and installs only what's missing.

---

## Step 4 — Run Your First Feature Loop

### Option A — Via `/speckit.specify` then `/speckit.implement_loop`

```
/speckit.specify Build a photo album app with drag-and-drop reordering
/specifit.plan   # generates plan.md + tasks.md
/speckit.implement_loop --max-iterations 20
```

### Option B — Direct loop on existing spec

```
/speckit.implement_loop --feature 001-photo-albums --max-iterations 20
```

Ralph will loop through planner → builder → reviewer hats until all tasks are done.

---

## Available Commands in Claude Code

```
/speckit.specify        Describe a feature → generates spec.md
/speckit.plan           Create implementation plan from spec
/speckit.tasks          Generate task list from plan
/speckit.implement      Single-pass implementation
/speckit.implement_loop Three-hat Ralph loop (planner/builder/reviewer)

/speckit.clarify        Ask clarifying questions on a spec
/speckit.analyze        Cross-artifact consistency check
```

---

## Troubleshooting

**`specify: command not found`**
```powershell
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
```

**`claude: command not found`**
```bash
npm install -g @anthropic-ai/claude-code
claude auth
```

**Ralph loop exits immediately with "no tasks"**
Ensure you're on a feature branch with `tasks.md` in `specs/{feature}/`:
```bash
git checkout -b 001-my-feature
ls specs/001-my-feature/tasks.md
```

**Max iterations reached**
Increase the limit and resume:
```
/speckit.implement_loop --feature 001-my-feature --max-iterations 50
```
