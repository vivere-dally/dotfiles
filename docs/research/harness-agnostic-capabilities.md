# One source of agent capabilities for four harnesses

- Date of the research: 2026-09-19.
- Claude Code 2.1.278. The binary is `~/.local/share/claude/versions/2.1.278`. The docs are at `code.claude.com/docs/en/*`, fetched on the date above.
- OpenAI Codex CLI 0.154.0 (`codex --version` prints `codex-cli 0.154.0`). The source is tag `rust-v0.154.0` of `github.com/openai/codex`.
- opencode 1.18.13 (`opencode --version` prints `1.18.13`). The source is tag `v1.18.13` of `github.com/anomalyco/opencode`.
- pi 0.85.1, package `@earendil-works/pi-coding-agent`. The source is tag `v0.85.1` of `github.com/earendil-works/pi`.

In this file, `PI` is a short name for the installed pi package:
`/Users/s-ved/dotfiles/.nvm/versions/node/v24.11.1/lib/node_modules/@earendil-works/pi-coding-agent`.
A citation such as `PI/dist/core/skills.js:142-149` means that absolute path, lines 142 to 149.

Each Codex and opencode citation links to the tagged source on GitHub, with line anchors. This research read files only. It ran no harness session, and it ran no git command.

## Summary

- All four harnesses load the Agent Skills format: a directory with `SKILL.md` and `name` and `description` frontmatter.
- The shared directory `~/.agents/skills` works for three harnesses: Codex, opencode, and pi. Claude Code reads only `~/.claude/skills`.
- opencode also reads `~/.claude/skills`. Thus a skill that you link into both directories reaches opencode two times.
- All four harnesses read a symlinked skill directory.
- Only Claude Code loads a rules directory by default, and only Claude Code has glob path-scoped rules. Codex and pi read one user-level `AGENTS.md`.
- opencode reads one global `AGENTS.md`. Its `instructions` list of file globs can also load a directory of rule files.
- Claude Code and Codex share almost the same command-hook protocol, with JSON on stdin and `permissionDecision: "deny"`.
- Codex rejects `suppressOutput`, and it sends file edits as an `apply_patch` patch text, not as a `file_path`.
- opencode has no command hooks. It has in-process plugins with `tool.execute.before` and `tool.execute.after`.
- pi has no command hooks. It has in-process TypeScript extensions with `tool_call` and `tool_result` events.
- Codex runs a user hook only after you trust it in `/hooks`. A new or changed hook does not run until you trust it again.
- Recommendation: keep one source folder. First, remove the Claude-only words from the skill bodies and the rules. Then link the skills and the rules without a build step. Generate one `AGENTS.md` for Codex, pi, and opencode.
- For the STE gate, keep one checker core. Give Claude Code and Codex the same command entry. Give opencode and pi a thin adapter each.

## Claude Code 2.1.278

### Skills

