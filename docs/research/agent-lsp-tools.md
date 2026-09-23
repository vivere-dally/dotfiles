# LSP tools for coding agents

- Research date: 2026-09-23.
- Scope: the effect of Language Server Protocol (LSP) tools on the results, cost, and speed of coding agents, and the options for pi in this repository.
- Sources: arXiv papers, NeurIPS and ICLR papers, official vendor documentation, source code of opencode, npm package contents, GitHub issues, and local capability files.
- Method: a Claude agent searched the web, fetched each primary source, and read the source of the pi packages from their npm tarballs. A second agent, GLM-5.3 Flash in pi, did the same research independently. This note merges the two. No agent installed a package or ran a language server.

## Conclusion

LSP tools give small and conditional gains to agents. No source shows a large gain in task success for a frontier agent.

Diagnostics after an edit have the better support. An automatic lint guardrail added 3 points on SWE-bench Lite ([SWE-agent, NeurIPS 2024](https://arxiv.org/html/2405.15793)). Static-analysis feedback at decoding time raised compilation rates by 11.6 to 13.1 points ([MGD, NeurIPS 2023](https://ar5iv.labs.arxiv.org/html/2306.10763)).

Navigation tools have weak support. A full pyright tool set added 1.4 to 2.0 points on SWE-bench Verified ([SWE-Master, 2026](https://arxiv.org/html/2602.03411)). A controlled token study found that the answer to "does the LSP save tokens" is "conditional and usually negative" ([Xu, 2026](https://arxiv.org/abs/2608.13568)).

In this setup, type feedback already comes from commands. An earlier analysis counted 69 lint, typecheck, and test runs by one pi implementor subagent in one 78-minute session. The prior note found that execution feedback is the strongest lever (`docs/research/agent-code-efficiency.md:16`).

Thus do not adopt an LSP navigation tool set now. Do one measured trial of automatic diagnostics after an edit. Keep it only if it lowers the command runs or the tokens at the same pass rate.

## Measured effects

### Agents with LSP tools

- **SWE-Master** gave agents a pyright tool with definition, references, call hierarchy, symbols, and signature help. On SWE-bench Verified, MiniMax-M2.1 went from 68.4% to 70.4%, and its average turns fell from 82.0 to 77.0. GLM-4.7 went from 66.2% to 67.6%, and its turns fell from 97.3 to 94.4 ([SWE-Master, Table 5](https://arxiv.org/html/2602.03411)). The paper gives no token counts and no variance.
- **Xu** compared grep, LSP only, and free choice with Claude Opus 4.8, Sonnet 4.6, and Haiku 4.5 on Python and TypeScript repositories ([Xu, 2026](https://arxiv.org/abs/2608.13568)):
  - On symbol localization, the LSP cost 6% to 118% more tokens. Only Haiku saved tokens (26%).
  - With free choice, the models used the LSP for 0% to 6% of localization tasks, and for about half of the reference tasks.
  - On reference completeness, the LSP raised precision to 1.00, but recall stayed near 0.66. For Opus, F1 went from 0.706 to 0.778, at 19% more tokens ([Xu, results](https://arxiv.org/html/2608.13568)).
  - On multi-file renames, grep solved all tasks. A location-only LSP failed "three-quarters" of them, because a rename must also change comments and strings.
  - On the noisy `hono` repository, the LSP raised F1 by 0.245 and saved 12% of tokens. The gain grew as the grep precision fell.
  - The author calls the study preliminary: few repositories, small N, and no end-to-end SWE-bench scores for the edits.
- **RepoNavigator** trained Qwen2.5-14B with reinforcement learning to use one `jump` tool on pyright. On SWE-bench Verified, the file F1 was 58.90 against 31.64 for a multi-tool baseline. The resolve rate was 15.03% against 12.47%. With three more tools, the function IoU fell from 24.28% to 13.71% ([RepoNavigator, 2026](https://arxiv.org/html/2512.20957)). This result applies to a trained model, not to a tool that you add to an agent.
- **RepoGraph** is a code graph, not an LSP. It added 2.0 to 2.7 points on SWE-bench Lite in four frameworks, at 4,000 to 20,000 more tokens for each task ([RepoGraph, ICLR 2025](https://arxiv.org/html/2410.14684)).

### Automatic diagnostics and static feedback

- SWE-agent rejects an edit that has a syntax error. On SWE-bench Lite with GPT-4 Turbo, the resolve rate was 18.0% with the guardrail and 15.0% without it ([SWE-agent, Table 3](https://arxiv.org/html/2405.15793)).
- The same ablation shows that the shape of the output matters. Iterative search gave 12.0%, and a summarized search gave 18.0%. A full-file view gave 12.7%, and a 100-line window gave 18.0%.
- Monitor-guided decoding (MGD) asks Eclipse JDT.LS for valid identifiers during decoding. The compilation rate of SantaCoder-1.1B went from 59.97% to 73.03%. For text-davinci-003, it went from 62.66% to 74.26% ([MGD, Table 1](https://ar5iv.labs.arxiv.org/html/2306.10763)).
- Type-constrained decoding for TypeScript "reduces compilation errors by more than half" on HumanEval and MBPP ([Mündler and others, 2025](https://arxiv.org/abs/2504.09246)).
- ToolGen calls the Jedi autocompletion tool during generation. Static validity rose by 44.9% to 57.7%, and dependency coverage rose by 31.4% to 39.1% ([ToolGen, 2024](https://arxiv.org/abs/2401.06391)).

### Static structure and fixed pipelines

- Lin and others added call-graph and inheritance annotations as plain text to Codex runs. On medium repositories, pass@1 rose by 3.4 percentage points for about 10% more input tokens. The run-to-run variance fell to about half ([Lin and others, ISSTA 2026](https://arxiv.org/abs/2606.26979)). This result needs no language server.
- QLCoder used an LSP for syntax guidance in a loop that writes CodeQL queries. It reached 53.4% correct queries on 176 CVEs, against 10% for Claude Code alone ([QLCoder, 2025](https://arxiv.org/abs/2511.08462)).
- LSPRAG used LSP definitions and references as retrieval for unit-test generation. Line coverage rose by up to 174.55% for Go, 213.31% for Java, and 31.57% for Python ([LSPRAG, 2025](https://arxiv.org/abs/2510.22210)).

These gains come from fixed pipelines, not from a tool that a general agent chooses to call.

The decoding-time results change the model output token by token. An agent harness cannot do that. They show that static facts prevent invented APIs, not that an agent tool gives the same gain.

### Practitioner measurements

- CircleCI ran three reference tasks on the Vue.js repository (about 149,000 lines of TypeScript). Opus 4.8 used 12,916 tool-output tokens with the LSP and 18,673 with grep. Sonnet 4.6 took 238 s with the LSP and 359 s with grep. Sonnet with grep missed references ([CircleCI, 2026](https://circleci.com/blog/claude-code-lsp/)).
- A pi user ran eight evaluations three times with `@narumitw/pi-lsp@0.49.7` on three models. Two models had a lower success rate with the tool, and one had a higher rate. The total tokens fell by 6.4%. The author calls the results "inconclusive" ([Raisbeck, 2026](https://dev.to/scott_raisbeck_24ea5fbc1e/does-an-lsp-help-a-coding-agent-4a6f)). That package gives diagnostics on request only.

### Claims without measurement

- Eric Traut, the author of pyright, answered the Codex LSP request for OpenAI. Traut wrote that "the language server protocol was not designed for coding agents". Traut also wrote that an OpenAI experiment did not give the expected benefits ([openai/codex#8745](https://github.com/openai/codex/issues/8745#issuecomment-3713058579)).
- The Serena README cites agent self-reports, for example that a cross-file rename becomes "one atomic call". It gives no benchmark ([Serena](https://github.com/oraios/serena)).
- The Claude Code documentation says that Claude "notices and fixes" an error in the same turn. It gives no measurement ([Claude Code plugins](https://code.claude.com/docs/en/discover-plugins)).

## What each tool exposes

| Tool | Diagnostics after an edit | Navigation | Server management |
| --- | --- | --- | --- |
| Claude Code | Automatic after each edit. Set `diagnostics: false` in `.lsp.json` to stop it. | LSP tool: definition, references, hover, symbols, workspace symbols, implementations, call hierarchy. | A plugin names the binary, and you install it. Lazy start by file extension. `restartOnCrash` and `startupTimeout` are options. |
| opencode | Automatic. Errors only, 20 for each file. The write tool adds up to 5 other files. | Experimental `lsp` tool with 9 operations, behind a flag. | LSP is off by default. Built-in servers download automatically unless `OPENCODE_DISABLE_LSP_DOWNLOAD` is set. |
| Codex | None built in. | None built in. | Request #8745 is open with 603 reactions. |
| Serena (MCP) | A diagnostics tool. | Symbols, references, rename, move, and symbol edits. | SolidLSP or a paid JetBrains backend, one server set for each project. |
| pi core | None. | None. | Four tools, under 1,000 tokens with the system prompt. |
| `pi-lens@4.2.1` | Automatic, with linters, formatters, and scanners. | `lsp_navigation` with 19 operations, inactive until the model loads it. | Auto-installs servers and tools. Autoformat, autofix, and a read guard are on by default. |
| `@narumitw/pi-lsp@0.49.8` | On request only (`lsp_diagnostics`, `lsp_fix`). | None. | Starts a server for each call, then stops it. No download. |
| `pi-lsp-extension@1.3.0` | Automatic when a server runs for that file type. | Definition, references, hover, symbols, rename preview, completions. | Lazy start or `autoStart`. Shared daemons across sessions. |

Sources for the table:

- Claude Code: [tools reference](https://code.claude.com/docs/en/tools-reference), [plugins reference](https://code.claude.com/docs/en/plugins-reference), and [code intelligence plugins](https://code.claude.com/docs/en/discover-plugins).
- opencode: [LSP docs](https://opencode.ai/docs/lsp/), [`lsp/diagnostic.ts`](https://github.com/anomalyco/opencode/blob/dev/packages/opencode/src/lsp/diagnostic.ts), [`tool/write.ts`](https://github.com/anomalyco/opencode/blob/dev/packages/opencode/src/tool/write.ts), and [`tool/registry.ts`](https://github.com/anomalyco/opencode/blob/dev/packages/opencode/src/tool/registry.ts).
- Codex: [issue #8745](https://github.com/openai/codex/issues/8745).
- Serena: [README](https://github.com/oraios/serena).
- pi core: [Zechner, 2025](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/). The current [pi docs](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/docs) do not mention LSP.
- pi packages: the npm tarball of each package, and the [pi-lsp-extension README](https://github.com/samfoy/pi-lsp-extension).

Some details of the pi packages are important for a decision:

- `@narumitw/pi-lsp` routes TypeScript to `biome lsp-proxy` by default (`src/adapters.ts:50-52` in the tarball). Biome is a linter, thus this route does not report type errors. A custom file must add `typescript-language-server`.
- The `@narumitw/pi-lsp` README says that the package "has not demonstrated through benchmarks that LSP improves agent task success". Its diagnostics output has no size bound.
- `pi-lens` bounds each tool result to 40 KiB. It auto-installs tools such as `typescript-language-server`, `pyright`, `ruff`, and `golangci-lint` (`docs/dependencies.md` in the tarball).
- `pi-lsp-extension` names `@sinclair/typebox` as a peer dependency. pi 0.87.1 depends on `typebox` 1.3.27. This search did not do a test of the load.
- `pi-lsp-extension` appends diagnostics only when a server already runs. Without `autoStart`, the first edit of each language gets no diagnostics.

## Costs and failure modes

- **Start time.** The pi-lens benchmark measured a cold start of 1.8 s for `gopls`, 2.0 s for `pyright`, and 1.8 s for `typescript-language-server`. A warm edit took 473 ms, 520 ms, and 605 ms ([pi-lens latency benchmark](https://github.com/apmantza/pi-lens/blob/master/docs/lsp-latency-benchmark.md)). The benchmark used one Windows machine, small fixtures, and one run.
- **Clean files are slower.** A clean TypeScript file took 1,043 ms for each edit. The client cannot stop early on a first error, thus it waits for its time budget (same source).
- **Memory.** Anthropic warns that `rust-analyzer` and `pyright` "can consume significant memory on large projects" ([Claude Code plugins](https://code.claude.com/docs/en/discover-plugins)).
- **Monorepos.** If the workspace configuration is wrong, a server can report false import errors for internal packages (same source).
- **Stale state.** The opencode docs say that servers "can get out of sync" and "slow down agent workflows". They suggest the lint and typecheck commands in `AGENTS.md` for some projects ([opencode LSP](https://opencode.ai/docs/lsp/)).
- **Wait policy.** Each client uses a different wait:
  - opencode: a 150 ms debounce, a 5 s document wait, and a 45 s start timeout ([`lsp/client.ts`](https://github.com/anomalyco/opencode/blob/dev/packages/opencode/src/lsp/client.ts)).
  - `@narumitw/pi-lsp`: an 800 ms settle time and a 20 s timeout (`docs/settings.md` in the tarball).
  - `pi-lens`: a freshness gate that compares the file time with the scan time.
- **Noise during multi-file edits.** An intermediate state has errors that the next edit removes. opencode shows only errors. pi-lens shows only new diagnostics by default. No source measures the noise rate or its effect on the agent.
- **Token cost of tools.** The four pi tools and the system prompt use under 1,000 tokens. Zechner reports 13,700 tokens for the Playwright MCP tool list ([Zechner, 2025](https://mariozechner.at/posts/2025-11-30-pi-coding-agent/)). A navigation tool set adds a cost of this kind to each session.
- **Renames.** A location-only reference list misses comments and strings. Thus an LSP rename alone failed where grep passed ([Xu, 2026](https://arxiv.org/abs/2608.13568)).
- **Indexing at scale.** On TypeScript repositories of up to 1.2 million lines, one JSON-RPC call for each symbol made LSP-based indexing a bottleneck ([abcoder-ts-parser, 2026](https://arxiv.org/abs/2604.18413)).
- **Server defects.** LSPFuzz found 51 bugs in four common LSP servers. The developers confirmed 42, fixed 26, and assigned two CVEs ([LSPFuzz, ASE 2025](https://arxiv.org/abs/2510.00532)). A crashed server stops all of its code intelligence.
- **Security.** A server command runs with the permissions of the user. `@narumitw/pi-lsp` reads a project file only when pi trusts the project.

## The local setup

- pi pins three packages, and none of them is an LSP package (`llm-capabilities/settings/pi/settings.json:25-33`). `@narumitw/pi-goal` comes from the same author as `@narumitw/pi-lsp`.
- The STE gate appends advice to the result of `write` and `edit` (`llm-capabilities/adapters/pi/ste-gate.ts:66-85`). A diagnostics extension uses the same `tool_result` event. The pi docs say that `tool_result` handlers compose ([pi extensions](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/extensions.md)).
- `gopls` and `tsc` are on `PATH`. `typescript-language-server`, `basedpyright-langserver`, and `ruff` exist only in `~/.local/share/nvim/mason/bin`, which is not on `PATH`. `pyright-langserver` is not installed.
- Agents already run the project checks through `bash`. Thus an LSP diagnostic gives the same kind of fact earlier and for one file, not a new kind of fact.

## Recommendations

### 1. Do not add navigation tools now

The measured gains are 1 to 2 points, or a token cost. The tools help with reference lookups in large repositories with ambiguous names, and with weaker models. Keep `rg` as the default. Reconsider for a large TypeScript monorepo, and measure it there.

### 2. Do not adopt pi-lens

It changes files outside the task with autoformat and autofix. This conflicts with `llm-capabilities/rules/engineering.template.md:3`. It also installs tools and starts scanners on its own. This conflicts with `llm-capabilities/rules/working-style.template.md:22`.

### 3. Do one trial of automatic diagnostics

Use `pi-lsp-extension@1.3.0`, because it is the only pi package in this search that appends diagnostics after `write` and `edit`. First, make sure that it loads on pi 0.87.1. If it does not load, write a small adapter on the `tool_result` event, and use opencode's limits: errors only, 20 for each file.

Put this `.pi-lsp.json` file in each project of the trial:

```json
{
  "autoStart": ["typescript", "go", "python"],
  "autoInjectDiagnostics": true,
  "servers": {
    "python": { "command": "basedpyright-langserver", "args": ["--stdio"] }
  }
}
```

- TypeScript and bun: `typescript-language-server --stdio` uses the `typescript` package of the project. The `tsconfig.json` file must resolve the Bun types, or the server reports false errors.
- Go: `gopls` from Homebrew.
- Python: `basedpyright-langserver` from Mason. Put the Mason `bin` directory on `PATH` for pi, or give an absolute path.
- Install nothing new. Ask the user before a change to `PATH` or to `settings.json`.
- The extension starts language servers and shared daemons. Stop them after the trial.

### 4. Measure before you keep it

Use the same model, effort, and prompts. Run a set of real tasks from the TypeScript, Go, and Python projects, with and without the extension, three times each. Record these values:

- the pass rate on the hidden tests of each task
- the total input and output tokens
- the wall time
- the count of lint, typecheck, and test commands
- the count of injected diagnostics that were stale or false
- the resident memory of the language servers

A small trial cannot detect a change of 2 points in the pass rate. It can detect a large change in command runs or tokens. Keep the extension only if the command runs or the tokens fall, and the pass rate does not fall.

## Gaps in the evidence

- No controlled study measures post-edit LSP diagnostics against type-check commands in the same agent loop.
- No study measures diagnostic noise during multi-file edits.
- The token study of Xu is small and preliminary. It did not do a test of Go.
- SWE-Master gives one run for each model, and no variance or token counts.
- The pi experiment of Raisbeck does not name its tasks or give a significance test.
- No source measures server memory on a large TypeScript or Go repository.
- This search did not run a language server or load a pi package.
