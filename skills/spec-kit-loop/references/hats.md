# Three-Hat System — Hat Definitions & Event Contracts

The loop implements a **planner → builder → reviewer** three-hat cycle driven by Ralph Orchestrator events.

## Event Flow

```
Ralph starts
    │
    ▼
[planner hat]  ──(plan.ready)──▶  [builder hat]  ──(build.done)──▶  [reviewer hat]
    │                                    │                              │
    │                                    │                              │
    │                                    ▼                              │
    │                              (build.retry)◀───────────────────── │
    │                                   │                               │
    │                                   └───────────────────────────────┘
    │
    ▼
(review passes) ──(task.start)──▶  back to [builder hat] for next task
(review passes + no tasks left) ──(loop.complete)──▶ Ralph exits
```

## Hat: planner

**Purpose**: Pre-flight readiness check before each build iteration.

```
Triggers:   task.start
Publishes:  plan.ready | plan.blocked
```

**Reads**:
- `specs/{feature}/plan.md`
- `specs/{feature}/data-model.md`
- `specs/{feature}/contracts/`
- `specs/{feature}/progress.md` (prior iteration learnings)

**Checks performed** (SDD Phase -1 gates):

| Gate | Rule | Fails if |
|------|------|---------|
| Simplicity | ≤3 projects | >3 projects |
| Future-proofing | No "might need" features | Speculative items present |
| Framework directness | Using framework features directly | Custom abstractions wrapping framework |
| Contract readiness | All contracts in `contracts/` exist | Missing contract files |
| Clarification resolved | No `[NEEDS CLARIFICATION]` markers | Any unresolved marker |

**On pass**: emits `plan.ready` with context on current task
**On block**: emits `plan.blocked` listing specific unresolved items

## Hat: builder

**Purpose**: Implements exactly ONE work unit per invocation. Enforces test-first (SDD Article IX).

```
Triggers:   plan.ready
Publishes:  build.done | build.retry
```

**Reads**:
- `specs/{feature}/tasks.md` — picks first unchecked `[ ]` task
- `specs/{feature}/progress.md` — prior learnings to avoid repeating mistakes
- Hat prompt from `assets/prompts/builder-prompt.md`

**Contract**:
1. Write failing test first (must fail before any implementation code)
2. Write minimal implementation to pass the test
3. Run quality checks (typecheck, linter)
4. Mark task `[x]` only after checks pass

**On success**: emits `build.done`
**On failure**: emits `build.retry` with error context appended to `progress.md`

## Hat: reviewer

**Purpose**: Quality enforcement, state advancement, and loop termination.

```
Triggers:   build.done
Publishes:  task.start | loop.complete
```

**Checks**:
1. Typecheck passes (e.g., `tsc --noEmit`, `cargo check`)
2. All contract tests pass
3. All integration tests pass
4. No remaining `[ ]` tasks in `tasks.md`

**On all checks pass**:
- Marks task `[x]` in `tasks.md` (already done by builder, but confirms)
- Commits with message: `feat({feature}): complete task N — {task description}`
- Appends iteration summary to `progress.md`
- If more tasks remain → emits `task.start`
- If no tasks remain → emits `loop.complete`

**On any check fail**:
- Appends failure details to `progress.md`
- Emits `build.retry` (loops back to builder with error context)

## progress.md Format

Append-only log. Created on first iteration.

```markdown
# Progress — {feature-name}

## Iteration N — {ISO timestamp}
### Hat: {planner|builder|reviewer}
### Task: {task description from tasks.md}
### Result: success | failure | blocked
### Files changed: {list}
### Lessons:
- {pattern or convention discovered}
### Blockers:
- {if any — specific clarification needed}
```

Builder reads `progress.md` on start to avoid repeating prior mistakes.
Reviewer writes the result after each iteration.

## Feature Context Files

RalphAdapter generates these per-feature files passed as Ralph context:

| Variable | File |
|----------|------|
| `FEATURE_DIR` | `specs/{feature}/` |
| `SPEC_FILE` | `specs/{feature}/spec.md` |
| `PLAN_FILE` | `specs/{feature}/plan.md` |
| `TASKS_FILE` | `specs/{feature}/tasks.md` |
| `DATA_MODEL` | `specs/{feature}/data-model.md` |
| `PROGRESS_FILE` | `specs/{feature}/progress.md` |
