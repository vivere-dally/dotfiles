# Maximum privacy for OpenAI Codex CLI 0.154.0

- Date of the research: 2026-09-19.
- Version: OpenAI Codex CLI 0.154.0. The command `codex --version` prints `codex-cli 0.154.0`. The binary is `/Users/s-ved/homebrew/Caskroom/codex/0.154.0/bin/codex`.
- Source: tag `rust-v0.154.0` of `github.com/openai/codex`. This research read a tarball of the tag, and the workspace `Cargo.toml` of that tarball sets `version = "0.154.0"`.
- Docs: each `developers.openai.com/codex/*` page now redirects to `learn.chatgpt.com/docs/*`. The citations use the address after the redirect. The page `developers.openai.com/codex/privacy` gives HTTP 404.
- A `strings` search of the binary finds each endpoint and key that this file names. Examples are `ab.chatgpt.com/otlp/v1/metrics`, `wham/settings/user`, `announcement_tip.toml`, and `config_toml_base64`.
- This research read files and web pages only. It started no Codex session, did no login, and ran no git command. It wrote nothing to `~/.codex`, to `/etc`, or to the macOS preferences.

In this file, `SRC` is a short name for `https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs`. Each source link goes to that tag, with line anchors.

## Summary

- Codex sends two kinds of usage data by default. Analytics events go to `chatgpt.com`, and OpenTelemetry metrics go to Statsig at `ab.chatgpt.com`. The key `analytics.enabled = false` stops both.
- Codex has no automatic crash reporter. Sentry gets data only when the user sends `/feedback`. The key `feedback.enabled = false` stops that path.
- At TUI start, Codex can fetch the newest version number, sync a plugin catalog, and connect to a hosted apps server. A config key stops each of the three.
- One fetch has no knob. Each TUI start downloads `announcement_tip.toml` from `raw.githubusercontent.com`.
- Each model request carries an installation ID, the path of the repository root, the git remote URLs, and the HEAD commit hash. No key stops this.
- Codex sets `store: false` on each Responses API request. The key `disable_response_storage` does not exist in 0.154.0.
- A ChatGPT account setting controls the commit and pull request attribution. No local key exists. When the setting is on, Codex tells the model to ignore earlier instructions against attribution.
- Codex has no switch that stops automatic compaction. Codex does not continue by itself at a usage limit.
- Codex writes to `~/.codex/config.toml` and resolves a symlink to write into its target. It also writes into an active `--profile` file. Thus the repository must own neither file.
- Recommendation: link a repository file to `/etc/codex/config.toml`. Each process of this binary reads that system layer, and Codex never writes it. Add a small `codex` shell function with `-c` flags, because session flags override a trusted project config.

## The Claude Code settings and their Codex equivalents

| Claude Code setting | Codex 0.154.0 equivalent | Notes |
| --- | --- | --- |
| `DISABLE_TELEMETRY` | `analytics.enabled = false`. Also set `otel.exporter`, `otel.trace_exporter`, and `otel.metrics_exporter` to `"none"`. | No environment variable exists. See section 1. |
| `DISABLE_ERROR_REPORTING` | `feedback.enabled = false` | Codex has no automatic crash report. `analytics.enabled = false` also stops the turn error events. See section 2. |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | No single switch. Set `check_for_update_on_startup = false`, `features.plugins = false`, and `features.apps = false`. | The announcement download stays. See sections 3 and 4. |
| Auto-updates | `check_for_update_on_startup = false` | Codex never installs an update without a prompt. See section 3. |
| Empty commit and pull request attribution, no `Co-Authored-By` | No local key. The ChatGPT account setting `commit_attribution_enabled` controls it. | See section 6. |
| No session URL | Nothing to set. Codex adds no session URL. | The pull request line links to `openai.com/codex`. |
| Feedback surveys off | Nothing to set. The source has no survey. | `feedback.enabled = false` blocks `/feedback`. |
| Workflows off | `features.goals = false` | A goal makes Codex start new turns by itself. `features.multi_agent` controls subagents. See section 7. |
| Auto-compact off | No switch. `model_auto_compact_token_limit` can only lower the limit. | Codex caps the limit at 90% of the context window. See section 7. |
| Auto-continue at the usage limit off | Nothing to set. | At a usage limit, Codex stops the active goal. See section 7. |

## 1. Telemetry, analytics, and OpenTelemetry

Codex has two separate usage channels. Both are on by default in the TUI and in `codex exec`.