- Claude Code loads skills from `~/.claude/skills/<name>/SKILL.md` (personal) and `.claude/skills/<name>/SKILL.md` (project). It also loads plugin skills and a managed enterprise location ([skills, where skills live](https://code.claude.com/docs/en/skills#where-skills-live)).
- Project skills load from the start directory and from each parent up to the repository root. A `.claude/skills` below the start directory loads when Claude first reads or edits a file there ([skills, monorepos](https://code.claude.com/docs/en/skills#discovery-from-parent-and-nested-directories)).
- For one name in two locations, enterprise wins over personal, and personal wins over project ([skills, same name](https://code.claude.com/docs/en/skills#resolve-skills-that-share-a-name)).
- A skill entry can be a symlink to a directory. Claude Code loads the skill one time when two locations point at the same target ([skills, where skills live](https://code.claude.com/docs/en/skills#where-skills-live)).
- Claude Code does not discover `~/.agents/skills` or `.agents/skills`. The location table of the skills page does not list them. The docs name a one-time importer, `/import`. Its code in the 2.1.278 binary lists `~/.agents/skills` and `~/.cursor/skills` as sources and `~/.claude/skills` as the target ([memory, migrate](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)).
- Claude Code honors `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `argument-hint`, `arguments`, `model`, `effort`, `context`, `agent`, `hooks`, `paths`, and `shell` ([skills, frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)).
- The user and the model can both invoke a skill. The user types `/<directory-name>`. The model uses the `Skill` tool ([skills, control who invokes](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill)).
- Claude Code replaces `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, named `$name`, `${CLAUDE_SKILL_DIR}`, and `${CLAUDE_PROJECT_DIR}` in the skill body ([skills, substitutions](https://code.claude.com/docs/en/skills#available-string-substitutions)).
- If no placeholder receives the arguments, Claude Code appends `ARGUMENTS: <value>` to the skill content ([skills, arguments](https://code.claude.com/docs/en/skills#pass-arguments-to-skills)).
- Claude Code runs each `` !`command` `` line before the model sees the skill ([skills, dynamic context](https://code.claude.com/docs/en/skills#inject-dynamic-context)).
- When a skill loads, the binary prints the line `Base directory for this skill: <dir>`. A `strings` search of the 2.1.278 binary finds this line.

### Always-loaded instructions

- The user file is `~/.claude/CLAUDE.md`. The user rules are each `.md` file in `~/.claude/rules/`, loaded before project rules ([memory, user-level rules](https://code.claude.com/docs/en/memory#user-level-rules)).
- The rules directory is read recursively. A rule without `paths` frontmatter loads at launch ([memory, set up rules](https://code.claude.com/docs/en/memory#set-up-rules)).
- A rule with `paths` frontmatter loads only when Claude reads a matching file ([memory, path-specific rules](https://code.claude.com/docs/en/memory#path-specific-rules)). None of the 8 current rule files has frontmatter. Thus no rule depends on path scoping today.
- The rules directory supports symlinks ([memory, symlinks](https://code.claude.com/docs/en/memory#share-rules-across-projects-with-symlinks)).
- In Cowork sessions only, Claude Code skips a symlinked `~/.claude/rules` that points outside the working directory ([memory, import](https://code.claude.com/docs/en/memory#import-additional-files)).
- `@path` imports expand to a depth of four hops ([memory, import](https://code.claude.com/docs/en/memory#import-additional-files)).
- Claude Code skips a memory file over 4 MiB. The docs advise less than 200 lines for each file ([memory, too large](https://code.claude.com/docs/en/memory#my-claude-md-is-too-large)).
- From v2.1.277, Claude Code reads a project `AGENTS.md` when no `CLAUDE.md` exists in the working directory or above it ([memory, AGENTS.md](https://code.claude.com/docs/en/memory#agents-md)). This support is project-level only.
- This support is off when the session does not fetch feature flags, for example when you turn telemetry off ([memory, unavailable](https://code.claude.com/docs/en/memory#when-agents-md-support-is-unavailable)).
- The current `settings.json` sets `DISABLE_TELEMETRY` and `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` (`/Users/s-ved/repos/me/dotfiles/claude/.claude/settings.json:2-7`). Thus this user gets no `AGENTS.md` support in Claude Code.

### Hooks

- You register hooks in the `hooks` key of `~/.claude/settings.json`, or in project settings, plugins, and skill frontmatter ([hooks, locations](https://code.claude.com/docs/en/hooks#hook-locations)). The runtime is any shell command. The current gate runs `bun ~/.claude/hooks/ste-check.ts`.
- `PreToolUse` gets `tool_name`, `tool_input`, and `tool_use_id`. For `Bash`, `tool_input.command` is the command text. For `Write` and `Edit`, `tool_input.file_path` is always absolute ([hooks, PreToolUse input](https://code.claude.com/docs/en/hooks#pretooluse-input)).
- To block, print `hookSpecificOutput.permissionDecision: "deny"` with a `permissionDecisionReason`. Claude sees that reason. An exit code of 2 with a reason on stderr also blocks ([hooks, PreToolUse decision](https://code.claude.com/docs/en/hooks#pretooluse-decision-control)).
- To advise, print `hookSpecificOutput.additionalContext`. Claude Code wraps it in a system reminder next to the tool result. It caps each string at 10,000 characters ([hooks, add context](https://code.claude.com/docs/en/hooks#add-context-for-claude)).
- `PostToolUse` also takes `additionalContext`, `decision: "block"` with `reason`, and `updatedToolOutput` ([hooks, PostToolUse decision](https://code.claude.com/docs/en/hooks#posttooluse-decision-control)).
- `suppressOutput` has no effect in Claude Code ([hooks, JSON output](https://code.claude.com/docs/en/hooks#json-output)).
- Hooks get `CLAUDE_PROJECT_DIR` in the environment and `cwd` in the payload ([hooks, scripts by path](https://code.claude.com/docs/en/hooks#reference-scripts-by-path)).

### Config locations

- The config directory is `~/.claude`. `CLAUDE_CONFIG_DIR` moves every `~/.claude` path, and that includes `rules/`, `skills/`, and `settings.json` ([claude directory](https://code.claude.com/docs/en/claude-directory#file-reference), [env vars](https://code.claude.com/docs/en/env-vars)).
- Claude Code writes its own data into `~/.claude/skills/synced/` and `~/.claude/skills/.trash/` ([skills, synced](https://code.claude.com/docs/en/skills#where-synced-skills-load)). Thus `~/.claude/skills` must stay a real directory. `scripts/stow.sh` already does this with `mkdir -p` (`/Users/s-ved/repos/me/dotfiles/scripts/stow.sh:15-19`).

### Portability hazards

- The built-in tool names are `Bash`, `PowerShell`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `Agent`, `Workflow`, `WebFetch`, `WebSearch`, `AskUserQuestion`, and `ExitPlanMode` ([hooks, PreToolUse](https://code.claude.com/docs/en/hooks#pretooluse)). The skill tool is `Skill`.
- A skill calls another skill with the `Skill` tool. Subagents come from the `Agent` tool, with types such as `Explore`.
- The `Workflow` tool is off in this setup, because `settings.json` sets `enableWorkflows` to `false` (`/Users/s-ved/repos/me/dotfiles/claude/.claude/settings.json:28`). But `viv-opsx-compact` calls it (`/Users/s-ved/repos/me/dotfiles/claude/.claude/skills/viv-opsx-compact/SKILL.md:61`).

## OpenAI Codex CLI 0.154.0

### Skills

- User roots are `$CODEX_HOME/skills` and `~/.agents/skills`. The source marks `$CODEX_HOME/skills` as deprecated but still loads it ([host_roots.rs L73-131](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/host_roots.rs#L73-L131)).
- Other roots are `.codex/skills` for each project config layer, and `/etc/codex/skills` for admin skills. System skills live in `$CODEX_HOME/skills/.system`.
- Repo roots are `.agents/skills` in each directory from the project root down to the working directory ([host_roots.rs L137-185](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/host_roots.rs#L137-L185)). The default root marker is `.git`.
- Codex does not read `~/.claude/skills`. No root in `host_roots.rs` names `.claude`.
- The official page lists `$CWD/.agents/skills`, parent `.agents/skills` up to the repository root, `$HOME/.agents/skills`, `/etc/codex/skills`, and the system skills ([Codex skills](https://developers.openai.com/codex/skills)).
- When two skills share a name, Codex keeps both, and both can show in skill selectors ([Codex skills](https://developers.openai.com/codex/skills)).
- In user, repo, and admin roots, Codex resolves directory symlinks. In the system root, it does not ([loader/host.rs L160-163](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/loader/host.rs#L160-L163)). The scan skips hidden directories, stops at depth 6, and reads a maximum of 2000 directories for each root ([loader/mod.rs L18-32](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/loader/mod.rs#L18-L32)).
- The frontmatter parser reads only `name`, `description`, and `metadata.short-description` ([skills/src/parser.rs L6-20](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/skills/src/parser.rs#L6-L20)). Codex ignores `disable-model-invocation`, `allowed-tools`, and `argument-hint`.
- To stop implicit invocation, put `agents/openai.yaml` in the skill directory with `policy.allow_implicit_invocation: false` ([metadata.rs L50-56](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/loader/metadata.rs#L50-L56), [Codex skills](https://developers.openai.com/codex/skills)).
- `[[skills.config]]` entries in `~/.codex/config.toml` turn one skill off by `path` or `name` ([skills_config.rs L18-47](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/skills_config.rs#L18-L47)).
- The user invokes a skill with `$skill-name` in the prompt, or with `/skills` ([mentions.rs L42](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/skills/src/mentions.rs#L42)). The model reads `SKILL.md` itself from the listed path ([catalog_prompt.rs L24-49](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/catalog_prompt.rs#L24-L49)).
- Codex does not replace `$ARGUMENTS` in a skill. Its migration code treats `$ARGUMENTS` as a feature that skills do not support ([command_migration.rs L418-428](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/command_migration.rs#L418-L428)). The rest of the user message is the only input.
- The prompt tells the model to resolve relative paths against the directory of `SKILL.md` ([catalog_prompt.rs L24-49](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/skills/src/catalog_prompt.rs#L24-L49)).
- The skill installer writes into `$CODEX_HOME/skills/<name>` ([skill-installer SKILL.md L48](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/skills/src/assets/samples/skill-installer/SKILL.md?plain=1#L48)). Codex writes system skills into `$CODEX_HOME/skills/.system` ([skills/src/lib.rs L63-67](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/skills/src/lib.rs#L63-L67)). Thus `~/.codex/skills` must stay a real directory.

### Always-loaded instructions

- The user file is `$CODEX_HOME/AGENTS.override.md` or `$CODEX_HOME/AGENTS.md`. Codex uses the first file that is not empty ([codex-home instructions L9-67](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/codex-home/src/instructions/mod.rs#L9-L67)). It reads one file only.
- Codex reads the user file through `tokio::fs::metadata` and `tokio::fs::read`, which resolve a symlink.
- Project files are one `AGENTS.override.md`, `AGENTS.md`, or fallback name for each directory, from the project root down to the working directory ([agents_md.rs L1-16](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/agents_md.rs#L1-L16)). The source comment says that symlinks are allowed ([agents_md.rs L186](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/agents_md.rs#L186)).
- `project_doc_max_bytes` defaults to 32 KiB ([config_toml.rs L73](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L73)). In the source, this budget starts after the user file, and it counts project files only ([agents_md.rs L61-65](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/agents_md.rs#L61-L65)).
- The official page says that the limit applies to the combined size ([Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md)). The source wins, but the 8 current rule files have a total of 22,301 bytes. Thus they fit under either reading.
- `project_doc_fallback_filenames` defaults to an empty list. Thus Codex does not read `CLAUDE.md` ([config_toml.rs L79-85](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L79-L85)).
- Codex has no rules directory and no path-scoped rules. Other keys are `developer_instructions`, which is an inline string, and `model_instructions_file`. The source discourages `model_instructions_file` ([config_toml.rs L231-253](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L231-L253)).

### Hooks

- Codex has command hooks with the same shape as Claude Code. The events are `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`, `SubagentStart`, `SubagentStop`, `Stop`, and `Interrupt` ([hook_config.rs L36-61](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/hook_config.rs#L36-L61)).
- The `hooks` feature is stable and on by default ([features lib.rs L1167-1171](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1167-L1171)).
- Registration uses `hooks.json` in the config folder of a layer, for example `~/.codex/hooks.json`, or `[hooks]` tables in `config.toml` ([discovery.rs L339-400](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/discovery.rs#L339-L400)).
- A handler has `type = "command"`, `command`, `timeout` in seconds, `async`, `statusMessage`, and `additionalContextLimit` ([hook_config.rs L161-201](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/hook_config.rs#L161-L201)). The default timeout is 600 seconds ([discovery.rs L740-763](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/discovery.rs#L740-L763)).
- Codex runs the command with `$SHELL -lc`, with an environment from a session snapshot, and with the session `cwd` ([command_runner.rs L391-454](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/command_runner.rs#L391-L454)).
- Codex adds environment variables only for plugin hooks: `PLUGIN_ROOT`, `CLAUDE_PLUGIN_ROOT`, `PLUGIN_DATA`, and `CLAUDE_PLUGIN_DATA` ([discovery.rs L262-270](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/discovery.rs#L262-L270)). It does not set `CLAUDE_PROJECT_DIR`.
- A user hook runs only when its trust hash matches ([discovery.rs L676-734](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/discovery.rs#L676-L734), [discovery.rs L794-821](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/discovery.rs#L794-L821)).
- You trust a hook in the `/hooks` menu. Codex writes `trusted_hash` under `[hooks.state."<key>"]` in the user `config.toml` ([config_rules.rs L15-66](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/config_rules.rs#L15-L66)).
- The key is `<source path>:<event>:<group index>:<handler index>` ([hooks lib.rs L113-123](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/lib.rs#L113-L123)).
- The hash covers the event, the matcher, and the handler config, and not the file text. A changed command needs a new trust ([discovery.rs L766-792](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/discovery.rs#L766-L792)).
- `--dangerously-bypass-hook-trust` skips trust for one run ([config/mod.rs L3265-3272](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L3265-L3272), [Codex hooks](https://developers.openai.com/codex/hooks)).
- Shell commands reach hooks as `tool_name: "Bash"` with `tool_input.command` ([exec_command.rs L520-531](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/handlers/unified_exec/exec_command.rs#L520-L531)).
- File edits reach hooks as `tool_name: "apply_patch"` with the patch text in `tool_input.command`. The matchers `Write` and `Edit` are aliases for `apply_patch` ([hook_names.rs L28-56](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/hook_names.rs#L28-L56), [apply_patch.rs L458-495](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/handlers/apply_patch.rs#L458-L495)).
- The payload has no `file_path`. The file names are in the `*** Add File: `, `*** Update File: `, and `*** Move to: ` lines of the patch ([apply-patch parser.rs L7-43](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/apply-patch/src/parser.rs#L7-L43)).
- The `PreToolUse` input has `session_id`, `turn_id`, `transcript_path`, `cwd`, `hook_event_name`, `model`, `permission_mode`, `tool_name`, `tool_input`, and `tool_use_id` ([pre_tool_use.rs L175-191](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/events/pre_tool_use.rs#L175-L191)).
- To block, print `hookSpecificOutput.permissionDecision: "deny"` with a reason that is not empty. Exit code 2 with a reason on stderr also blocks ([pre_tool_use.rs L193-310](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/events/pre_tool_use.rs#L193-L310), [output_parser.rs L121-182](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/output_parser.rs#L121-L182)).
- To advise, print `hookSpecificOutput.additionalContext` from `PreToolUse` or `PostToolUse`. Codex adds it as developer context. It spills text over about 2,500 tokens to a file ([Codex hooks](https://developers.openai.com/codex/hooks)).
- Codex rejects `suppressOutput`, `continue: false`, and `stopReason` in `PreToolUse`. It rejects `suppressOutput` in `PostToolUse` too ([output_parser.rs L369-399](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/engine/output_parser.rs#L369-L399)).
- A rejected output marks the hook run as failed and drops its `additionalContext` ([post_tool_use.rs L200-210](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/events/post_tool_use.rs#L200-L210)). The official page agrees ([Codex hooks](https://developers.openai.com/codex/hooks)).
- The output structs reject unknown fields ([schema.rs L86-154](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/schema.rs#L86-L154)).
- The current `ste-check.ts` prints `suppressOutput: true` with each piece of advice (`/Users/s-ved/repos/me/dotfiles/claude/.claude/hooks/ste-check.ts:694-699`). Thus Codex drops all advice of the current gate. The deny output of the gate is valid for Codex.

### Config locations

- The home is `~/.codex`, and `CODEX_HOME` moves it. The value must be a directory that exists ([home-dir lib.rs L13-63](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/utils/home-dir/src/lib.rs#L13-L63)).
- The files for a script to write are `~/.codex/AGENTS.md` and `~/.codex/hooks.json`. The script must not write `~/.codex/config.toml`, because Codex writes project trust and hook trust into that file.
- If `CODEX_HOME` itself is a symlink, the sandbox needs `allow_symlinked_codex_home = true` ([config_toml.rs L212](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L212)). Link files inside `~/.codex`, and not the directory.

### Portability hazards

- Codex has no read or grep tool. The model reads and searches through the shell tool `exec_command` ([shell_spec.rs L96](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/handlers/shell_spec.rs#L96)). It edits with `apply_patch`.
- Subagents come from `spawn_agent`. The `multi_agent` feature is on by default ([features lib.rs L1260-1263](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1260-L1263)).
- `request_user_input` exists only when `experimental_request_user_input_enabled` is true ([spec_plan.rs L1158-1161](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/spec_plan.rs#L1158-L1161)).
- A skill reaches another skill only when the model reads the other `SKILL.md` from the listed path.

## opencode 1.18.13

The repository `sst/opencode` now redirects to `anomalyco/opencode`, and the Homebrew tap is `anomalyco/tap`.

### Skills

- Global roots are `~/.config/opencode/skills`, `~/.claude/skills`, and `~/.agents/skills` ([opencode skills](https://opencode.ai/docs/skills/)).
- Project roots are `.opencode/skills`, `.claude/skills`, and `.agents/skills`, from the working directory up to the git worktree ([skill/index.ts L173-233](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/skill/index.ts#L173-L233)).
- `skills.paths` and `skills.urls` in `opencode.json` add more roots ([skills.ts L6-9](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/skills.ts#L6-L9)).
- `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` stops the `.claude/skills` scan. `OPENCODE_DISABLE_EXTERNAL_SKILLS=1` stops both the `.claude` and the `.agents` scans ([runtime-flags.ts L21-30](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L21-L30)).
- The glob resolves symlinks (`symlink: true`, [skill/index.ts L142-171](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/skill/index.ts#L142-L171)).
- For two skills with one name, the loader logs a warning and keeps the one that it adds last. It loads the files in parallel, so the order is not fixed ([skill/index.ts L125-139, L240-243](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/skill/index.ts#L125-L139)).
- The docs name the frontmatter fields `name`, `description`, `license`, `compatibility`, and `metadata`. opencode ignores other fields ([opencode skills](https://opencode.ai/docs/skills/)).
- The source needs only a `name` string ([skill/index.ts L53-59](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/skill/index.ts#L53-L59)). opencode ignores `disable-model-invocation` and `allowed-tools`.
- The docs say that `name` must match the directory name. The source declares `NameMismatchError` but never raises it. The source wins.
- The model loads a skill with the `skill` tool, which takes only `name` ([tool/skill.ts L8-66](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/skill.ts#L8-L66)). The tool output says `Base directory for this skill: <dir>`.
- Each skill is also a slash command `/<name>`, unless a command with that name exists ([command/index.ts L134-156](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/command/index.ts#L134-L156)).
- A slash command replaces `$ARGUMENTS` and `$1` to `$N`. With no placeholder, it appends the arguments ([session/prompt.ts L1372-1406](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/prompt.ts#L1372-L1406)).
- A slash command also runs each `` !`command` `` in the skill body ([config/markdown.ts L6](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/markdown.ts#L6)). A load through the `skill` tool replaces nothing.
- The nearest equivalent of `disable-model-invocation` is a `permission.skill` rule set to `"deny"` in `opencode.json`. The rule hides the skill from the model ([session/system.ts L98-109](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/system.ts#L98-L109), [opencode skills](https://opencode.ai/docs/skills/)).
- The slash command reads `skill.all()` and not the permission rules. Thus the user can still type the command.

### Always-loaded instructions

- The global file is the first file that exists of `~/.config/opencode/AGENTS.md` and `~/.claude/CLAUDE.md` ([session/instruction.ts L60-68, L110-120](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/instruction.ts#L60-L120)).
- The project file is the first match of `AGENTS.md`, `CLAUDE.md`, and `CONTEXT.md` from the working directory up to the worktree.
- `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1` stops both `CLAUDE.md` fallbacks.
- The `instructions` array in `opencode.json` adds files, globs, and URLs ([session/instruction.ts L135-150](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/instruction.ts#L135-L150), [opencode rules](https://opencode.ai/docs/rules/)).
- For an absolute path or a `~/` path, only the last segment can hold a glob, for example `~/x/rules/*.md`. Thus opencode can load a whole directory of rule files.
- opencode has no `paths` frontmatter. When the `read` tool reads a file, opencode adds the instruction file of each directory between that file and the session directory. It adds each file one time for each message ([tool/read.ts L300](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/read.ts#L300), [session/instruction.ts L179-221](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/instruction.ts#L179-L221)). This is directory scoping, not glob scoping.
- The source shows no size limit for instruction files.

### Hooks and plugins

- opencode has no command hooks. A search of `packages/` for `PreToolUse`, `PostToolUse`, and a `hooks` config key found nothing.
- The mechanism is a plugin. A plugin is a JS or TS module that exports async functions. Each function returns a hooks object ([opencode plugins](https://opencode.ai/docs/plugins/)).
- opencode loads `{plugin,plugins}/*.{ts,js}` from each config directory, and it resolves symlinks ([config/plugin.ts L18-30](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/plugin.ts#L18-L30)). It also loads the `plugin` array of `opencode.json`.
- The plugins run in process, on the Bun runtime inside the binary. A `strings` search of the binary finds `Bun v1.3.14`.
- `tool.execute.before` gets `{ tool, sessionID, callID }` and a mutable `{ args }` ([plugin index.ts L266-281](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/plugin/src/index.ts#L266-L281)).
- To block, throw an error. The trigger does not catch it, and the tool call fails ([plugin/index.ts L282-295](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/plugin/index.ts#L282-L295), [session/tools.ts L100-128](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/tools.ts#L100-L128)).
- The error message goes to the model as the `errorText` of the tool result ([processor.ts L186-205](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/processor.ts#L186-L205), [message-v2.ts L337-346](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/message-v2.ts#L337-L346)).
- `tool.execute.after` gets `{ tool, sessionID, callID, args }` and a mutable `{ title, output, metadata }`. To advise, append text to `output.output`. That string becomes the tool result for the model ([processor.ts L383-400](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/processor.ts#L383-L400), [message-v2.ts L292-295](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/message-v2.ts#L292-L295)).
- The shell tool is `bash` with `args.command`. The file tools are `write` and `edit` with `args.filePath`.
- For GPT models other than `gpt-4` and `oss`, opencode swaps `write` and `edit` for `apply_patch` with `args.patchText` ([tool/registry.ts L292-295](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/registry.ts#L292-L295)).
- The patch text uses the same `*** Add File:` and `*** Update File:` headers as Codex ([core patch.ts L35-55](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/patch.ts#L35-L55)).

### Config locations

- The global config directory is `$XDG_CONFIG_HOME/opencode`, which is `~/.config/opencode` by default. `opencode.json` lives there.
- `OPENCODE_CONFIG` adds one config file. `OPENCODE_CONFIG_DIR` adds one more config directory for agents, commands, plugins, and skills ([config/paths.ts L23-41](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/paths.ts#L23-L41), [opencode config](https://opencode.ai/docs/config/)).
- In the source, `OPENCODE_CONFIG_DIR` also replaces `~/.config/opencode` as the place of the global `AGENTS.md` ([core global.ts L64](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/global.ts#L64)). The config page does not say this.
- At each start, opencode writes a `.gitignore` into each config directory, if none exists. It also runs a package install of `@opencode-ai/plugin` there ([config/config.ts L295-312, L436-455](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L295-L312)).
- Thus `~/.config/opencode` must stay a real directory. A config directory that points into the repository gets `package.json`, `node_modules`, and `.gitignore` written into the repository.

### Portability hazards

- The tools are `read` (`filePath`), `write`, `edit`, `apply_patch`, `bash`, `grep`, `glob`, `skill`, `task` for subagents, `question`, `todowrite`, `webfetch`, and `websearch`.
- The built-in subagents are `general` and `explore` ([agent/agent.ts L183-216](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L183-L216)).
- `question` is on for the `cli`, `app`, and `desktop` clients ([tool/registry.ts L202](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/registry.ts#L202)).
- A skill reaches another skill through the `skill` tool.

## pi 0.85.1

The canonical repository is `github.com/earendil-works/pi`, with the agent in `packages/coding-agent` (`PI/package.json:105-109`). The old `badlogic/pi-mono` repository redirects there. The docs site is `pi.dev/docs/latest`.

### Skills

- pi implements the Agent Skills standard (`PI/docs/skills.md:7`).
- Global roots are `~/.pi/agent/skills` and `~/.agents/skills`. Project roots are `.pi/skills`, and `.agents/skills` in the working directory and each parent up to the git root (`PI/docs/skills.md:24-34`, `PI/dist/core/package-manager.js:287-303`).
- Project roots load only after you trust the project.
- Among the auto-discovered roots, the code adds project entries before user entries (`PI/dist/core/package-manager.js:1939-2020`). The loader keeps that order (`PI/dist/core/resource-loader.js:330-334`).
- For two skills with one name, pi keeps the first and warns (`PI/dist/core/skills.js:320-347`). Thus a project skill wins over a user skill. Packages and paths in the `skills` setting come before both (`PI/dist/core/package-manager.js:698-731`).
- pi skips a second path to the same real file without a warning (`PI/dist/core/skills.js:323-328`).
- pi does not read `~/.claude/skills` by default. The docs show how to add it with the `skills` array in `settings.json` (`PI/docs/skills.md:44-63`).
- The loader resolves symlinked files and directories (`PI/dist/core/skills.js:142-149`, `PI/dist/core/skills.js:170-183`).
- The loader reads `name`, `description`, and `disable-model-invocation` (`PI/dist/core/skills.js:231-265`). A skill with `disable-model-invocation: true` does not show in the system prompt (`PI/dist/core/skills.js:275-277`).
- The docs list `allowed-tools` as experimental (`PI/docs/skills.md:149`). But the source never reads it. A search of `PI/dist` for `allowed-tools` and `allowedTools` found nothing. The source wins, so pi ignores `allowed-tools`.
- In pi, `name` can differ from the directory name (`PI/docs/skills.md:144`).
- The model loads a skill with the `read` tool from the `<location>` in the system prompt. The user types `/skill:<name> [args]` (`PI/docs/skills.md:65-91`).
- pi does not replace `$ARGUMENTS` in a skill. It appends the argument text after the skill block (`PI/dist/core/agent-session.js:983-1006`).
- The docs say that the prefix is `User: <args>` (`PI/docs/skills.md:83`). The source appends the plain text. The source wins.
- `$ARGUMENTS` works only in pi prompt templates, which is a different feature (`PI/docs/prompt-templates.md:65-74`).
- The skill block says `References are relative to <baseDir>` (`PI/dist/core/agent-session.js:995`).

### Always-loaded instructions

- The user file is `~/.pi/agent/AGENTS.md`. For each directory, pi takes the first file that exists of `AGENTS.override.md`, `AGENTS.md`, `AGENTS.MD`, `CLAUDE.md`, and `CLAUDE.MD` (`PI/dist/core/resource-loader.js:32-51`).
- pi then adds one such file from each directory, from the filesystem root down to the working directory (`PI/dist/core/resource-loader.js:82-108`). It reads one file for each directory, not a directory of rules.
- pi reads the file through `existsSync` and `statSync`, which resolve a symlink.
- `~/.pi/agent/SYSTEM.md` replaces the system prompt. `~/.pi/agent/APPEND_SYSTEM.md` appends to it (`PI/dist/core/resource-loader.js:809-828`, `PI/README.md:334-336`).
- `--append-system-prompt` takes text or a file path, and you can give it more than one time (`PI/dist/cli/args.js:273`).
- pi has no path-scoped rules. A search of `PI/dist/core` for `paths` frontmatter found nothing.
- An example extension lists `.claude/rules/` of the project in the system prompt, but it is not loaded by default (`PI/examples/extensions/claude-rules.ts:1-86`). The source shows no size limit.

### Hooks and extensions

- pi has no command hooks. The mechanism is an extension, which is a TypeScript module that pi loads in process with `jiti` on Node (`PI/docs/extensions.md:154-181`). The binary is Node, with the shebang `#!/usr/bin/env node` in `PI/dist/bundle/cli.js`.
- The extension locations are `~/.pi/agent/extensions/*.ts`, `~/.pi/agent/extensions/*/index.ts`, and the same under `.pi/extensions/`. The `extensions` array in `settings.json` adds more (`PI/docs/extensions.md:109-135`).
- The discovery resolves symlinks (`PI/dist/core/package-manager.js:404-449`).
- The `tool_call` event fires before a tool runs. The event is `{ toolName, toolCallId, input }`. For `bash`, `input.command` is the command text (`PI/dist/core/extensions/types.d.ts:678-724`).
- To block, return `{ block: true, reason }` (`PI/dist/core/extensions/types.d.ts:818-828`). The model gets an error tool result with that reason (`PI/node_modules/@earendil-works/pi-agent-core/dist/agent-loop.js:400-458`).
- A handler that throws also blocks the call (`PI/dist/core/agent-session.js:223-243`).
- The `tool_result` event fires after the tool runs. To advise, return `{ content: [...event.content, { type: "text", text }] }`. The new content is the tool result for the model (`PI/dist/core/extensions/types.d.ts:835-840`, `PI/dist/core/agent-session.js:244-271`).
- For `write` and `edit`, `input.path` is the file path (`PI/dist/core/tools/write.d.ts:5-6`). It can be relative, so resolve it against `ctx.cwd`.
- `pi.exec()` has no stdin option (`PI/dist/core/exec.d.ts:1-30`). To give JSON to a subprocess, use `node:child_process` directly.
- Other events: `before_agent_start` can change the system prompt or add a message (`PI/docs/extensions.md:530-565`). `input` sees the raw prompt (`PI/docs/extensions.md:911-958`).

### Config locations

- The agent directory is `~/.pi/agent`. `PI_CODING_AGENT_DIR` moves it (`PI/dist/config.js:406`, `PI/dist/config.js:421-427`).
- The files are `settings.json`, `AGENTS.md`, `skills/`, `extensions/`, and `prompts/` in that directory. The project directory is `.pi/`, and it loads only after trust (`PI/README.md:285-308`).

### Portability hazards

- The built-in tools are `read`, `bash`, `edit`, `write`, `grep`, `find`, `ls`, and `powershell`. The default set is `read`, `write`, `edit`, and `bash` (`PI/README.md:91`, `PI/README.md:588`).
- The built-in list has no subagent tool, no question tool, and no skill tool (`PI/README.md:588`). The README says "No sub-agents" (`PI/README.md:501`). A skill reaches another skill only when the model reads the other `SKILL.md`.
- A skill with `disable-model-invocation: true` is hidden from the prompt. Thus another skill cannot find it in pi.

## Comparison

| | Claude Code 2.1.278 | Codex 0.154.0 | opencode 1.18.13 | pi 0.85.1 |
| --- | --- | --- | --- | --- |
| User skill roots | `~/.claude/skills` | `~/.agents/skills`, `$CODEX_HOME/skills` (deprecated) | `~/.config/opencode/skills`, `~/.claude/skills`, `~/.agents/skills` | `~/.pi/agent/skills`, `~/.agents/skills` |
| Project skill roots | `.claude/skills` up to repo root | `.agents/skills` from repo root to cwd, `.codex/skills` | `.opencode/skills`, `.claude/skills`, `.agents/skills` up to worktree | `.pi/skills`, `.agents/skills` up to git root (after trust) |
| Symlinked skill dirs | Yes | Yes (not system root) | Yes | Yes |
| User invocation | `/<name>` | `$<name>`, `/skills` | `/<name>` | `/skill:<name>` |
| Argument placeholders | `$ARGUMENTS`, `$N`, `$name` | None | `$ARGUMENTS`, `$N` (slash only) | None (text appended) |
| Stop model invocation | `disable-model-invocation` | `agents/openai.yaml` `allow_implicit_invocation: false` | `permission.skill` `"deny"` | `disable-model-invocation` |
| User instructions | `~/.claude/CLAUDE.md`, `~/.claude/rules/**/*.md` | `$CODEX_HOME/AGENTS.md` (one file) | `~/.config/opencode/AGENTS.md` or `~/.claude/CLAUDE.md`, plus `instructions` globs | `~/.pi/agent/AGENTS.md`, `APPEND_SYSTEM.md` |
| Many files or a directory | Yes | No | Yes, with `instructions` globs | No |
| Path-scoped rules | `paths` frontmatter | No | Nested `AGENTS.md` on read | No |
| Hook mechanism | Command hooks in `settings.json` | Command hooks in `hooks.json` or `config.toml`, trust needed | In-process plugin in `plugins/` | In-process extension in `extensions/` |
| Block a shell command | `permissionDecision: "deny"` | `permissionDecision: "deny"` | Throw in `tool.execute.before` | Return `{ block: true, reason }` from `tool_call` |
| Advise after a write | `additionalContext` | `additionalContext`, no `suppressOutput` | Append to `output.output` | Return new `content` from `tool_result` |
| Write payload | `tool_input.file_path` | `apply_patch` text in `tool_input.command` | `args.filePath`, or `args.patchText` | `input.path` |
| Hook runtime | Shell command | `$SHELL -lc` command | Bun, in process | Node with `jiti`, in process |
| Config directory env var | `CLAUDE_CONFIG_DIR` | `CODEX_HOME` | `OPENCODE_CONFIG_DIR` (added dir), `OPENCODE_CONFIG`, `XDG_CONFIG_HOME` | `PI_CODING_AGENT_DIR` |

## Cross-harness conventions and tools

- **Agent Skills.** Anthropic made the format and released it as an open standard. The spec and the discussion live at `agentskills.io` and `github.com/agentskills/agentskills` ([Agent Skills home](https://agentskills.io/home), [specification](https://agentskills.io/specification)).
- The spec defines `name`, `description`, `license`, `compatibility`, `metadata`, and `allowed-tools`, which is experimental. The spec says that `name` must match the directory name.
- `disable-model-invocation`, `argument-hint`, and `$ARGUMENTS` are not in the spec.
- The client guide calls `.agents/skills` and `~/.agents/skills` "a widely-adopted convention for cross-client skill sharing" ([adding skills support](https://agentskills.io/client-implementation/adding-skills-support)). The spec itself does not name a location.
- **AGENTS.md.** The format came from OpenAI Codex, Amp, Jules, Cursor, and Factory. The Agentic AI Foundation of the Linux Foundation now owns it ([agents.md](https://agents.md/)). The format covers project files only. Each harness names its own user-level path.
- **`vercel-labs/skills`** is the `npx skills` installer. It links or copies skills into the directories of many agents, and that includes all four harnesses ([README](https://github.com/vercel-labs/skills)). It is active: the last push was on 2026-09-18.
- Its table names `~/.codex/skills` for Codex, which Codex now calls deprecated. Its table also says that Codex has no hooks, which is out of date for 0.154.0.
- **`dyoshikawa/rulesync`** makes rule, skill, command, and hook files for many tools from one source. Its table marks rules, skills, and hooks for Claude Code, Codex CLI, OpenCode, and Pi Coding Agent ([README](https://github.com/dyoshikawa/rulesync)). It is active: the last push was on 2026-09-19.
- **`intellectronica/ruler`** copies one rule set to the rule files of many agents, and it has experimental skills support ([README](https://github.com/intellectronica/ruler)). Its table lists no hooks.
- **Built-in importers** copy one time and do not sync. Claude Code has `/import` ([memory, migrate](https://code.claude.com/docs/en/memory#migrate-instructions-from-other-tools)). Codex has an importer for Claude Code and Cursor config ([external-agent-migration lib.rs](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/external-agent-migration/src/lib.rs)).
- None of these tools keeps a hook checker in one shared core. rulesync is the nearest match, but it makes a separate hook file for each tool. Thus this repository needs its own small script.

## Recommendation

### Source layout

```
llm-capabilities/
├── rules/                  # the 8 rule files, moved from claude/.claude/rules
├── skills/<name>/          # Agent Skills dirs; SKILL.md + bundled files
│   └── agents/openai.yaml  # only in user-invoked skills (Codex policy file)
├── ste/
│   ├── core.ts             # pure checker: no process.exit, no stdin, no Bun.* globals
│   └── cli.ts              # bun entry: --file mode + hook protocol on stdin
├── adapters/
│   ├── codex/hooks.json    # PreToolUse ^Bash$, PostToolUse ^apply_patch$ -> cli.ts
│   ├── opencode/ste-gate.ts  # plugin: tool.execute.before/after -> cli.ts
│   └── pi/ste-gate.ts        # extension: tool_call/tool_result -> cli.ts
└── build/                  # generated, gitignored
    └── AGENTS.md           # concatenation of rules/*.md
```

Keep `claude/.claude/settings.json` and `statusline-command.sh` in the `claude` stow package, because they are Claude-only. Move `skills/`, `rules/`, and `hooks/` out of that package into `llm-capabilities/`.

Add `^/llm-capabilities` to `.stow-local-ignore`, as the file does for `^/claude` today (`/Users/s-ved/repos/me/dotfiles/.stow-local-ignore:28-29`). Add `llm-capabilities/build/` to `.gitignore`.

### The STE gate: one core, thin adapters

- Split `ste-check.ts` into `core.ts` and `cli.ts`. `core.ts` keeps each rule: the trap table from `rules/ste.md`, `checkText`, `markdownProse`, `ghPayload`, the sign-off rule, and the budgets.
- `core.ts` must not call `process.exit`, read stdin, or use `Bun.file`. Then Bun (Claude Code, Codex, opencode) and Node with `jiti` (pi) can both load it.
- Give `core.ts` the rules directory as an argument. Today the gate finds it through `CLAUDE_CONFIG_DIR` or `~/.claude/rules` (`/Users/s-ved/repos/me/dotfiles/claude/.claude/hooks/ste-check.ts:75-78`).
- `cli.ts` keeps the `--file` mode and the Claude Code hook protocol. It also accepts the Codex dialect, with three changes:
  1. Do not print `suppressOutput`. Codex rejects it, and Claude Code ignores it.
  2. For `tool_name: "apply_patch"`, read the file names from the `*** Add File: `, `*** Update File: `, and `*** Move to: ` lines of `tool_input.command`. Resolve each name against the payload `cwd`. Then give each `.md` file to the checker.
  3. When `CLAUDE_PROJECT_DIR` is absent, use the payload `cwd` as the project directory.
- The opencode and pi adapters send `cli.ts` a Claude-shaped payload, and they read the Claude-shaped answer. Thus there is only one protocol parser, and the adapters only map fields:
  - opencode `tool.execute.before`, `bash`: send `{ hook_event_name: "PreToolUse", tool_name: "Bash", tool_input: { command }, cwd }`. On `permissionDecision: "deny"`, throw an `Error` with the reason.
  - opencode `tool.execute.after`, `write` or `edit`: send `PostToolUse` with `tool_name: "Write"` and `file_path` from `args.filePath`. For `apply_patch`, send the patch as Codex does. Append each `additionalContext` to `output.output`.
  - pi `tool_call`, `bash`: send the `PreToolUse` payload. On deny, return `{ block: true, reason }`.
  - pi `tool_result`, `write` or `edit`: send `PostToolUse` with `file_path` from `input.path`, resolved against `ctx.cwd`. Return the old content plus one text block.
- Spawn `cli.ts` as a subprocess from both adapters. A subprocess costs one Bun start for each call. But the harness process stays safe from a crash or an exit in the checker.
- The pi adapter must use `node:child_process`, because `pi.exec()` has no stdin. The opencode adapter can use `Bun.spawn`.
- An in-process import of `core.ts` is faster. It is possible only after the split above.

### Materialization for each harness

A new script, for example `scripts/llm.sh`, links everything, and `scripts/stow.sh` calls it. It must be safe to run again. It moves a file that is in the way into the backup directory, as `make_way` does today (`/Users/s-ved/repos/me/dotfiles/scripts/stow.sh:21-47`).

It must link leaf entries only, never a parent directory. Claude Code writes `skills/synced`, Codex writes `skills/.system`, and opencode writes `.gitignore`, `package.json`, and `node_modules` into its config directory.

| Target | Method | Path |
| --- | --- | --- |
| Stable home for all configs | Symlink | `~/.local/share/llm-capabilities` to `$DOTFILES/llm-capabilities` |
| Claude Code skills | Symlink for each skill | `~/.claude/skills/<name>` |
| Claude Code rules | Symlink | `~/.claude/rules` to `llm-capabilities/rules` |
| Claude Code hook | Edit the stowed `settings.json` one time | command `bun "$HOME/.local/share/llm-capabilities/ste/cli.ts"` |
| Codex, opencode, pi skills | Symlink for each skill | `~/.agents/skills/<name>` |
| Codex instructions | Symlink to a generated file | `~/.codex/AGENTS.md` to `build/AGENTS.md` |
| Codex hook | Symlink | `~/.codex/hooks.json` to `adapters/codex/hooks.json` |
| opencode instructions | Symlink to a generated file | `~/.config/opencode/AGENTS.md` to `build/AGENTS.md` |
| opencode gate | Symlink | `~/.config/opencode/plugins/ste-gate.ts` |
| pi instructions | Symlink to a generated file | `~/.pi/agent/AGENTS.md` to `build/AGENTS.md` |
| pi gate | Symlink | `~/.pi/agent/extensions/ste-gate.ts` |

The Codex hook file can be static. It uses `$HOME`, because Codex runs the command through `$SHELL -lc`:

```json
{
  "description": "llm-capabilities STE gate",
  "hooks": {
    "PreToolUse": [
      { "matcher": "^Bash$",
        "hooks": [{ "type": "command", "timeout": 15, "statusMessage": "STE check",
                    "command": "\"$HOME/.bun/bin/bun\" \"$HOME/.local/share/llm-capabilities/ste/cli.ts\"" }] }
    ],
    "PostToolUse": [
      { "matcher": "^apply_patch$",
        "hooks": [{ "type": "command", "timeout": 15, "statusMessage": "STE check",
                    "command": "\"$HOME/.bun/bin/bun\" \"$HOME/.local/share/llm-capabilities/ste/cli.ts\"" }] }
    ]
  }
}
```

What the script must do, in order:

1. Make these real directories if absent: `~/.claude/skills`, `~/.agents/skills`, `~/.codex`, `~/.config/opencode/plugins`, `~/.pi/agent/extensions`, and `~/.local/share`.
2. Make `build/AGENTS.md`. Put the rule files in one fixed order, and put a line at the top that says that the file is generated.
3. Link the entries in the table.
4. Move aside a skill copy that has the same name in `~/.codex/skills` or `~/.claude/skills`. Today `~/.codex/skills` holds real copies of `viv-load-context`, `viv-opsx-artifact-check`, and `viv-opsx-compact`, and Codex would show both copies.
5. Remove a link that points into `llm-capabilities/` but whose target is gone.
6. Print one reminder: open `/hooks` in Codex one time to trust the new hook, and do this again after each change to `hooks.json`.

Put `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` in the repository `.zshrc`. Then opencode reads each skill one time from `~/.agents/skills`, and a Claude-only skill in `~/.claude/skills` stays out of opencode. The cost: opencode then also skips `.claude/skills` in each project.

### What stays unchanged and what is generated

- Linked unchanged: each skill directory, the rules directory for Claude Code, the Codex `hooks.json`, and the two adapter files.
- Generated: only `build/AGENTS.md`. Codex, opencode, and pi each read a single user file, so one concatenated file serves all three.
- An edit of a rule file changes Claude Code at once, but the other three change only after the script runs again. A `--check` mode that compares `build/AGENTS.md` with `rules/*.md` finds this drift.
- Optional: for `permission.skill`, merge `"<name>": "deny"` into `~/.config/opencode/opencode.json` with `jq`. Do this only for skills with `disable-model-invocation: true`. The cost: the script then edits a file that the user owns.

### Skill bodies that work in each harness

- Do not name a harness tool. Write "read the whole file", "search the code", "run the shell command", and "ask the user". Today `viv-review-pr` and `viv-load-context` name `Read` and `Explore`, and `viv-opsx-artifact-check` names `AskUserQuestion`.
- Do not use `$ARGUMENTS`. Write "the text after the skill name, or the request in the conversation". Each harness delivers that text, but only Claude Code and the opencode slash command replace the placeholder. `viv-review-pr` uses it at line 13.
- Do not use `$SKILL_DIR` or `${CLAUDE_SKILL_DIR}`. Write the path relative to the skill directory, for example `scripts/scan.py`. All four harnesses tell the model the skill directory. `viv-opsx-compact` uses `$SKILL_DIR` at line 34.
- To reach another skill, write "load the `viv-domain-modeling` skill". Do not write "call the Skill tool". The target skill must stay model-invocable, because pi hides a `disable-model-invocation` skill from the model.
- Do not use `` !`command` `` lines. Claude Code runs them, opencode runs them only for a slash command, and Codex and pi do not run them.
- Write "the project instruction file (`AGENTS.md` or `CLAUDE.md`)" in place of `CLAUDE.md` alone.
- For subagent work, write "if the harness can start subagents, start one for each cluster. If it cannot, do the clusters one at a time". Today `viv-opsx-compact` calls `Workflow`, which works only in Claude Code, and that tool is off in this setup.
- Keep `disable-model-invocation: true` in the frontmatter for Claude Code and pi. Add `agents/openai.yaml` for Codex.
- Two rules also name Claude tools: `git.md:28` names the `isolation: "worktree"` option of the Agent tool, and `investigation.md:6` names `Read` and `Grep`. The generated `AGENTS.md` carries these names to the other harnesses. Rewrite them in neutral words.

## Gaps

- **The Codex hook environment.** Codex runs hooks with `$SHELL -lc` and a session snapshot of the environment. This research did not find which variables the snapshot holds. zsh reads `~/.zshrc` only for an interactive shell, and `~/.zshrc` is the file that adds `~/.bun/bin` to `PATH` (`/Users/s-ved/repos/me/dotfiles/.zshrc:89-91`). To settle it, trust a hook that prints `PATH` and look at the output. Until then, use the absolute path `$HOME/.bun/bin/bun` in `hooks.json`.
- **The error text in opencode.** The trigger wraps the plugin promise in `Effect.promise`, so a throw becomes a defect. This research did not find the exact text that reaches `errorText`. To settle it, run one opencode session with a plugin that throws.
- **opencode `instructions` globs and symlinked files.** The glob uses `node-glob` with `follow: false` and `nodir: true`. This research did not confirm that a symlinked rule file matches. The recommendation does not depend on it.
- **Symlinked adapter files.** This research did not confirm if `jiti` (pi) and Bun (opencode) resolve a relative import against the symlink or against its target. The recommendation uses absolute paths through `~/.local/share/llm-capabilities`, so it does not depend on it.
- **The Codex trust key for a symlinked `hooks.json`.** The key starts with the source path. This research did not confirm if Codex uses the link path or the target path. The `/hooks` menu shows the key.
- **Closed source.** Claude Code is not open source. Its claims come from the docs of 2026-09-19 and from `strings` output of the 2.1.278 binary, not from source code.
