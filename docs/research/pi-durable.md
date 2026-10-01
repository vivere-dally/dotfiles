# Research: Pi Durable package family (`@earendil-works/pi-durable`, `@earendil-works/pi-ai`, `@earendil-works/chord`)

## Summary

Pi Durable is an experimental TypeScript library for agents that survive crashes and run for a long time. It is a framework for building agentic applications. It does not replace the Pi coding agent CLI. All three packages reached version 1.0.0 on 2026-10-01 under the MIT license, but the pi-durable README carries the label "Experimental. The API changes without notice between releases." For this user, the verdict is watch, not install.

## Findings

1. **Claim:** Pi Durable is a durable agent harness in a library, not a product or a server. It stores every conversation entry, model turn, tool call, and application document before the harness shows it. If the process dies mid-turn, a new process opens the same storage and continues each unfinished task from its last checkpoint. **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md), [npm registry: pi-durable](https://registry.npmjs.org/@earendil-works/pi-durable). **Support:** direct evidence. The registry description is "Durable conversation, task, and document runtime for Pi". The README starts with "A durable agent harness." **Confidence:** high.

2. **Claim:** The runtime model is a `Harness` over a storage backend, with tasks as the unit of work. Storage options are memory, SQLite (one file, WAL mode), and JSONL (append-only files). The SQLite and JSONL cores use no Node APIs, so they run on Bun or in a Cloudflare Durable Object with a small adapter. One process owns a storage at a time, and there is no cross-process locking. Every step of a run is a task with a checkpoint, and a `requestId` makes each submission exactly-once. A timer task survives a restart, which gives scheduling at the framework level. **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md), [Pi Durable announcement](https://earendil.com/posts/pi-durable/). **Support:** direct evidence. **Confidence:** high.

3. **Claim:** One harness runs conversations in parallel. Each conversation holds its own agent choices (model, thinking level, tools, instructions, working directory) as names, and can fork another conversation at any entry. Compaction runs in the background before the context overflows. Application state lives in typed JSON documents that commits change atomically with the transcript. Extensions bundle tools, system prompt sections, hooks, and tasks, and the registry can replace an extension while the harness runs. Any client can attach to a conversation, read the current view, and steer it or queue a follow-up. **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md), [Pi Durable announcement](https://earendil.com/posts/pi-durable/). **Support:** direct evidence. **Confidence:** high.

4. **Claim:** Pi Durable does not replace the Pi coding agent CLI. The announcement says: "It does not replace the Pi coding agent. It is a framework for building any agentic application, coding agents included." The Pi 1.0 post keeps the CLI contract unchanged: one person drives it in a terminal. The post also says: "If the process dies, you look at what happened and tell it to continue." The two share the pi-ai library and the same principles. The coding-agent package carries experimental demos built on Durable (`packages/coding-agent/src/experimental/durable` and `.../vacation`). **Sources:** [Pi Durable announcement](https://earendil.com/posts/pi-durable/), [Pi 1.0 announcement](https://earendil.com/posts/pi-1-0/). **Support:** direct evidence. **Confidence:** high.

5. **Claim:** `@earendil-works/pi-ai` is the model-access library of the trio. The README calls it a "Unified LLM API with provider collections, automatic auth resolution, token and cost tracking". It also gives simple context persistence and hand-off to other models mid-session. It covers streaming, tool calls with TypeBox schemas, image input and generation, classification, thinking levels, cross-provider handoff, context serialization, and OAuth for some providers. Built-in providers include OpenAI, Anthropic, Google, Vertex AI, Amazon Bedrock, xAI, OpenRouter, and any OpenAI-compatible API such as Ollama. It also ships a small `pi-ai` CLI binary. **Sources:** [pi-ai README](https://github.com/earendil-works/pi/blob/main/packages/ai/README.md), [npm registry: pi-ai](https://registry.npmjs.org/@earendil-works/pi-ai). **Support:** direct evidence. **Confidence:** high.

6. **Claim:** `@earendil-works/chord` is the application-composition runtime of the trio. The README says it gives "facets, services, replicated state, and a pluggable remote-service boundary". The README also states: "it is not a Pi package: it does not depend on any other Pi workspace package". Applications outside Pi can use it. Its pieces are facets, typed services, replicated state, a remote service boundary, and a context object for cancellation. The facets are plugin parts that run in different processes. The services are singleton or keyed. The replicated state has atomic overlay transactions and delta tracking. The remote service boundary is transport-independent. Pi Durable depends on `@earendil-works/chord ^1.0.0` and `@earendil-works/pi-ai ^1.0.0`, and each Durable call takes a Chord context for cancellation. **Sources:** [chord README](https://github.com/earendil-works/pi/blob/main/packages/chord/README.md), [npm registry: pi-durable](https://registry.npmjs.org/@earendil-works/pi-durable). **Support:** direct evidence. **Confidence:** high.

7. **Claim:** Maturity. The npm registry gives these publish records:
   - pi-ai: first publish under this name 0.74.0 on 2026-05-07, 1.0.0 on 2026-10-01. A `legacy-node20` dist-tag points at 0.74.2.
   - chord: 0.0.0 on 2026-09-04, 1.0.0 on 2026-10-01.
   - pi-durable: 0.0.1 on 2026-09-19, 1.0.0 on 2026-10-01.
   - License MIT on each package, and the repository README states MIT.
   **Sources:** [npm registry: pi-ai](https://registry.npmjs.org/@earendil-works/pi-ai), [npm registry: chord](https://registry.npmjs.org/@earendil-works/chord), [npm registry: pi-durable](https://registry.npmjs.org/@earendil-works/pi-durable), [repository README](https://github.com/earendil-works/pi). **Support:** direct evidence. **Confidence:** high.

8. **Claim:** Stability labels differ in the trio. The first line of the pi-durable README is "**Experimental.** The API changes without notice between releases." The announcement repeats: "Pi Durable is experimental, and the API might still change." The pi-ai and chord READMEs carry no experimental label. The repository pins direct dependencies and sets `min-release-age=2` for npm resolution. **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md), [Pi Durable announcement](https://earendil.com/posts/pi-durable/), [chord README](https://github.com/earendil-works/pi/blob/main/packages/chord/README.md), [repository README](https://github.com/earendil-works/pi). **Support:** direct evidence for the labels. The inference that 1.0.0 without a label signals intent to stabilize is researcher judgment. No explicit stability promise exists for pi-ai or chord. **Confidence:** high for the labels, medium for the inference.

9. **Claim:** Adoption is small for Durable. The npm downloads API reports, for the week 2026-09-23 to 2026-09-29: pi-durable 651 downloads, pi-ai 7,020,697 downloads, chord 2,737,607 downloads. The pi-durable number shows a small real user base two weeks after the first publish. The high counts for pi-ai and chord have no explanation in the sources I read. Installs through the CLI package and registry mirrors are possible causes. **Sources:** [npm downloads API: pi-durable](https://api.npmjs.org/downloads/point/last-week/@earendil-works/pi-durable), [pi-ai](https://api.npmjs.org/downloads/point/last-week/@earendil-works/pi-ai), [chord](https://api.npmjs.org/downloads/point/last-week/@earendil-works/chord). **Support:** direct evidence for the numbers. The cause judgment is researcher inference, and the cause is unverified. **Confidence:** high for the numbers, low for the cause.

10. **Claim:** Fit for this user. The CLI covers the daily coding-agent work unchanged, and Durable adds nothing to the CLI today. At the framework level, Durable gives the issue-coordinator workflows their necessary properties:
    - runs that continue after a crash or a laptop sleep
    - background tasks and timers that survive restarts
    - queued messages with steering while the agent works
    - restart-safe persistent subagents
    - a model and a tool set for each conversation
    - one SQLite file as the whole state

    The examples list shows each of these (`20-inbox`, `21-late-join`, `23-subagent-background`, `25-compaction`, `26-coding-agent`, `28-reviewer`). **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md), [Pi Durable announcement](https://earendil.com/posts/pi-durable/). **Support:** direct evidence for the features. **Confidence:** high.

11. **Claim:** But the user must write the application. No scheduler product, no daemon, and no CLI ship with pi-durable. The one-process-per-storage rule fits one coordinator service per machine, with other processes as attached clients. It does not fit many independent pi processes that share state. On macOS, tmux or launchd must supervise the process, because the package gives no service integration. The API changes without notice between releases, so an application written today can break on the next version. **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md). **Support:** direct evidence for the one-process rule and the experimental label. The macOS supervision note and the fit judgment are researcher inference. **Confidence:** high for the facts, medium for the fit judgment.

12. **Claim:** Verdict: watch, do not install now. Reasons:
    - The package is experimental, and the API changes without notice between releases.
    - Value requires application code that does not exist yet, and writing it against an unstable API wastes work.
    - The CLI already covers the daily sessions, and the existing intercom and tmux setup still works.
    - Revisit when Earendil ships the announced Slack bot and GitHub triage bot. Revisit when the experimental label drops. Revisit when you decide to build the coordinator daemon. The repository README points to [earendil-works/pi-chat](https://github.com/earendil-works/pi-chat) for Slack and chat automation. Make a review of it before you build anything.
    **Sources:** [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md), [Pi Durable announcement](https://earendil.com/posts/pi-durable/), [repository README](https://github.com/earendil-works/pi). **Support:** direct evidence for the labels and plans. The verdict is researcher judgment. **Confidence:** medium.

## Contradictions

- None of substance. Three small notes:
  - The Pi 1.0 post says "Both are MIT licensed" next to an install command with three packages. The registry and the repository README confirm MIT for all three, so this is loose wording, not a license conflict.
  - Old pi-ai versions (0.74.x) point their homepage at `github.com/earendil-works/pi-mono`. The current repository is `github.com/earendil-works/pi`. The metadata is stale in old versions only.
  - The weekly download counts for pi-ai and chord sit far above pi-durable. Recorded as an open question, not resolved.

## Missing evidence

- The announcement posts show no publication date in the fetched text. The 2026-10-01 release date comes from the npm time objects.
- No explicit API stability promise exists for pi-ai or chord beyond the 1.0.0 version label.
- The pi.dev documentation for Durable was not read in this pass, so its depth is unverified.
- Whether pi-chat builds on pi-durable is unverified.
- The cause of the high weekly download counts for pi-ai and chord is unknown.

## Sources

- Kept: [Pi 1.0 announcement](https://earendil.com/posts/pi-1-0/) — names Pi Durable as experimental and gives the install command and license.
- Kept: [Pi Durable announcement](https://earendil.com/posts/pi-durable/) — the design tour: crash recovery, tasks, extensions, compaction, multiplayer, FAQ.
- Kept: [pi-durable README](https://github.com/earendil-works/pi/blob/main/packages/durable/README.md) — the normative package documentation: concepts, storage table, examples, experimental label.
- Kept: [pi-ai README](https://github.com/earendil-works/pi/blob/main/packages/ai/README.md) — scope of the model-access library and its license.
- Kept: [chord README](https://github.com/earendil-works/pi/blob/main/packages/chord/README.md) — scope of the composition runtime and its independence from Pi.
- Kept: [npm registry packuments](https://registry.npmjs.org/@earendil-works/pi-durable) for pi-durable, [pi-ai](https://registry.npmjs.org/@earendil-works/pi-ai), and [chord](https://registry.npmjs.org/@earendil-works/chord) — versions, publish dates, dependencies, licenses.
- Kept: [npm downloads API](https://api.npmjs.org/downloads/point/last-week/@earendil-works/pi-durable) — adoption signal for the week 2026-09-23 to 2026-09-29.
- Kept: [repository README](https://github.com/earendil-works/pi) — package table, supply-chain rules, pi-chat link.
- Rejected: npmjs.com HTML package pages gave HTTP 403 on fetch. The registry API gave the same data as raw JSON.

## Next steps

- Read [`packages/durable/docs/spec.md`](https://github.com/earendil-works/pi/blob/main/packages/durable/docs/spec.md), the normative specification, before any build decision.
- Read the pi.dev Durable documentation and watch [earendil-works/pi-chat](https://github.com/earendil-works/pi-chat) and the announced Slack and triage bots.
- If the user wants a pilot, run examples `23-subagent-background` and `26-coding-agent` in a scratch project against a copy of a real coordinator workflow.
