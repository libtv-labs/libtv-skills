# Quick Start — spec-kit-loop with OpenClaw Agent

This guide covers installing the skill into an OpenClaw agent so it's available in chat sessions.

---

## Prerequisites

- OpenClaw gateway running: `openclaw gateway status`
- Access to the agent's workspace or skill directory

---

## Step 1 — Locate Your Agent's Skill Directory

OpenClaw agent skills are installed per-agent. The default location:

```
~/.agents/skills/
```

For **named agents**, skills are in:

```
~/.agents/{agent-id}/skills/
```

Check where your current agent's skills live:

```
openclaw skills list
```

Or look at the `skills` section in your `AGENTS.md` at the workspace root.

---

## Step 2 — Install the Skill

Copy the skill directory into the agent's skills folder:

```powershell
# Windows
$skillSrc = "G:\dev\projects\agent-skills-collections\spec-kit-loop"
$skillDest = "$env:USERPROFILE\.agents\skills\spec-kit-loop"
Copy-Item -Recurse $skillSrc $skillDest
```

```bash
# macOS / Linux
cp -r /path/to/spec-kit-loop ~/.agents/skills/spec-kit-loop
```

Or link it (recommended — keeps skill in one place, usable by multiple agents):

```bash
# macOS / Linux
ln -s /path/to/spec-kit-loop ~/.agents/skills/spec-kit-loop
```

---

## Step 3 — Verify the Skill Loads

In an OpenClaw chat session, trigger the skill:

```
Use the spec-kit-loop skill to run an implementation loop on feature 001-my-feature
```

OpenClaw reads the `name` and `description` from the skill's `SKILL.md` frontmatter to determine when to activate it. The skill is active when the agent mentions `/speckit.implement_loop`, `implement_loop`, `Ralph loop`, or `spec-kit loop`.

---

## Step 4 — Bootstrap the Environment (First Use)

On a fresh machine, the skill's `bootstrap.ps1` will self-provision. To run it manually:

```bash
# From the agent's working directory
./.agents/skills/spec-kit-loop/scripts/bootstrap.ps1
```

Or trigger via chat once the skill is loaded:

```
Run the bootstrap script from the spec-kit-loop skill
```

The skill reports the detected tier and installs missing components automatically.

---

## Step 5 — Run the Loop

Once bootstrapped, trigger the loop via chat:

```
Run /speckit.implement_loop on feature 001-my-feature, max 20 iterations
```

The agent will:
1. Load the skill's hat prompts and Ralph adapter
2. Detect the Ralph backend
3. Generate the per-feature `ralph-loop.yml`
4. Start the three-hat loop

---

## For OpenClaw Developers — Adding Skill Metadata

If you want the skill to appear in OpenClaw's skill registry, add it to your agent's `AGENTS.md` or skill config:

```markdown
## Skills

- spec-kit-loop  ~/.agents/skills/spec-kit-loop
```

Or via the CLI:

```bash
openclaw skills add spec-kit-loop --path ~/.agents/skills/spec-kit-loop
```

---

## File Locations Reference

| File | Purpose |
|------|---------|
| `~/.agents/skills/spec-kit-loop/SKILL.md` | Skill entry point — loaded when triggered |
| `~/.agents/skills/spec-kit-loop/scripts/bootstrap.ps1` | Self-provision spec-kit + Claude + Ralph |
| `~/.agents/skills/spec-kit-loop/scripts/RalphAdapter.ps1` | Backend dispatcher |
| `~/.agents/skills/spec-kit-loop/references/*.md` | Detailed reference docs |
| `~/.agents/skills/spec-kit-loop/assets/prompts/*.md` | Hat instruction prompts |

---

## Troubleshooting

**Skill not activating**
- Check the skill directory is in `~/.agents/skills/`
- Verify `SKILL.md` has valid YAML frontmatter with `name` and `description`
- Run `openclaw skills list` to confirm it appears

**Bootstrap fails on Windows**
- Ensure PowerShell execution policy allows scripts: `Set-ExecutionPolicy -RemoteSigned`
- Run as administrator if needed: `.\bootstrap.ps1`

**Ralph backend not found**
```
# Install Ralph Orchestrator CLI
npm install -g @ralph-orchestrator/ralph-cli

# Verify
ralph --version
```

**Agent loops but nothing happens**
- Ensure you're in a spec-kit project (`specs/{feature}/tasks.md` exists)
- Check `progress.md` in the feature directory for iteration history
