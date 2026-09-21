# Pi daily-driver plan

- Research date: 2026-09-20.
- Installed Pi version: `0.86.0`.
- Sources: the current Pi documentation and the source repositories of package authors.

## Current state

The repository already gives Pi much of the common harness behavior:

- The bootstrap installs Pi from its official npm package (`scripts/bootstrap.sh:125`).
- The capability script installs the shared `AGENTS.md`, skills, and STE extension (`scripts/llm-capabilities.sh:121-137`).
- The managed settings disable telemetry and automatic compaction (`llm-capabilities/settings/pi/settings.json:1-8`).
- The shell disables startup network traffic (`.zshrc:132-138`).
- The usage script reports Pi tokens and cost (`README.md:36-51`).
- Sidekick starts Pi directly and forwards its modified Enter keys (`.config/nvim/lua/plugins/ml.lua:11-68,154-160`).

The live Pi settings select Anthropic and a Claude model. The live settings contain no package configuration.

Pi already supplies the daily session features. It saves sessions, resumes work, branches conversations, exports transcripts, and compacts context on request. The TUI shows token use, cache use, cost, context use, and the current model. It also accepts file references, images, shell commands, queued messages, and an external editor. [Pi usage](https://pi.dev/docs/latest/usage), [Sessions](https://pi.dev/docs/latest/sessions)

These features are complete without an extension.

## Recommended work

### Add subagents

Subagents are the largest functional gap. The Pi harness substitutions currently tell skills to do delegated work in the primary context (`llm-capabilities/harnesses/pi.json:6-8`). Claude Code and Codex can delegate that work.

Pi does not include subagents in its core. Pi supplies an official example that starts isolated Pi processes, streams progress, runs parallel tasks, and reports usage. [Pi design principles](https://pi.dev/docs/latest/usage#design-principles), [official subagent example](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples/extensions/subagent)

Use `pi-subagents` after a source review. It adds focused child agents, foreground and background work, parallel review, and saved workflows. Its package source has unit and integration tests and pins its runtime dependencies. [pi-subagents source](https://github.com/nicobailon/pi-subagents), [package manifest](https://github.com/nicobailon/pi-subagents/blob/main/package.json)

After installation, change `llm-capabilities/harnesses/pi.json` to name the extension tool. Then the shared research, review, and context skills can delegate work in Pi.

### Add web access

Pi has no built-in web search or page fetch tool. This prevents the shared research skill from matching Claude Code and Codex.

Use `pi-web-access` after a source review. It supplies `web_search` and `fetch_content`. It can reuse Pi OpenAI Codex authentication and can work without a separate search key. [package catalog](https://pi.dev/packages), [pi-web-access source](https://github.com/nicobailon/pi-web-access)

The package has a broad network surface and a broad provider set. Configure only the selected provider. Pin the package version in the dotfiles.

### Add structured questions

The current Pi substitution tells the model to ask in a reply and stop (`llm-capabilities/harnesses/pi.json:10`). Claude Code and Codex can show a structured question control.

Adapt Pi's official `question.ts` example as a local extension. It gives the model a question tool with choices and free-form input. The current example marks the tool as sequential, which prevents concurrent question dialogs. [official question extension](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/question.ts)

Keep the shared working-style rule. The extension improves necessary questions but must not cause more questions.

### Add a narrow permission gate

Project trust only controls project settings and extensions. It does not restrict model tool calls. Pi runs with the permissions of the user account and has no built-in sandbox. [Pi security](https://pi.dev/docs/latest/security)

Adapt Pi's official permission-gate example as a local extension. Make it confirm destructive host commands and fail closed without a TUI. Keep normal repository commands automatic. [official permission-gate extension](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/examples/extensions/permission-gate.ts)

The existing STE extension remains separate. It enforces publication rules but does not isolate the filesystem (`llm-capabilities/adapters/pi/ste-gate.ts:42-75`).

For untrusted work, use a separate sandbox profile. Pi documents Gondolin, Docker, OpenShell, and Docker Sandboxes. A permission dialog is not a sandbox. [Pi containerization](https://pi.dev/docs/latest/containerization)

### Complete terminal key transport

The tmux configuration turns extended keys on but does not select CSI-u (`.config/tmux/tmux.conf:24`). Pi recommends `extended-keys-format csi-u` so tmux preserves modified Enter keys. [Pi tmux setup](https://pi.dev/docs/latest/tmux)

The Sidekick mappings cover Pi inside Neovim. Add the documented Alacritty `Alt+Enter` binding for direct Pi sessions on macOS. [Pi Alacritty setup](https://pi.dev/docs/latest/terminal-setup#alacritty)

### Set the model workflow in Pi

Authenticate the OpenAI Codex provider with `/login`. Pi can use a ChatGPT Plus or Pro subscription. Anthropic subscription access in Pi uses paid extra usage, not Claude plan limits. [Pi providers](https://pi.dev/docs/latest/providers#subscriptions)

Use `/model`, `/thinking`, and `/scoped-models` to save the model, reasoning level, and model cycle. Keep these values in Pi's live settings because Pi owns and updates them. [Pi settings](https://pi.dev/docs/latest/settings#model--thinking)

Set the reasoning level to `xhigh` for parity with the current Claude Code and Codex settings. Turn on cache-miss notices if the extra usage detail is useful.

## Keep the existing behavior

- Keep automatic compaction off. Manual `/compact` remains available, and this matches the other harness settings.
- Keep Sidekick in regular TUI mode. Regular mode preserves terminal scrollback.
- Keep session files in Pi's default user directory. Sidekick already uses Pi's continue and resume flags.
- Keep project trust at `ask`. Trust does not replace the permission gate or a sandbox.
- Keep prompt templates optional. The shared skills already own reusable workflows.

## Defer

- Do not add MCP for parity. The Codex configuration disables apps and plugins, and Claude Code disables connectors.
- Do not add a goal or todo package. The Codex configuration disables goals, and the shared rules already control task completion.
- Do not add a plan-mode extension yet. The shared working-style rules already separate proposals from edits.
- Do not add a background-shell extension. Pi recommends tmux, which this repository already uses.
- Do not add `pi-lens` initially. It overlaps the Neovim LSP, formatter, and diagnostic setup and adds automatic edit checks.
- Defer a Gruvbox Pi theme. It improves appearance but does not close a functional gap.

## Configuration ownership

Store local extensions under `llm-capabilities/adapters/pi/`. Link each extension through `scripts/llm-capabilities.sh`, as the STE extension is linked now.

Declare reviewed packages at exact versions. Pi packages run with full system access, so each update needs a source review. [Pi package security](https://pi.dev/docs/latest/packages#install-and-manage)

`PI_OFFLINE=1` stops installation of missing packages. The bootstrap must install declared packages explicitly with offline mode removed. The existing privacy research records this behavior (`docs/research/privacy-pi.md`).

The recommended order is terminal transport, structured questions, subagents, web access, and the permission gate. This order makes the daily interface reliable before it adds code with full host access.