- Analytics events. Codex posts JSON batches to `<chatgpt_base_url>/codex/analytics-events/events` ([SRC analytics/src/client.rs L114-L143](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/client.rs#L114-L143)).
- The default base URL is `https://chatgpt.com/backend-api/` ([SRC core/src/config/mod.rs L4281-L4283](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L4281-L4283)). The event queue exists unless `analytics.enabled` is `false` ([SRC analytics/src/client.rs L239-L250](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/client.rs#L239-L250)).
- The events cover plugins, skills, MCP calls, hook runs, token use, the resolved config, compaction, and turn errors ([SRC analytics/src/client.rs L283-L741](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/client.rs#L283-L741)).
- An accepted-lines event carries the counts of added and deleted lines. It also carries a SHA-1 hash of the git remote URL ([SRC analytics/src/accepted_lines.rs L106-L118](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/accepted_lines.rs#L106-L118), [SRC analytics/src/events.rs L176-L190](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/events.rs#L176-L190)).
- Codex sends all events only with a ChatGPT login. With an API key, it sends only the plugin events ([SRC analytics/src/client.rs L832-L856](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/client.rs#L832-L856), [SRC analytics/src/events.rs L164-L173](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/events.rs#L164-L173)).
- Metrics. The default `otel.metrics_exporter` is `statsig` ([SRC core/src/config/otel.rs L13-L21](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/otel.rs#L13-L21)).
- Codex resolves `statsig` to an OTLP HTTP exporter for `https://ab.chatgpt.com/otlp/v1/metrics`, with an API key in the binary ([SRC otel/src/config.rs L9-L36](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/otel/src/config.rs#L9-L36)).
- When `analytics.enabled` is `false`, Codex uses no metrics exporter, whatever the value of `otel.metrics_exporter` is ([SRC core/src/otel_init.rs L68-L77](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/otel_init.rs#L68-L77)).
- When the key is absent, the TUI and `codex exec` read it as `true` ([SRC tui/src/startup_orchestration.rs L420-L426](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/startup_orchestration.rs#L420-L426), [SRC exec/src/lib.rs L173](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/exec/src/lib.rs#L173)).
- For metrics, `codex app-server` reads an absent key as `false`, unless the client gives `--analytics-default-enabled`. The comment in the source says that the IDE extension gives it ([SRC cli/src/main.rs L580-L596](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cli/src/main.rs#L580-L596), [SRC app-server/src/main.rs L113-L118](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/main.rs#L113-L118)).
- The help text of `codex app-server` says that analytics are off by default. For the events, the source disagrees ([SRC app-server/src/analytics_utils.rs L7-L16](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/analytics_utils.rs#L7-L16), [SRC app-server/src/lib.rs L922](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/lib.rs#L922)).
- The source wins. The app-server builds the events client from `analytics.enabled` alone. Thus only an explicit `false` stops the events.
- The export of OpenTelemetry logs and traces is off by default. `otel.exporter` and `otel.trace_exporter` default to `none` ([SRC core/src/config/otel.rs L17-L20](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/otel.rs#L17-L20)).
- A project `.codex/config.toml` cannot set any `otel` key ([SRC config/src/loader/mod.rs L71-L88](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L71-L88)).
- The docs agree that the metrics are on by default and that `[analytics] enabled = false` stops them ([config-advanced, metrics](https://learn.chatgpt.com/docs/config-file/config-advanced#metrics)).
- The security page says that telemetry is off by default ([agent-approvals-security, monitoring and telemetry](https://learn.chatgpt.com/docs/agent-approvals-security#monitoring-and-telemetry)). That sentence is true for the OpenTelemetry log export only.
- No environment variable controls telemetry. A search of the source for `DO_NOT_TRACK`, `OTEL_SDK_DISABLED`, and each string literal that starts with `CODEX_` found no telemetry switch.
- A `strings` search of the binary found no `DO_NOT_TRACK` and no `OTEL_SDK_DISABLED`.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `analytics.enabled` | bool | Absent. The TUI, `codex exec`, and the IDE extension read an absent value as on. | `false` stops the analytics events and the Statsig metrics. | [config_toml.rs L504-L506](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L504-L506), [types.rs L216-L224](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L216-L224), [otel_init.rs L68-L77](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/otel_init.rs#L68-L77) |
| `otel.metrics_exporter` | `none`, `statsig`, `otlp-http`, `otlp-grpc` | `statsig` | The target of the metrics. `analytics.enabled = false` overrides it. | [types.rs L550-L629](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L550-L629), [core otel.rs L21](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/otel.rs#L21) |
| `otel.exporter` | `none`, `otlp-http`, `otlp-grpc` | `none` | The target of the log events. | [core otel.rs L17](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/otel.rs#L17) |
| `otel.trace_exporter` | `none`, `otlp-http`, `otlp-grpc` | `none` | The target of the traces. | [core otel.rs L20](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/otel.rs#L20) |
| `otel.log_user_prompt` | bool | `false` | Puts the prompt text into the exported logs. | [types.rs L581-L582](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L581-L582), [core otel.rs L13](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/otel.rs#L13) |
| `features.runtime_metrics` | bool | `false`, under development | Adds runtime metrics to the metrics exporter. | [features lib.rs L1089-L1093](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1089-L1093), [otel_init.rs L81](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/otel_init.rs#L81) |
| `codex app-server --analytics-default-enabled` | flag | Off | Makes an absent `analytics.enabled` mean on for the metrics of that app-server. | [cli main.rs L580-L596](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cli/src/main.rs#L580-L596) |

## 2. Error and crash reporting

- Codex has no automatic crash reporter. Only the `feedback` crate depends on the `sentry` crate ([SRC feedback/Cargo.toml L20](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/feedback/Cargo.toml#L20)).
- The panic hooks of the TUI restore the terminal and give the panic text to the tracing log. They send nothing over the network by themselves ([SRC tui/src/lib.rs L1060-L1069](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/lib.rs#L1060-L1069), [SRC tui/src/tui.rs L553-L559](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/tui.rs#L553-L559)).
- The command `/feedback` sends a Sentry envelope to `o33249.ingest.us.sentry.io` ([SRC feedback/src/lib.rs L57-L58](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/feedback/src/lib.rs#L57-L58), [SRC feedback/src/lib.rs L564-L575](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/feedback/src/lib.rs#L564-L575)).
- With logs on, the upload also carries rows of the local log database and the session rollout file. The rollout file holds the full transcript ([SRC app-server feedback_processor.rs L128-L215](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/request_processors/feedback_processor.rs#L128-L215)).
- When `feedback.enabled` is `false`, the app-server rejects each upload, and `/feedback` shows a message ([SRC feedback_processor.rs L57-L65](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/request_processors/feedback_processor.rs#L57-L65), [SRC tui/src/chatwidget/slash_dispatch.rs L172](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/chatwidget/slash_dispatch.rs#L172)).
- The same key stops Codex from keeping records of failed auto-reviews for a later upload ([SRC core/src/guardian/feedback.rs L37-L44](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/guardian/feedback.rs#L37-L44)).
- Codex also sends turn errors as analytics events ([SRC analytics/src/client.rs L538-L542](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/client.rs#L538-L542)). The key `analytics.enabled = false` stops them.
- The docs agree for `/feedback` ([config-advanced, feedback controls](https://learn.chatgpt.com/docs/config-file/config-advanced#feedback-controls)).

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `feedback.enabled` | bool | `true` | `false` blocks `/feedback` uploads to Sentry and the records of failed auto-reviews. | [config_toml.rs L508-L510](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L508-L510), [config/mod.rs L4343-L4347](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L4343-L4347) |
| `[feedback] enabled` in `requirements.toml` | bool | Absent | Pins the value. No config layer can change it. | [config_requirements.rs L994](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_requirements.rs#L994), [core requirements.rs L47-L51](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/requirements.rs#L47-L51) |
| `analytics.enabled` | bool | On | `false` stops the turn error events. | See section 1. |

## 3. Update checks, announcements, and "what's new"

- In a release build, the TUI reads `$CODEX_HOME/version.json` at start. If the file is absent or older than 20 hours, a background task fetches the newest version ([SRC tui/src/updates.rs L27-L58](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/updates.rs#L27-L58)).
- For a Homebrew install, the task reads `https://formulae.brew.sh/api/cask/codex.json`. For other installs, it reads the GitHub API for `openai/codex/releases/latest`, and for an npm-style install also the npm registry ([SRC tui/src/updates.rs L60-L131](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/updates.rs#L60-L131)).
- The request carries the `originator` header and a `User-Agent` header ([SRC login/src/auth/default_client.rs L335-L351](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L335-L351)).
- `check_for_update_on_startup = false` stops the fetch and the update prompt ([SRC tui/src/updates.rs L27-L30](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/updates.rs#L27-L30), [SRC tui/src/updates.rs L151-L154](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/updates.rs#L151-L154)). The default is `true` ([SRC core/src/config/mod.rs L3968](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L3968)).
- Codex never updates itself without a prompt. The TUI shows a prompt, and only the choice of the user runs `brew upgrade --cask codex` ([SRC tui/src/update_prompt.rs L36-L45](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/update_prompt.rs#L36-L45), [SRC tui/src/update_action.rs L51](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/update_action.rs#L51)).
- The command `codex update` runs only when the user types it.
- The announcement download has no knob. Each TUI start downloads `https://raw.githubusercontent.com/openai/codex/main/announcement_tip.toml` in the background ([SRC tui/src/tooltips.rs L6-L7](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/tooltips.rs#L6-L7), [SRC tui/src/tooltips.rs L170-L179](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/tooltips.rs#L170-L179)).
- The call site has no condition around it ([SRC tui/src/lib.rs L1058](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/lib.rs#L1058)). `tui.show_tooltips = false` hides the tip, but the download still occurs ([SRC tui/src/history_cell/session.rs L189-L191](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/history_cell/session.rs#L189-L191)).
- On this machine, `/Users/s-ved/.codex/version.json` records a check on 2026-09-18 that found `0.155.0`.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `check_for_update_on_startup` | bool | `true` | `false` stops the version fetch and the update prompt. | [config_toml.rs L496-L499](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L496-L499), [updates.rs L27-L30](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/updates.rs#L27-L30) |
| `check_for_update_on_startup` in `requirements.toml` | bool | Absent | Pins the value. | [config_requirements.rs L992](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_requirements.rs#L992), [core requirements.rs L38](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/requirements.rs#L38) |
| `tui.show_tooltips` | bool | `true` | Hides the startup tips. The announcement download continues. | [types.rs L739-L742](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L739-L742) |
| Announcement download | No knob | On | Gets `announcement_tip.toml` from GitHub at each TUI start. | [tooltips.rs L170-L179](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/tooltips.rs#L170-L179), [tui lib.rs L1058](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/lib.rs#L1058) |

## 4. Other background network

- Plugins. With `features.plugins` on, each start syncs the curated repository `https://github.com/openai/plugins.git` into `$CODEX_HOME/.tmp/plugins` ([SRC core-plugins/src/startup_sync.rs L23-L34](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/startup_sync.rs#L23-L34)).
- The sync uses git, the GitHub API, or a backup archive at `chatgpt.com/backend-api/plugins/export/curated` ([SRC core-plugins/src/startup_sync.rs L77-L160](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/startup_sync.rs#L77-L160), [SRC core-plugins/src/manager.rs L708-L725](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/manager.rs#L708-L725)).
- With a ChatGPT login and `features.remote_plugin` on, Codex reads a remote plugin catalog in place of the GitHub sync ([SRC core-plugins/src/manager.rs L704-L706](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/manager.rs#L704-L706)).
- The same start also upgrades each configured marketplace automatically ([SRC core-plugins/src/manager.rs L2752-L2790](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/manager.rs#L2752-L2790)). `features.plugins = false` stops the sync, the remote catalog, and the upgrade.
- On this machine, `~/.codex/.tmp/plugins` and `~/.codex/cache/remote_plugin_catalog` exist.
- Apps, which are the connectors. With `features.apps` on, Codex adds a hosted MCP server named `codex_apps` at `https://chatgpt.com/backend-api/ps/mcp` ([SRC ext/mcp/src/lib.rs L35-L47](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/mcp/src/lib.rs#L35-L47), [SRC codex-mcp/src/mcp/mod.rs L583-L590](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/codex-mcp/src/mcp/mod.rs#L583-L590)).
- `features.apps = false` removes that server. On this machine, `~/.codex/cache/codex_apps_tools` exists.
- Tool suggestions work only when `tool_suggest`, `apps`, and `plugins` are all on ([SRC core/src/tools/spec_plan.rs L633-L638](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/spec_plan.rs#L633-L638)). Thus `apps = false` or `plugins = false` also removes them.
- Model catalog. With a ChatGPT login, Codex fetches the model list from the provider. It keeps the list in `$CODEX_HOME/models_cache.json` for 300 seconds ([SRC models-manager/src/manager.rs L29-L30](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/models-manager/src/manager.rs#L29-L30), [SRC models-manager/src/manager.rs L375-L439](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/models-manager/src/manager.rs#L375-L439)).
- `model_catalog_json` replaces the fetch with a static file ([SRC model-provider/src/provider.rs L449-L465](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/model-provider/src/provider.rs#L449-L465)). The fetch goes to the same backend as the prompts, thus the privacy gain is small.
- Attribution policy. With a ChatGPT login, each thread reads `commit_attribution_enabled` from `<chatgpt_base_url>/wham/settings/user` ([SRC ext/git-attribution/src/policy.rs L52-L91](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/policy.rs#L52-L91), [SRC backend-client/src/client.rs L671-L676](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/backend-client/src/client.rs#L671-L676)). No key stops this fetch.
- Cloud config. Codex fetches a managed config bundle only for Business, Education, and Enterprise plans ([SRC cloud-config/src/service.rs L50-L58](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cloud-config/src/service.rs#L50-L58)).
- Remote control. Only `codex remote-control` and `codex app-server` start it. The in-process app-server of the TUI has no remote control ([SRC app-server/src/in_process.rs L489](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/in_process.rs#L489)).
- Installation ID. Codex keeps a random UUID in `$CODEX_HOME/installation_id` ([SRC core/src/installation_id.rs L17-L62](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/installation_id.rs#L17-L62)).
- Codex sends that UUID with each model request as `x-codex-installation-id` ([SRC core/src/responses_metadata.rs L307-L316](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/responses_metadata.rs#L307-L316), [SRC core/src/client.rs L153](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/client.rs#L153)). No key stops this.
- Web search. The default mode is `cached`, and `disabled` removes the tool ([SRC core/src/config/mod.rs L3686-L3687](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L3686-L3687), [SRC protocol/src/config_types.rs L375-L381](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/config_types.rs#L375-L381)).
- The `in_app_updates` feature is on by default, but no Rust code outside its definition reads it. A search of the tree for `InAppUpdates` and `in_app_updates` found the definition only.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `features.plugins` | bool | `true` | `false` stops the curated sync, the remote catalog, and the marketplace upgrade. | [features lib.rs L1361-L1365](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1361-L1365), [manager.rs L2752-L2790](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/manager.rs#L2752-L2790) |
| `features.remote_plugin` | bool | `true` | With a ChatGPT login, uses the remote catalog in place of the GitHub sync. | [features lib.rs L1439-L1443](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1439-L1443), [manager.rs L704-L706](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core-plugins/src/manager.rs#L704-L706) |
| `features.apps` | bool | `true` | `false` removes the hosted `codex_apps` MCP server. | [features lib.rs L1283-L1287](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1283-L1287), [ext/mcp lib.rs L35-L47](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/mcp/src/lib.rs#L35-L47) |
| `apps._default.enabled`, `apps.<id>.enabled` | bool | `true` | Hides all apps, or one app. | [types.rs L405-L528](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L405-L528) |
| `features.tool_suggest` | bool | `true` | Lets the model suggest a plugin or connector install. Works only with `apps` and `plugins`. | [features lib.rs L1349-L1353](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1349-L1353), [spec_plan.rs L633-L638](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/tools/spec_plan.rs#L633-L638) |
| `features.recommended_plugins` | bool | `false` | Plugin recommendations. | [features lib.rs L1355-L1359](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1355-L1359) |
| `model_catalog_json` | path | Absent | A static model catalog. No fetch of the model list. | [config_toml.rs L377-L379](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L377-L379), [provider.rs L449-L465](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/model-provider/src/provider.rs#L449-L465) |
| `web_search` | `disabled`, `cached`, `indexed`, `live` | `cached` | `disabled` removes the web search tool. | [config_toml.rs L445-L446](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L445-L446), [config/mod.rs L3686-L3687](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L3686-L3687) |
| Announcement, attribution policy, installation ID | No knob | On | See above. | See above. |

## 5. Data that OpenAI gets or keeps

- Response storage. Codex sets `store: false` on each Responses API request ([SRC core/src/client.rs L978-L994](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/client.rs#L978-L994)).
- A search of the tagged tree for `disable_response_storage` found nothing. A search of the Rust code for `store: true` also found nothing. Thus that key does not exist in 0.154.0, and no setting applies.
- Turn metadata. Each model request carries the `x-codex-turn-metadata` header. The `client_metadata` field carries the same data ([SRC core/src/responses_metadata.rs L213-L374](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/responses_metadata.rs#L213-L374)).
- The data holds the installation ID, the session, thread, and turn IDs, the sandbox mode, and a `workspaces` map ([SRC core/src/responses_metadata.rs L376-L423](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/responses_metadata.rs#L376-L423)).
- Each key of `workspaces` is the absolute path of a repository root. Each value holds the git remote URLs, the HEAD commit hash, and a flag for local changes ([SRC core/src/turn_metadata.rs L523-L551](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/turn_metadata.rs#L523-L551)).
- A fresh turn in a local environment always starts this git task ([SRC core/src/session/turn_context.rs L1043-L1052](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/session/turn_context.rs#L1043-L1052)). No key stops it.
- `responses_api_metadata` adds your own keys to the same data. The default is empty ([SRC config/src/config_toml.rs L394-L395](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L394-L395)).
- Feedback. With logs on, `/feedback` sends the transcript to Sentry (see section 2). `feedback.enabled = false` stops it.
- Session sharing. The list of slash commands has no share command. `/export` writes Markdown on the local machine ([SRC tui/src/slash_command.rs L91-L154](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/slash_command.rs#L91-L154)).
- Cloud tasks. Only the `codex cloud` subcommand uses the cloud tasks client. A search of `tui/src`, `app-server/src`, and `core/src` for that client found no use.
- Secrets in the environment of a command. By default, each command that Codex runs gets every environment variable, and that includes names with `KEY`, `SECRET`, or `TOKEN` ([SRC config/src/shell_environment_policy.rs L135-L136](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/shell_environment_policy.rs#L135-L136)).
- `shell_environment_policy.ignore_default_excludes = false` removes those variables from the commands ([SRC protocol/src/shell_environment.rs L124-L128](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/shell_environment.rs#L124-L128)). Then a command cannot print them into the transcript.
- The docs say the same about `ignore_default_excludes` ([config-basic](https://learn.chatgpt.com/docs/config-file/config-basic)).

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `store` on each request | No knob | Always `false` | Codex asks the Responses API not to store the response. | [client.rs L986](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/client.rs#L986) |
| Turn metadata | No knob | On | Sends the repository root path, the remote URLs, the HEAD hash, and the installation ID. | [turn_metadata.rs L523-L551](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/turn_metadata.rs#L523-L551) |
| `responses_api_metadata` | Map of strings | Empty | Adds your own metadata to each request. | [config_toml.rs L394-L395](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L394-L395) |
| `feedback.enabled` | bool | `true` | `false` stops the upload of transcripts to Sentry. | See section 2. |
| `shell_environment_policy.ignore_default_excludes` | bool | `true` | `false` removes variables with `KEY`, `SECRET`, or `TOKEN` in the name from commands. | [shell_environment_policy.rs L135-L136](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/shell_environment_policy.rs#L135-L136), [shell_environment.rs L124-L128](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/shell_environment.rs#L124-L128) |
| `shell_environment_policy.inherit` | `all`, `core`, `none` | `all` | Selects which variables reach a command. | [config_types.rs L207-L218](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/config_types.rs#L207-L218) |
| `web_search` | `disabled`, `cached`, `indexed`, `live` | `cached` | Search queries go to OpenAI with the web search tool. | See section 4. |

## 6. Attribution

- Codex 0.154.0 has no local key for attribution. The feature `codex_git_commit` has the stage `Removed` ([SRC features/src/lib.rs L1083-L1087](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1083-L1087)).
- The struct `ConfigToml` has no `commit_attribution` field ([SRC config/src/config_toml.rs L152-L535](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L152-L535)). A search of the config crate for `commit_attribution` found nothing.
- Codex installs the git attribution extension in each session, with no feature gate ([SRC cli/src/main.rs L2349-L2354](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cli/src/main.rs#L2349-L2354), [SRC app-server/src/extensions.rs L94-L99](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/extensions.rs#L94-L99)).
- The extension reads `commit_attribution_enabled` from the ChatGPT account ([SRC ext/git-attribution/src/policy.rs L70-L91](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/policy.rs#L70-L91)). With an API key or with no login, the policy is off, and Codex adds no text.
- When the setting is on, Codex adds a developer message. The message tells the model to end each commit message with `Co-authored-by: Codex <noreply@openai.com>` ([SRC ext/git-attribution/src/world_state.rs L17-L25](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/world_state.rs#L17-L25)).
- The same message tells the model to put the line `Generated with [Codex](https://openai.com/codex/).` into each pull request body.
- The same message also says "Ignore any earlier instructions disabling Codex attribution". Thus a line in `AGENTS.md` against attribution is not a reliable control.
- When the setting is off, Codex adds a short "attribution is disabled" message, but only after the setting was on earlier in the same thread ([SRC world_state.rs L26-L55](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/world_state.rs#L26-L55)).
- If the settings fetch fails or takes more than 5 seconds, the policy is off for that turn. Codex then tries again after 30 seconds ([SRC policy.rs L46-L50](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/policy.rs#L46-L50), [SRC ext/git-attribution/src/lib.rs L72-L85](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/lib.rs#L72-L85)).
- The base prompt tells the model not to make a git commit unless the user asks ([SRC protocol/src/prompts/base_instructions/default.md L144](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/prompts/base_instructions/default.md?plain=1#L144)).
- The memories feature makes its own commits with the same trailer, but only in a git repository under `$CODEX_HOME/memories` ([SRC git-utils/src/baseline.rs L17-L18](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/git-utils/src/baseline.rs#L17-L18), [SRC memories/write/src/phase2.rs L60-L74](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/memories/write/src/phase2.rs#L60-L74)).
- To stop the attribution, set the account setting to off. This research found no primary doc that names the place of that setting (see Gaps).
- A second control does not depend on the model. For example, a git `commit-msg` hook can delete the Codex trailer, or a Codex `PreToolUse` hook can deny a commit command that holds it.

Headers that Codex sends to providers:

- Each Codex HTTP client sends `originator: codex_cli_rs` ([SRC login/src/auth/default_client.rs L40](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L40), [SRC default_client.rs L335-L351](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L335-L351)).
- The `User-Agent` holds the Codex version, the OS type, the OS version, and the CPU architecture ([SRC default_client.rs L164-L175](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L164-L175)).
- Model requests also carry `x-codex-installation-id`, `x-codex-window-id`, and `x-codex-turn-metadata`. A subagent request also carries `x-openai-subagent` ([SRC responses_metadata.rs L307-L374](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/responses_metadata.rs#L307-L374)).
- No config key changes these headers. The variable `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` changes the `originator` value ([SRC default_client.rs L41](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L41), [SRC default_client.rs L64-L67](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L64-L67)). This research does not recommend it.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| ChatGPT account setting `commit_attribution_enabled` | bool, on the server | Unknown | Adds the commit trailer and the pull request line. | [policy.rs L70-L91](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/policy.rs#L70-L91), [world_state.rs L17-L25](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/world_state.rs#L17-L25) |
| `features.codex_git_commit` | Removed | Not applicable | No effect in 0.154.0. | [features lib.rs L1083-L1087](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1083-L1087) |
| Login with an API key | Login mode | Not applicable | Codex adds no attribution text. | [policy.rs L90](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/git-attribution/src/policy.rs#L90) |
| `CODEX_INTERNAL_ORIGINATOR_OVERRIDE` | Environment variable | Absent | Changes the `originator` header. Not recommended. | [default_client.rs L41-L67](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/login/src/auth/default_client.rs#L41-L67) |

## 7. Uncontrolled behavior

These knobs stop actions that Codex starts without a request from the user.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `tui.auto_recap` | bool | `true` | After 3 completed turns and 3 minutes with the terminal unfocused, the TUI sends a recap request to the model. `false` stops it. `/recap` stays available. | [types.rs L744-L747](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L744-L747), [recap.rs L34-L36](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/app/recap.rs#L34-L36), [recap.rs L186-L195](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/app/recap.rs#L186-L195) |
| `features.goals` | bool | `true` | Gives the model a `create_goal` tool. With an active goal, Codex starts a new turn by itself when idle. | [features lib.rs L1589-L1593](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1589-L1593), [goal spec.rs L43-L48](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/goal/src/spec.rs#L43-L48), [goal runtime.rs L215-L231](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/goal/src/runtime.rs#L215-L231) |
| `features.skill_mcp_dependency_install` | bool | `true` | Offers to install the MCP servers that a skill names, into the global config. With `approval_policy = "never"` and full disk write, it installs with no prompt. | [features lib.rs L1499-L1503](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1499-L1503), [mcp_skill_dependencies.rs L256-L273](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/mcp_skill_dependencies.rs#L256-L273), [codex-mcp mod.rs L90-L109](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/codex-mcp/src/mcp/mod.rs#L90-L109) |
| `features.memories` | bool | `false` | Background memory extraction and consolidation, with model calls. | [features lib.rs L1101-L1105](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1101-L1105), [memories start.rs L24-L38](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/memories/write/src/start.rs#L24-L38) |
| `service_tier` | string | Absent | When absent, the model catalog can select a default tier, for example a fast tier. `"default"` keeps the standard tier. | [config_toml.rs L384-L386](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L384-L386), [service_tier_resolution.rs L6-L40](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/service_tier_resolution.rs#L6-L40) |
| `features.fast_mode` | bool | `true` | With `false`, the TUI sends no service tier. | [features lib.rs L1661-L1665](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1661-L1665), [service_tier_resolution.rs L22-L24](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/service_tier_resolution.rs#L22-L24) |
| `features.unbounded_connection_retries` | bool | `true` | Retries a failed connection with no limit. | [features lib.rs L1227-L1231](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1227-L1231), [responses_retry.rs L58-L83](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/responses_retry.rs#L58-L83) |
| `features.multi_agent`, `agents.enabled` | bool | `true` | Subagent tools for the model. | [features lib.rs L1259-L1263](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1259-L1263), [config_toml.rs L682-L685](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L682-L685) |
| `notify` | Array of strings | Absent | Runs an external program after each turn. | [config_toml.rs L226-L228](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L226-L228) |
| `tui.notifications` | bool or list | `true` | Terminal notifications with OSC 9 or BEL. Local only. | [types.rs L631-L709](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L631-L709) |
| `model_auto_compact_token_limit` | integer | Absent | Lowers the compaction limit. No value stops compaction, because the limit is at most 90% of the context window. | [config_toml.rs L167-L172](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L167-L172), [openai_models.rs L515-L526](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/openai_models.rs#L515-L526) |
| Usage limit | No knob | Not applicable | Codex does not continue by itself. It marks the active goal `UsageLimited` and stops it. A usage reset needs a confirmation from the user. | [goal runtime.rs L260-L297](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/ext/goal/src/runtime.rs#L260-L297), [usage.rs L248-L262](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/chatwidget/usage.rs#L248-L262) |
| Update install | No knob | Not applicable | Codex asks before it runs an update. | [update_prompt.rs L36-L45](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/update_prompt.rs#L36-L45) |
| Daemon reuse | No knob | Not applicable | With no `-c` flag, the TUI connects to a local app-server daemon if its socket answers. The daemon keeps the config that it read at its own start. | [tui lib.rs L988-L999](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/lib.rs#L988-L999), [startup_orchestration.rs L151-L160](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/startup_orchestration.rs#L151-L160) |

### Approval and sandbox knobs

These knobs are not privacy knobs. The defaults already ask before a risky action.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `approval_policy` | `on-request`, `never`, or a `granular` table | `on-request` | When Codex asks the user. The enum also has `untrusted`, and the source marks it as internal. The docs say that `untrusted` is retired as a policy value. | [protocol.rs L984-L1007](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/protocol.rs#L984-L1007), [config-reference](https://learn.chatgpt.com/docs/config-file/config-reference) |
| `approvals_reviewer` | `user`, `auto_review` | `user` | Who answers an approval request. | [config_types.rs L180-L190](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/protocol/src/config_types.rs#L180-L190) |
| `sandbox_mode` | `read-only`, `workspace-write`, `danger-full-access` | `read-only`. With a trust decision for the project, `workspace-write`. | The sandbox of model commands. | [config_toml.rs L758-L776](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L758-L776) |
| `sandbox_workspace_write.network_access` | bool | `false` | Network access for commands in `workspace-write`. | [types.rs L976-L987](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L976-L987) |
| `default_permissions`, `[permissions.<name>]` | string, table | Absent | Named permission profiles. | [config_toml.rs L217-L224](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L217-L224) |
| `projects."<path>".trust_level` | `trusted`, `untrusted` | Absent | Codex writes it after the trust prompt. | [config/mod.rs L2327-L2338](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L2327-L2338) |
| `features.guardian_approval` | bool | `true` | The auto-review agent, used only with `approvals_reviewer = "auto_review"`. | [features lib.rs L1547-L1551](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L1547-L1551) |
| `--dangerously-bypass-approvals-and-sandbox`, alias `--yolo` | Flag | Off | No prompts and no sandbox. | [shared_options.rs L52-L59](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/utils/cli/src/shared_options.rs#L52-L59) |
| `--approve-for-me` | Flag | Off | Automatic review in `workspace-write`. | [shared_options.rs L43-L50](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/utils/cli/src/shared_options.rs#L43-L50) |
| `--dangerously-bypass-hook-trust` | Flag | Off | Runs hooks with no trust record. | [shared_options.rs L61-L64](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/utils/cli/src/shared_options.rs#L61-L64) |

## 8. Local persistence (knobs only)

This section lists the knobs. It does not recommend a change.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `history.persistence` | `save-all`, `none` | `save-all` | Writes `$CODEX_HOME/history.jsonl`. | [types.rs L193-L214](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L193-L214), [defaults.toml](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/defaults.toml) |
| `history.max_bytes` | integer | Absent, no limit | Drops the oldest entries above the limit. | [types.rs L201-L203](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L201-L203) |
| `sqlite_home`, `CODEX_SQLITE_HOME` | path | `$CODEX_HOME` | Place of `state_5.sqlite`, `logs_2.sqlite`, `goals_1.sqlite`, `memories_1.sqlite`, `queue_1.sqlite`, and `thread_history_1.sqlite`. | [config_toml.rs L346-L348](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L346-L348), [state sqlite.rs L29-L34](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/state/src/sqlite.rs#L29-L34) |
| `log_dir` | path | `$CODEX_HOME/log` | Place of the log files. A set value also starts the text log of the TUI. | [config_toml.rs L350-L353](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L350-L353) |
| `codex exec --ephemeral` | Flag | Off | No session files for that run. | `codex exec --help` of the installed binary |
| `features.memories`, `[memories]` | bool, table | Feature off | Memory files under `$CODEX_HOME/memories` and `memories_1.sqlite`. | [types.rs L289-L357](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L289-L357) |
| `features.shell_snapshot` | bool | `true` | Writes the shell state, with the exported variables, to `$CODEX_HOME/shell_snapshots`. Codex keeps each file for 3 days. | [features lib.rs L963-L967](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/features/src/lib.rs#L963-L967), [shell_snapshot.rs L45-L47](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/shell_snapshot.rs#L45-L47), [shell-command shell_snapshot.rs L56-L61](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/shell-command/src/shell_snapshot.rs#L56-L61) |
| `cli_auth_credentials_store` | `file`, `keyring`, `auto`, `ephemeral` | `file` | Place of the login credentials. | [types.rs L106-L119](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/types.rs#L106-L119) |
| `mcp_oauth_credentials_store` | `auto`, `file`, `keyring` | `auto` | Place of the MCP OAuth credentials. | [config_toml.rs L279-L285](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L279-L285) |
| `installation_id`, `version.json`, `models_cache.json` | No knob | Written | Codex writes these files in `$CODEX_HOME`. | See sections 3 and 4. |
| `CODEX_HOME` | Environment variable | `~/.codex` | Moves all of the above. | [home-dir lib.rs L13-L63](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/utils/home-dir/src/lib.rs#L13-L63) |

## Config mechanics

### Layers and precedence

The source gives each layer a precedence number. A higher number overrides a lower number ([SRC config/src/config_layer_source.rs L30-L52](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_layer_source.rs#L30-L52), [SRC config/src/loader/mod.rs L109-L122](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L109-L122)).

| Precedence | Layer | Place on macOS | Loaded when | Source |
| --- | --- | --- | --- | --- |
| -10 | Packaged defaults | Inside the binary (`config/defaults.toml`) | Always | [loader/mod.rs L172-L187](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L172-L187) |
| 10 | System | `/etc/codex/config.toml` | The file exists | [loader/mod.rs L65-L66](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L65-L66), [loader/mod.rs L294-L312](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L294-L312) |
| 15 | Enterprise cloud bundle | Fetched from ChatGPT | Business, Education, and Enterprise plans | [loader/mod.rs L200-L214](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L200-L214) |
| 20 | User | `$CODEX_HOME/config.toml` | Always | [loader/mod.rs L314-L349](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L314-L349) |
| 21 | User profile | `$CODEX_HOME/<name>.config.toml` | `--profile <name>` or `-p <name>` | [loader/mod.rs L351-L362](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L351-L362), [config/mod.rs L1939-L1947](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L1939-L1947) |
| 25 | Project | Each `.codex/config.toml` from the project root down to the working directory | The project is trusted | [loader/mod.rs L364-L438](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L364-L438) |
| 30 | Session flags | `-c key=value`, `--enable`, `--disable`, and other flags | Given on the command line | [loader/mod.rs L440-L446](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L440-L446) |
| 40 | Legacy managed file | `/etc/codex/managed_config.toml` | The file exists | [layer_io.rs L21-L22](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/layer_io.rs#L21-L22), [loader/mod.rs L452-L478](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L452-L478) |
| 50 | Legacy managed preferences | Domain `com.openai.codex`, key `config_toml_base64` | The value exists | [macos.rs L20-L22](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/macos.rs#L20-L22), [loader/mod.rs L479-L497](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L479-L497) |

- The enum also has an `Mdm` source with precedence 0. The loader makes no config layer of that kind. The macOS preference becomes the layer with precedence 50.
- Requirements are a separate stack. From low to high, the stack is `/etc/codex/requirements.toml`, the cloud requirements, the legacy managed file, and the preference key `requirements_toml_base64` ([SRC loader/mod.rs L94-L108](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L94-L108), [SRC loader/mod.rs L200-L254](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L200-L254)).
- A requirement constrains a value, and no config layer can override it. Requirements can pin `check_for_update_on_startup`, `feedback`, and `[features]`. They cannot pin `analytics`, `otel`, or `tui` ([SRC config/src/config_requirements.rs L984-L1027](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_requirements.rs#L984-L1027)).
- In the legacy managed file, `approval_policy`, `approvals_reviewer`, and `sandbox_mode` also become requirements ([SRC loader/mod.rs L956-L993](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L956-L993)).
- The docs agree for layers 10 to 30 ([config-basic, configuration precedence](https://learn.chatgpt.com/docs/config-file/config-basic#configuration-precedence)). The docs also say that the managed file and the managed preference override the CLI flags ([managed-configuration, precedence and layering](https://learn.chatgpt.com/docs/enterprise/managed-configuration#precedence-and-layering)).
- A trusted project config cannot set `openai_base_url`, `chatgpt_base_url`, `apps_mcp_product_sku`, `responses_api_metadata`, `model_provider`, `model_providers`, `notify`, `profile`, `profiles`, two realtime base URLs, or `otel` ([SRC loader/mod.rs L71-L88](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L71-L88), [SRC loader/mod.rs L1158-L1174](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L1158-L1174)).
- A trusted project config can set `analytics`, `feedback`, `check_for_update_on_startup`, `features`, and `tui`. Only a session flag or a managed layer overrides such a project value.
- Codex rejects an unknown key only with `--strict-config`. Without that flag, a key with a typo has no effect ([SRC loader/mod.rs L611-L626](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/mod.rs#L611-L626)). A TOML parse error in a layer file makes the config load fail.

### The files that Codex writes

- Codex writes user state into the active user config file. The state includes project trust, the model choice, notices, the model availability counter, and hook trust hashes ([SRC core/src/config/edit.rs L793-L805](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/edit.rs#L793-L805), [SRC config/src/state.rs L315-L328](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/state.rs#L315-L328), [SRC tui/src/hooks_rpc.rs L58-L88](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/hooks_rpc.rs#L58-L88)).
- Codex always writes project trust to `$CODEX_HOME/config.toml` ([SRC core/src/config/mod.rs L2327-L2338](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/mod.rs#L2327-L2338)).
- The writer resolves the full symlink chain and writes into the final target ([SRC core/src/config/edit.rs L741-L784](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/config/edit.rs#L741-L784), [SRC utils/path-utils/src/lib.rs L44-L123](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/utils/path-utils/src/lib.rs#L44-L123)).
- Thus a symlink from `~/.codex/config.toml` into the repository puts private project paths into the repository.
- With `--profile <name>`, the profile file is the active user file ([SRC tui/src/startup_orchestration.rs L241-L246](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/startup_orchestration.rs#L241-L246), [SRC tui/src/local_settings.rs L57-L61](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/local_settings.rs#L57-L61)).
- The TUI then writes its preferences and the model availability counter into `<name>.config.toml` ([SRC tui/src/app/startup_prompts.rs L252-L255](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/app/startup_prompts.rs#L252-L255)).
- The app-server also writes hook trust hashes into the profile file ([SRC app-server/src/config_manager.rs L67-L69](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/config_manager.rs#L67-L69)). A hook trust key holds the path of the hook file ([SRC hooks/src/lib.rs L113-L123](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/hooks/src/lib.rs#L113-L123)). Thus a symlinked profile file is not safe either.
- The app-server rejects each write outside the user config file ([SRC app-server/src/config_manager_service.rs L216-L236](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/app-server/src/config_manager_service.rs#L216-L236)).
- A search for writers of `/etc/codex/config.toml`, `/etc/codex/managed_config.toml`, and `/etc/codex/requirements.toml` found only readers.
- Codex can write the `.codex/config.toml` of a project, to keep an MCP tool approval ([SRC core/src/mcp_tool_call.rs L2250-L2257](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/core/src/mcp_tool_call.rs#L2250-L2257)).

### Options for settings that the user owns

| Option | Precedence | Clients | Codex writes it | Symlink safe | Notes |
| --- | --- | --- | --- | --- | --- |
| `/etc/codex/config.toml` | 10 | All that use this binary: the TUI, `codex exec`, and `codex app-server` (the IDE extension starts it) | No | Yes | One `sudo` step. User, profile, project, and `-c` values override it. |
| `/etc/codex/requirements.toml` | Constraint | All | No | Yes | Pins `check_for_update_on_startup`, `feedback`, and `[features]`. It cannot pin `analytics`, `otel`, or `tui`. |
| `/etc/codex/managed_config.toml` | 40 | All | No | Yes | Overrides `-c` and project config. The source calls it legacy and "phased out". Its approval and sandbox keys become constraints. |
| `defaults write com.openai.codex config_toml_base64 <base64>` | 50 | All | No | Not a file | OpenAI documents it for MDM. The Apple docs say that `CFPreferencesCopyAppValue` also searches the domain of the current user. This research did not do a test. |
| `~/.codex/config.toml` | 20 | All | Yes | No | Codex owns it. A script can merge keys into it in place, but then Codex and the script share one file. |
| `~/.codex/<name>.config.toml` with `--profile` | 21 | Runtime commands only | Yes, when active | No | `codex login`, `update`, `doctor`, `features`, `plugin`, `app-server`, and `cloud` reject `--profile`. |
| Project `.codex/config.toml` | 25 | Trusted projects only | Sometimes | No | A project layer, not a user layer. |
| `-c key=value` in a shell function | 30 | Commands from the shell only | No | Not a file | Overrides user, profile, and project config. Stops the daemon reuse, so the flags always apply. |
| Environment variable | None | None | Not applicable | Not applicable | No variable controls telemetry, feedback, updates, plugins, or apps. |
| Include directive | None | None | Not applicable | Not applicable | No include mechanism exists. |

- The macOS reader calls `CFPreferencesCopyAppValue` with the domain `com.openai.codex` ([SRC config/src/loader/macos.rs L123-L145](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/loader/macos.rs#L123-L145)).
- Apple says that this function "searches through all the domains in order until a value is found", and the first domain is the current user ([Apple, Preference Domains](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFPreferences/Concepts/PreferenceDomains.html)).
- `--profile` works only for `codex`, `exec`, `review`, `resume`, `queue`, `archive`, `delete`, `unarchive`, `fork`, `mcp`, `sandbox`, and `debug prompt-input` ([SRC cli/src/main.rs L1890-L1917](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cli/src/main.rs#L1890-L1917)). Thus a shell function that always adds `--profile` breaks the other subcommands.
- Root `-c` flags reach each subcommand. `--enable` and `--disable` become `features.<name>` overrides ([SRC cli/src/main.rs L1139-L1141](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cli/src/main.rs#L1139-L1141), [SRC cli/src/main.rs L2443-L2448](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/cli/src/main.rs#L2443-L2448)).
- The docs describe the profile files and `-c` in the same way ([config-advanced, profiles](https://learn.chatgpt.com/docs/config-file/config-advanced#profiles), [config-advanced, one-off overrides](https://learn.chatgpt.com/docs/config-file/config-advanced#one-off-overrides-from-the-cli)).
- Environment variable searches: a search of the source for string literals that start with `CODEX_` found more than 100 names. None controls analytics, feedback, updates, plugins, or apps.
- The variables that touch this topic are `CODEX_HOME`, `CODEX_SQLITE_HOME`, `CODEX_INTERNAL_ORIGINATOR_OVERRIDE`, and `CODEX_ANALYTICS_EVENTS_CAPTURE_FILE`. The last one works in debug builds only ([SRC analytics/src/client.rs L146-L156](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/analytics/src/client.rs#L146-L156)).
- Include searches: a search of `config/src` and `core/src/config` for `include`, `extends`, and `config_file` found no include of config files. The `include` action belongs to `shell_environment_policy` filters.
- `agents.<role>.config_file` adds a config layer only for a subagent with that role ([SRC config/src/config_toml.rs L717-L730](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/config/src/config_toml.rs#L717-L730)).

## Recommended configuration

### The approach

1. Put the privacy keys in one repository file. Link that file to `/etc/codex/config.toml`. Every client reads it, and Codex never writes it.
2. Add a `codex` shell function with `-c` flags for the five keys that a trusted project can change. A session flag overrides a project layer.
3. Leave `~/.codex/config.toml` to Codex. Do not use a profile file for these keys.
4. Optional: add `/etc/codex/requirements.toml` to pin the update check, feedback, and the features, so that no layer can change them.

### File 1: the system layer

The top-level key must come before the first table header. Otherwise TOML puts it into the table above it.

```toml
# /etc/codex/config.toml -> $DOTFILES/codex/etc/codex/config.toml
# Codex 0.154.0 reads this file for the TUI, `codex exec`, and each app-server.
# Codex never writes it. User, --profile, trusted project, and -c values override it.

# No version fetch from formulae.brew.sh or api.github.com, and no update prompt.
check_for_update_on_startup = false

# Stops the analytics events (chatgpt.com) and the Statsig metrics (ab.chatgpt.com).
[analytics]
enabled = false

# No OpenTelemetry export of logs, traces, or metrics.
[otel]
exporter = "none"
trace_exporter = "none"
metrics_exporter = "none"
log_user_prompt = false

# No /feedback upload to Sentry.
[feedback]
enabled = false

[tui]
# No automatic recap request to the model when the terminal loses focus.
auto_recap = false
# Hides the startup tips. The announcement download still occurs (no knob).
show_tooltips = false

[features]
# No curated plugin sync, no remote plugin catalog, no marketplace auto-upgrade.
plugins = false
# No hosted codex_apps MCP server at chatgpt.com/backend-api/ps/mcp.
apps = false
# No create_goal tool and no automatic goal turns.
goals = false
# No offer to install the MCP servers that a skill names.
skill_mcp_dependency_install = false

# Commands that Codex runs get no variable whose name holds KEY, SECRET, or TOKEN.
# Cost: a command that reads such a variable (for example GH_TOKEN) fails.
[shell_environment_policy]
ignore_default_excludes = false
```

### File 2: the shell function

```zsh
# Codex: -c flags override a trusted project .codex/config.toml.
# /etc/codex/config.toml holds the same keys for the IDE extension and the desktop app.
codex() {
  command codex \
    -c analytics.enabled=false \
    -c feedback.enabled=false \
    -c check_for_update_on_startup=false \
    -c features.plugins=false \
    -c features.apps=false \
    "$@"
}
```

### Optional file 3: the requirements layer

```toml
# /etc/codex/requirements.toml (optional). No config layer can change these values.
# requirements.toml cannot pin analytics, otel, or tui.
check_for_update_on_startup = false

[feedback]
enabled = false

[features]
plugins = false
apps = false
goals = false
skill_mcp_dependency_install = false
```

### Environment variables

Set none. No environment variable of Codex 0.154.0 controls telemetry, error reports, update checks, plugins, or apps. The searches that support this are in "Config mechanics".

### How to install without owning `config.toml`

1. Add the content of file 1 to the repository, for example as `codex/etc/codex/config.toml`. If the repository uses stow for `$HOME`, keep this file out of the `$HOME` packages.
2. Run this one time: `sudo mkdir -p /etc/codex && sudo ln -sfn "$DOTFILES/codex/etc/codex/config.toml" /etc/codex/config.toml`.
3. Add the function of file 2 to the repository `.zshrc`.
4. Optional: install file 3 at `/etc/codex/requirements.toml` in the same way.
5. Do not link or edit `~/.codex/config.toml`. Do not make a `~/.codex/<name>.config.toml` file.
6. To make sure that the layers load, start the TUI and run `/debug-config`. It shows the config layers and the requirement sources ([SRC tui/src/slash_command.rs L118](https://github.com/openai/codex/blob/rust-v0.154.0/codex-rs/tui/src/slash_command.rs#L118)).
7. After the next TUI start, `~/.codex/version.json` must keep its old `last_checked_at` value.

Caution: the link target is in a directory that your user can write. A Codex session in `workspace-write` mode inside the dotfiles repository can edit it, and the next start then reads the edit. If this risk is not permitted, copy the file with `sudo install -m 0644` in place of the link.

### What this configuration does not stop

- The announcement download from `raw.githubusercontent.com` at each TUI start.
- The turn metadata on each model request: the installation ID, the repository root path, the git remote URLs, and the HEAD hash.
- The attribution settings fetch, and the attribution text while the ChatGPT account setting is on.
- The fetch of the model list, and the model requests themselves.
- An analytics key set to `true` in a trusted project, for a client that the shell function does not start (for example the IDE extension).

## Gaps

- The place of the account setting `commit_attribution_enabled` is unknown. A search of the downloaded docs pages for "attribution" and "co-authored" found nothing. Web searches on `learn.chatgpt.com`, `developers.openai.com`, and `help.openai.com` found no primary page.
- The `defaults write` method for `config_toml_base64` is not tested. The source and the Apple docs support it, but this research wrote no preference.
- This research did not run the shell function or the system file. Thus it did not see `/debug-config` with the new layers.
- This research read the `-c` path for `codex`, `exec`, `agents`, and some other subcommands. It did not read each subcommand, thus one subcommand can still reject root `-c` flags.
- The desktop app is not open source. This research did not confirm that the app starts its app-server with the same config loader. The IDE extension claim comes from a source comment only.
- The OpenTelemetry crates in the binary know the `OTEL_EXPORTER_OTLP_*` variables. This research did not find out if those variables can change the Statsig endpoint.
- This research did not read the `user_agent()` helper, so the terminal part of the `User-Agent` is unknown.
- This research did not list the calls for account data and rate limits that the TUI makes at start.
- The docs have no privacy page for Codex. `developers.openai.com/codex/privacy` gives HTTP 404.
