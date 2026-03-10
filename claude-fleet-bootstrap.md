# Claude Fleet Management — Bootstrap Plan

**Context:** Large monorepo (~355 Vue files, ~1125 TS files, mixed authorship), Copilot with 125k context (40k reserved = ~85k usable), fresh sessions every time. Goal: proper harness and context management so every session starts smart.

---

## Concepts

### Area Briefs vs Worker Prompts

These are two different things:

- **Area Brief** = a map of a work area. Architecture, key files, conventions, current state. Answers: "What do I need to know about this part of the codebase?" Maintained long-term, updated as the codebase evolves.
- **Worker Prompt** = a mission order for a specific task. Goal, scope, constraints, context (pulled from briefs), harness instructions. Answers: "What am I doing right now?" Disposable — used once per task.

A worker receives **both**: the relevant brief (or excerpts from it) as context, and the worker prompt as instructions. The brief alone doesn't tell you what to do. The prompt alone doesn't tell you where you are.

### Two Memory Layers

1. **Fleet Memory** (`~/claude-fleet/`) — cross-project knowledge. Session logs, area briefs, PM state. Lives outside the repo.
2. **Repo Memory** (`.claude/memory.md` in the repo) — in-repo knowledge that travels with the code. Architecture decisions, conventions, gotchas, patterns that any session working in this repo should know. Committed to git.

Workers read BOTH. Fleet memory for task context and history. Repo memory for codebase conventions and architecture.

---

## Step 1: Create the Fleet Directory (2 mins)

On your work machine, create:

```
~/claude-fleet/
├── CLAUDE.md
├── projects/
├── sessions/
└── workers/
```

```bash
mkdir -p ~/claude-fleet/{projects,sessions,workers}
```

---

## Step 2: Create the Repo Memory File (5 mins)

In your monorepo root, create `.claude/memory.md`:

```markdown
# [Project Name] — Repo Memory

## Architecture
- [High-level architecture: monorepo structure, key packages/apps]
- [Framework: Vue 3 + TypeScript / Options API vs Composition API / etc.]
- [State management: Pinia / Vuex / etc.]
- [Build: Vite / Webpack / etc.]
- [API layer: REST / GraphQL / how frontend talks to backend]

## Conventions
- [Component naming: PascalCase, prefix patterns]
- [File structure: where components/services/composables/types live]
- [Testing: framework, naming, where tests live]
- [CSS/styling: Tailwind / SCSS / scoped styles / etc.]
- [Import conventions: aliases, barrel exports]

## Key Patterns
- [How auth works — token storage, refresh flow, guards]
- [How API calls are made — service layer, error handling]
- [Shared component patterns — props/emit conventions, slots]
- [Any code generation or scaffolding patterns]

## Known Debt / Gotchas
- [Legacy patterns still in use that shouldn't be copied]
- [Files/areas that are fragile or have known issues]
- [Mixed patterns (e.g. Options API in old files, Composition API in new)]

## Recent Decisions
- [Append architectural decisions here as they're made]
- [Format: YYYY-MM-DD — Decision — Reason]
```

**Commit this to git.** It's part of the codebase now. Every Claude session that opens the repo reads it.

---

## Step 3: Write the PM CLAUDE.md (10 mins)

Copy this template into `~/claude-fleet/CLAUDE.md` and fill in the blanks:

```markdown
# Claude Fleet PM

You are a project manager for Claude sessions working on a large monorepo.

## Your Job
- Maintain area briefs in `projects/`
- Write worker prompts with harness instructions baked in
- Read session logs to understand what previous workers did
- Never write code directly — you delegate

## The Monorepo
- Path: [REPO_PATH]
- Stack: Vue + TypeScript
- Scale: ~355 Vue files, ~1125 TS files
- Repo memory: [REPO_PATH]/.claude/memory.md
- Key areas: [list 3-5 major areas/domains/packages]
- Build: [build command]
- Test: [test command]
- Lint: [lint command]

## Context Constraints
- 125k total context, 40k reserved = ~85k usable
- Every token matters — briefs must be HIGH SIGNAL, LOW NOISE
- Workers must NOT load entire directories — target specific files
- Prefer file paths + line ranges over full file contents

## Worker Prompt Template
Every worker prompt you write MUST include:
1. GOAL — one sentence, what to achieve
2. SCOPE — exact files/directories to touch (paths, not descriptions)
3. CONTEXT — relevant brief excerpts (inline, not "go read X")
4. CONSTRAINTS — what NOT to touch, conventions to follow
5. HARNESS — memory instructions (always include these):

### Harness Instructions (include in every worker prompt)
When you complete your task:
1. Append a summary to `~/claude-fleet/sessions/YYYY-MM-DD.md`:
   - Date/time
   - What you did (1-3 bullets)
   - Files changed
   - Decisions made and why
   - Open questions / blockers
2. Update the area brief in `~/claude-fleet/projects/[area].md` if:
   - You discovered new architecture or dependencies
   - A convention changed
   - Current state of work changed
3. Update `[REPO_PATH]/.claude/memory.md` if:
   - You made an architectural decision
   - You discovered a convention not yet documented
   - You found a gotcha future sessions should know about
   - Append to "Recent Decisions" with date and reason

## Session Log Format
Workers append to `sessions/YYYY-MM-DD.md`:

### HH:MM — [area/task]
- Did: ...
- Files: ...
- Decisions: ...
- Memory updated: yes/no
- Next: ...
```

