---
name: viv-load-context
description: Load deep context about a topic, module, or subsystem before high-stakes work. Use when the user asks to "load into context everything about X", "remind me how X works", says "I want to know the ins and outs of X", or signals an upcoming risky change (for example, "production breaking", "be thorough"). Drives a systematic sweep of source code, specs, related repos, postmortems, repo-level instructions (AGENTS.md or CLAUDE.md), and persistent memory — then surfaces a structured map of what was loaded so the user can correct gaps before action begins.
---

# Load Context

Pre-flight mode for risky tasks. The goal is not to research and report — it is to absorb a subsystem deeply enough that the *next* action runs from understanding, not guesses. The user invokes this when the cost of misunderstanding is high (production-breaking changes, refactors across service boundaries, edits in areas that have burned the project before).

## Workflow

1. **Identify the topic.** Extract the noun phrase from the request ("the auth system", "billing", "the picker component"). If genuinely ambiguous between two subsystems, ask which — but do not ask if the topic is clear.
2. **Anchor on {{instruction_file}} first.** Read the repo's {{instruction_file}} (and any nested ones in relevant subdirectories) before anything else. It encodes the repo-specific conventions, landmines, and pointers — including where this repo keeps specs, postmortems, sibling repos, and other context sources. Let it guide the rest of the sweep.
3. **Map the surface area.** For breadth, when the topic touches many directories, {{start_search_agent}}. But a search gives excerpts, not full reads, so it cannot finish the job.
4. **Read canonical files end-to-end.** Use {{read_tool}} on the primary types, modules, hooks, configs, and specs, in full. Do not read a part of a file unless the file exceeds 2000 lines.
5. **Trace one or two representative flows.** Pick a real entry point and follow it end-to-end (for example, user action → handler → storage, or CLI input → core logic → output). Naming a flow that you traced is proof that you loaded it. Naming a file that you opened is not.
6. **Check for prior pain.** Look for postmortems, archived design docs, and persistent memory referencing the topic. Loading the *what* without the *why* is how regressions happen. {{instruction_file}} usually points to where these live in this repo.
7. **Report what is loaded** in the format below. Then **stop** and wait for the user to confirm or correct before acting on the actual task.

## Where to look

{{instruction_file}} is the index — it tells you where this repo keeps specs, postmortems, sibling code, and conventions. Use it to guide the sweep rather than guessing paths. Beyond what it points to, the standard places worth checking:

- **Source code** matching the topic keyword across module, library, component, hook, type, and provider directories
- **Specs / design docs** in whatever directory the repo uses ({{instruction_file}} will say — common names: `openspec/`, `docs/`, `design/`, `rfcs/`, `adr/`)
- **Postmortems and notes** at the repo root or wherever {{instruction_file}} points (for example, a `HORRIBLE_BUG_FIXES.md`, `POSTMORTEMS/`, `INCIDENTS/`)
- **Sibling repos** if the topic spans services ({{instruction_file}} typically names them and their relative paths)
- **Persistent memory** for this project, if any (the harness exposes a memory directory per project — grep it for topic terms)
- **Git history:** `git log --oneline -- <paths>` for recent activity, `git log --grep="<topic>" --oneline` for commit-mentioned context

## Reading discipline

- **Full reads beat excerpts.** A subagent's summary cannot substitute for {{read_tool}} on the canonical files. Your context window is what carries the next action.
- **Do not skip the postmortem step** when the topic is one the repo has been burned on. {{instruction_file}} and persistent memory are the strongest signal for which areas those are.
- **Do not act in the same turn as the load.** The user's instruction is to load first. The actionable task comes after they confirm.

## Report format

End the load with this block:

```
**Context loaded — <topic>**

Read:
- <path> — <one-line purpose>
- ...

Flows traced:
- <flow A>: <one-line summary>

Landmines (from postmortems / memory / archived design docs):
- <name> — <one-line reason>

Open questions before I act:
- <gap or ambiguity>
```

Keep one line for each item. The user reads this to decide whether to correct the model or hand off the task.

## Anti-patterns

- **Reading directory listings instead of files.** Mapping is not loading.
- **Summarizing without opening files.** If you did not `Read` it, you did not load it.
- **Acting on the task in the same turn.** Defeats the point — the user invoked this skill *to get a checkpoint* before changes.
- **Treating "ultrathink" alone as the trigger.** "ultrathink" is a thinking directive that often accompanies this skill but does not invoke it on its own. The trigger is the user asking to load context.
- **Skipping {{instruction_file}}.** It is the highest-signal-per-token document in the repo and the only one guaranteed to be current. Read it first.
- **Skipping postmortems on risky areas.** Loading code without history misses the constraints that shape it.
