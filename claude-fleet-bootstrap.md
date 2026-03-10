# Claude Fleet Management — Bootstrap Plan

**Context:** Large monorepo (~355 Vue files, ~1125 TS files, mixed authorship), Copilot with 125k context (40k reserved = ~85k usable), fresh sessions every time. Goal: proper harness and context management so every session starts smart.

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

## Step 2: Write the PM CLAUDE.md (10 mins)

Copy this template into `~/claude-fleet/CLAUDE.md` and fill in the blanks:

```markdown
# Claude Fleet PM

You are a project manager for Claude sessions working on a large monorepo.

## Your Job
- Maintain project/area briefs in `projects/`
- Write worker prompts with harness instructions baked in
- Read session logs to understand what previous workers did
- Never write code directly — you delegate

## The Monorepo
- Path: [REPO_PATH]
- Stack: Vue + TypeScript
- Scale: ~355 Vue files, ~1125 TS files
- Key areas: [list 3-5 major areas/domains/packages]
- Build: [build tool / commands]
- Test: [test commands]

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
5. HARNESS — memory instructions (see below)

## Harness Instructions (copy into every worker prompt)
When you complete your task:
1. Append a summary to `~/claude-fleet/sessions/YYYY-MM-DD.md`:
   - Date/time
   - What you did (1-3 bullets)
   - Files changed
   - Decisions made and why
   - Open questions / blockers
2. Update the relevant project brief in `~/claude-fleet/projects/` if:
   - You discovered something about the architecture
   - A convention changed
   - New dependencies were added
   - The current state of work changed

## Session Log Format
Workers append to `sessions/YYYY-MM-DD.md`:
```
### HH:MM — [area/task]
- Did: ...
- Files: ...
- Decisions: ...
- Next: ...
```
```

---

## Step 3: Create Area Briefs (first PM session, ~15 mins)

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
> - Conventions I should know (naming, patterns, state management)
> - Known debt / gotchas
>
> Keep each brief under 100 lines. These need to fit in a worker's context.

**Important:** You may need to point the PM at the repo. Either:
- Run it in the repo directory with the fleet CLAUDE.md symlinked, or
- Give it the repo path and let it explore with file tools

---

## Step 4: Verify Briefs (you, 5 mins, from phone)

Read each brief. Fix inaccuracies. These become the source of truth. If a brief is wrong, every worker that reads it will be wrong.

---

## Step 5: First Real Task (10 mins)

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

That's it. The brief is the context. The harness is the memory. The worker does the job AND updates the shared state.

---

## Step 6: Iterate (ongoing)

Each morning or start of work:
1. Open PM session: "Read CLAUDE.md and all session logs since [date]. What's the current state? What needs attention?"
2. PM reads the accumulated session logs, gives you a summary
3. You pick a task, PM writes the worker prompt
4. You run the worker, worker updates the logs
5. Repeat

---

## Tips for 85k Context on a Large Monorepo

1. **Briefs are your index.** Workers read the brief to know WHERE to look, then load only those specific files. Never "explore the codebase" — that burns context.

2. **File paths > file contents in briefs.** A brief should say `src/components/Dashboard/index.vue (main layout, imports DashboardChart + DashboardTable)` not paste the whole file.

3. **Scope ruthlessly.** "Refactor the auth module" is too broad for one worker. "Update the token refresh logic in `src/auth/refresh.ts` lines 45-80" is a worker-sized task.

4. **Session logs are cumulative context.** If a worker discovers that `ComponentX` actually depends on `ServiceY` (not documented in the brief), the session log captures it, and next PM session updates the brief. Knowledge compounds.

5. **Rotate stale briefs.** If an area changes a lot, regenerate its brief monthly. Stale briefs are worse than no briefs.

6. **Use the PM for triage, not just delegation.** "I have a bug in the dashboard. Where should I look?" — PM reads the dashboard brief, points you to likely files. Cheaper than having a worker explore.

7. **One area per worker session.** Don't cross-cut. If a task touches auth AND dashboard, split it into two worker prompts with a dependency note.

---

## The Pattern in One Sentence

**PM reads briefs → writes targeted worker prompts → workers do tasks + update memory → PM reads updates → cycle continues.**

The filesystem is the message bus. The briefs are the shared memory. The harness instructions are the contract. Fresh sessions every time, but knowledge persists in files.