---

## Step 4: Create Area Briefs (first PM session, ~15 mins)

Open a Claude session in the fleet directory. Prompt:

> Read CLAUDE.md. I need you to create area briefs for my monorepo. The major areas are:
> - [Area 1 — e.g. "auth module", "dashboard views", "API layer"]
> - [Area 2]
> - [Area 3]
>
> For each area, create `projects/[area].md` with:
> - Purpose (1-2 sentences)
> - Key files and directories (paths only)
> - Dependencies on other areas
> - Area-specific conventions (naming, patterns, state management)
> - Current state (what's working, what's in progress, known issues)
>
> Also read the repo memory file at [REPO_PATH]/.claude/memory.md for existing conventions.
>
> Keep each brief under 100 lines. These need to fit in a worker's 85k context budget.

**Important:** You may need to point the PM at the repo. Either:
- Run it in the repo directory with the fleet CLAUDE.md symlinked, or
- Give it the repo path and let it explore with file tools

---

## Step 5: Verify Briefs (you, 5 mins, from phone)

Read each brief and the repo memory file. Fix inaccuracies. These become the source of truth for all future workers.

---

## Step 6: First Real Task (10 mins)

Open a Claude session in your repo. Paste:

> ## Context
> [Paste the relevant area brief here — just the one brief for the area you're working in]
>
> ## Task
> [What you need done]
>
> ## Harness
> When done:
> 1. Append summary to ~/claude-fleet/sessions/2026-03-10.md
> 2. Update ~/claude-fleet/projects/[area].md if architecture changed
> 3. Update .claude/memory.md if you made architectural decisions or found undocumented conventions

That's it. The brief is the context. The harness is the memory. The worker does the job AND updates both memory layers.

---

## Step 7: Iterate (ongoing)

Each morning or start of work:
1. Open PM session: "Read CLAUDE.md, all session logs since [date], and the repo memory file. What's the current state? What needs attention?"
2. PM reads the accumulated session logs + repo memory, gives you a summary
3. You pick a task, PM writes the worker prompt (with brief excerpts + harness inline)
4. You run the worker in the repo, worker does the task + updates memory
5. `git commit .claude/memory.md` when memory changes are worth keeping
6. Repeat

---

## Tips for 85k Context on a Large Monorepo

1. **Briefs are your index.** Workers read the brief to know WHERE to look, then load only those specific files. Never "explore the codebase" — that burns context.

2. **File paths > file contents in briefs.** A brief should say `src/components/Dashboard/index.vue (main layout, imports DashboardChart + DashboardTable)` not paste the whole file.

3. **Scope ruthlessly.** "Refactor the auth module" is too broad for one worker. "Update the token refresh logic in `src/auth/refresh.ts` lines 45-80" is a worker-sized task.

4. **Session logs are cumulative context.** If a worker discovers that `ComponentX` actually depends on `ServiceY` (not documented), the session log captures it, PM updates the brief next session. Knowledge compounds.

5. **Repo memory is the long-term brain.** Conventions, decisions, gotchas — things that are true regardless of what task you're doing. This file should be readable in under 2 minutes.

6. **Rotate stale briefs.** If an area changes a lot, regenerate its brief monthly. Stale briefs are worse than no briefs.

7. **Use the PM for triage, not just delegation.** "I have a bug in the dashboard. Where should I look?" — PM reads the dashboard brief, points you to likely files. Cheaper than having a worker explore.

8. **One area per worker session.** Don't cross-cut. If a task touches auth AND dashboard, split it into two worker prompts with a dependency note.

9. **Commit memory changes with the code.** `memory.md` changes in the same PR as the code changes. Keeps history in sync.

---

## The Pattern in One Sentence

**PM reads briefs → writes targeted worker prompts → workers do tasks + update both memory layers → PM reads updates → cycle continues.**

Two memory layers: fleet (cross-project, external) + repo (in-code, committed). Briefs are the map. Worker prompts are the mission. Harness instructions are the contract. Fresh sessions every time, but knowledge persists in files.
