# Maximum privacy for opencode 1.18.13

- Date of the research: 2026-09-19.
- opencode 1.18.13. `opencode --version` prints `1.18.13`. The binary is `/Users/s-ved/homebrew/Cellar/opencode/1.18.13/bin/opencode`.
- The Homebrew formula comes from the tap `anomalyco/tap` (`/Users/s-ved/homebrew/Cellar/opencode/1.18.13/INSTALL_RECEIPT.json`, key `source.tap`).
- The source is tag `v1.18.13` of `github.com/anomalyco/opencode`. This research read the tag tarball from `codeload.github.com` and did not clone the repository.
- The docs are the pages under `opencode.ai/docs`, fetched on the date above. The tag holds the same pages in `packages/web/src/content/docs`.
- Each GitHub link points to the tag, with line anchors. Where the docs and the source disagree, this file trusts the source and says so.
- The `opencode debug config` and `opencode debug paths` runs used a scratch `HOME`, scratch XDG directories, and a scratch working directory. No run touched `~/.config/opencode` or `~/.local/share/opencode`.

## Summary

- opencode has no analytics SDK and no crash reporter. The only telemetry path is OpenTelemetry. It stays off until you set `OTEL_EXPORTER_OTLP_ENDPOINT`.
- By default, the TUI looks for a new version 1 second after it starts. It installs a patch release with no prompt. On this machine, that is `brew tap`, `git pull --ff-only` in the tap, and `brew upgrade`.
- The upgrade check reads `autoupdate` only from the files of the global config directory. A value in `OPENCODE_CONFIG`, `OPENCODE_CONFIG_CONTENT`, or a project file has no effect on it. `OPENCODE_DISABLE_AUTOUPDATE=1` stops it in all cases.
- Other default traffic: a model catalog fetch from `models.opencode.ai` at start and each 60 minutes. Also, an npm install of `@opencode-ai/plugin` into each config directory that has no `node_modules`.
- Sharing is manual by default. `OPENCODE_DISABLE_SHARE=1` stops all share traffic, but the docs do not name it. `share: "disabled"` makes each share request fail.
- opencode adds no `Co-Authored-By` trailer and no "Generated with" line. Only `opencode github run`, the CI agent, adds a co-author line and a footer.
- Each model request carries `User-Agent: opencode/1.18.13` and the session ID. For the OpenCode providers, it also carries a hash of the git remote URL. No config key removes these headers.
- In 1.18.13, LSP servers and formatters are off until you set `lsp` or `formatter`. Thus no LSP or formatter download occurs by default.
- The recommended layering: privacy env vars in the repository `.zshrc`, and a dotfiles-owned `~/.config/opencode/config.json`. opencode merges `config.json` before the `opencode.json` of the user, and no normal opencode write goes to it.

## Map from the Claude Code settings

| Claude Code setting | opencode 1.18.13 equivalent |
| --- | --- |
| `DISABLE_TELEMETRY` | No switch is necessary. There is no analytics code. Keep `OTEL_EXPORTER_OTLP_ENDPOINT` unset and `experimental.openTelemetry` unset or `false`. |
| `DISABLE_ERROR_REPORTING` | No switch is necessary. There is no crash upload. The crash screen only copies a GitHub issue URL to the clipboard when you push `c`. |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | No single switch. Set `OPENCODE_DISABLE_AUTOUPDATE=1`, `OPENCODE_DISABLE_MODELS_FETCH=1`, `OPENCODE_DISABLE_SHARE=1`, and `OPENCODE_DISABLE_LSP_DOWNLOAD=1`. Keep `lsp` and `formatter` off. |
| Empty commit and PR attribution, no `Co-Authored-By` | Nothing to turn off. The prompts and the git instructions add no attribution. |
| No session URL | `share: "disabled"` and `OPENCODE_DISABLE_SHARE=1`. |
| Feedback surveys off | No survey exists. |
| Auto-compact off | `OPENCODE_DISABLE_AUTOCOMPACT=1`, or `compaction.auto: false`. |
| Auto-continue off | No key. The synthetic "Continue if you have next steps" turn comes only after an automatic compaction. With auto-compaction off, it does not occur. |

## 1. Telemetry, analytics, and OpenTelemetry

A search of `packages/` found no analytics code in the CLI runtime. The search excluded the docs site, the console, the enterprise app, the web app, and the desktop app. The terms were `telemetry`, `analytics`, `posthog`, `segment`, `sentry`, `honeycomb`, `mixpanel`, `amplitude`, `datadog`, `bugsnag`, `rudderstack`, `plausible`, and `umami`. The only hits were the OpenTelemetry code below and unrelated words.

The same vendor names in `strings` of the binary gave only unrelated matches. For example, `sentry` matched `JSEntryPtrTag` of JavaScriptCore, and `amplitude` matched an SVG attribute and miniaudio functions.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | env, URL | unset | When set, opencode sends all its log records to `<endpoint>/v1/logs` and its trace spans to `<endpoint>/v1/traces`. When unset, no exporter exists. | [otlp.ts L50-77](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability/otlp.ts#L50-L77), [observability.ts L11-22](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability.ts#L11-L22) |
| `OTEL_EXPORTER_OTLP_HEADERS` | env, `k=v,k=v` | unset | Headers for the exporter above. | [otlp.ts L9-18](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability/otlp.ts#L9-L18) |
| `OTEL_RESOURCE_ATTRIBUTES` | env, `k=v,k=v` | unset | More resource attributes. opencode always adds its version, channel, client name, and a run ID. | [otlp.ts L20-48](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability/otlp.ts#L20-L48) |
| `experimental.openTelemetry` | config, boolean | unset (off) | Turns on the AI SDK `experimental_telemetry` spans for model calls. The span metadata holds the session ID and `username`. The spans leave the machine only through the OTLP exporter above. | [config schema L173-175](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L173-L175), [session/llm.ts L208-222, L344-352](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/llm.ts#L208-L222), [agent.ts L376-393](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L376-L393) |
| `username` | config, string | the OS user name | The schema calls it the name to show in conversations. The only other use in the source is `userId` in the telemetry metadata above. | [config.ts L566-573](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L566-L573) |
| `OPENCODE_CLIENT` | env, string | `cli` | Goes into the OTLP resource and into the `x-opencode-client` header to the OpenCode providers. | [flag.ts L75-77](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/flag/flag.ts#L75-L77), [request.ts L187-195](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/llm/request.ts#L187-L195) |

## 2. Error and crash reporting

No setting is necessary. A search for `crash`, `bug report`, `report a bug`, and `issues/new` found only the crash screen of the TUI. That screen builds a GitHub issue URL with the error text and stack. It copies the URL to the clipboard only when you push `c`. It sends nothing.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| Crash screen "Copy report" | TUI key `c` | manual | Copies a `github.com/anomalyco/opencode/issues/new` URL to the clipboard. No upload. | [error-component.tsx L45-52, L203-214](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/tui/src/component/error-component.tsx#L45-L52) |
| TUI worker error handlers | none | on | The worker discards unhandled errors. It does not send them anywhere. | [worker.ts L16-21](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/tui/worker.ts#L16-L21) |
| Errors in the log file | see category 8 | on | Errors go to the local log file only, unless `OTEL_EXPORTER_OTLP_ENDPOINT` is set. | [logging.ts L49-69](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability/logging.ts#L49-L69) |

## 3. Update checks and auto-update

The TUI calls `checkUpgrade` 1 second after it starts ([tui.ts L265-267](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/tui.ts#L265-L267), [worker.ts L59-62](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/tui/worker.ts#L59-L62)). The check reads `autoupdate` through `getGlobal()` ([upgrade.ts L9-10](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L9-L10)). `getGlobal()` reads only `config.json`, `opencode.json`, and `opencode.jsonc` in `~/.config/opencode` ([config.ts L246-293](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L246-L293)).

With the default value, a patch release installs with no prompt. A minor or major release opens a dialog that asks first ([upgrade.ts L26-52](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L26-L52), [app.tsx L1031-1075](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/tui/src/app.tsx#L1031-L1075)).

For the tap formula of this machine, the version lookup runs `brew info --json=v2 anomalyco/tap/opencode`. That lookup reads the local tap clone, thus it sees a new version only after a `brew update`. The upgrade runs `brew tap anomalyco/tap`, then `git pull --ff-only` in the tap, then `brew upgrade` ([installation/index.ts L208-216, L280-301](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/installation/index.ts#L208-L216)). The user forbids git operations without consent, and this `git pull` runs with no prompt.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `OPENCODE_DISABLE_AUTOUPDATE` | env, `1` or `true` | off | The check returns before the version lookup. No subprocess and no network. | [flag.ts L23](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/flag/flag.ts#L23), [upgrade.ts L10](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L10) |
| `autoupdate` | config, `true`, `false`, or `"notify"` | unset, which acts as `true` | `false` stops the check. `"notify"` looks up the version and shows the dialog for each release, patch releases too. Only a file in `~/.config/opencode` counts. | [config schema L64-67](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L64-L67), [upgrade.ts L8-53](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L8-L53) |
| `OPENCODE_ALWAYS_NOTIFY_UPDATE` | env, `1` or `true` | off | After the lookup, always shows the dialog and never installs by itself. | [upgrade.ts L15-24](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L15-L24) |
| `opencode upgrade [target]` | CLI command | manual | Upgrades on request. Not affected by the knobs above. | `opencode --help` |

Docs difference: [opencode config, Autoupdate](https://opencode.ai/docs/config/#autoupdate) says that `"notify"` does not work for a package manager install such as Homebrew. The source has no install-method check before the notify dialog. The docs also do not say that only the global directory counts.

## 4. Other background network

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `OPENCODE_DISABLE_MODELS_FETCH` | env, `1` or `true` | off | Stops the catalog fetch at start and the refresh each 60 minutes. Without the flag, a cache file younger than 5 minutes also skips a fetch. opencode then reads `~/.cache/opencode/models.json`, or else the snapshot that the build puts in the binary. `opencode models --refresh` and a provider login still fetch on request. | [models-dev.ts L217-231, L255-258](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/models-dev.ts#L217-L231), [models.ts L29](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/models.ts#L29), [build.ts L195](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/script/build.ts#L195) |
| `OPENCODE_MODELS_URL` | env, URL | `https://models.opencode.ai` | Catalog source. The request goes to `<url>/api.json` with `User-Agent: opencode/<channel>/<version>/<client>`. The host is `models.opencode.ai`, not `models.dev`. | [models-dev.ts L23, L160-182](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/models-dev.ts#L160-L182) |
| `OPENCODE_MODELS_PATH` | env, path | unset | Reads the catalog from this file. | [models-dev.ts L184](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/models-dev.ts#L184) |
| Install of `@opencode-ai/plugin` | no knob | on | For each config directory, opencode forks an npm install in the background. It runs when `node_modules` is missing, or when the lockfile lacks a declared package name. Install scripts are off (`ignoreScripts: true`). The install also skips a directory that is not writable. | [config.ts L424-457](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L424-L457), [npm.ts L80-108, L139-190](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/npm.ts#L139-L190) |
| npm plugins in `plugin` | config, array | `[]` | At start, opencode installs each npm plugin that is absent into `~/.cache/opencode/packages/<name>`. A local path plugin, such as the one on this machine, gets no install. | [npm.ts L79, L115-137](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/npm.ts#L115-L137), [plugin/index.ts L179-216](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/plugin/index.ts#L179-L216) |
| `OPENCODE_PURE`, `--pure` | env or flag | off | Skips the external plugins, which is the `plugin` array. It does not stop the `@opencode-ai/plugin` install. | [plugin/index.ts L179](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/plugin/index.ts#L179), [index.ts L62-71](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/index.ts#L62-L71) |
| `OPENCODE_DISABLE_DEFAULT_PLUGINS` | env, `1` or `true` | off | Skips the internal auth plugins: Codex, Copilot, Modal, GitLab, Poe, Cloudflare, Azure, DigitalOcean, Snowflake, and xAI. The ones that this research read make no request at load time. | [plugin/index.ts L66-84, L168](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/plugin/index.ts#L66-L84) |
| `lsp` | config, boolean or object | unset (off) | Unset or `false` starts no LSP server. `true` or an object starts the built-in servers. A missing server binary then downloads from GitHub or npm. | [lsp.ts L151-189](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/lsp/lsp.ts#L151-L189), [lsp/server.ts L143-190](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/lsp/server.ts#L143-L190) |
| `OPENCODE_DISABLE_LSP_DOWNLOAD` | env, `1` or `true` | off | Stops each LSP download. The server starts only if its binary is already on `PATH` or in the cache. | [runtime-flags.ts L22](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L22), [lsp/server.ts L152](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/lsp/server.ts#L152) |
| `formatter` | config, boolean or object | unset (off) | Unset or `false` runs no formatter. When on, `prettier`, `biome`, and `oxfmt` install from npm into the cache if absent. No env var gates these installs. | [format/index.ts L120-158](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/format/index.ts#L120-L158), [formatter.ts L71-84, L143-153](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/format/formatter.ts#L71-L84) |
| ripgrep download | no knob | only if `rg` is missing | If `rg` is not on `PATH` and not in the cache, opencode downloads it from GitHub. This machine has `rg` on `PATH`. | [ripgrep/binary.ts L93-115](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/ripgrep/binary.ts#L93-L115) |
| `.well-known/opencode` remote config | `providers login <url>` | none | Only an auth entry of type `wellknown` starts this fetch, at each config load. `~/.local/share/opencode/auth.json` on this machine has one entry, `opencode-go`, of type `api`. | [config.ts L356-396](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L356-L396) |
| Console account config | `opencode console login` (hidden) | none | With an active console org, each config load fetches the org config, and shares go to the console. | [config.ts L478-514](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L478-L514), [share-next.ts L206-222](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/share/share-next.ts#L206-L222) |
| `instructions` and `skills.urls` | config | unset | opencode fetches each URL entry. | [instruction.ts L155-169](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/instruction.ts#L155-L169), [skill/index.ts L222](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/skill/index.ts#L222) |
| `websearch` tool | env flags | off for providers other than `opencode` | The tool exists for the `opencode` provider, or with `OPENCODE_ENABLE_EXA`, `OPENCODE_ENABLE_PARALLEL`, or `OPENCODE_EXPERIMENTAL`. Queries go to `mcp.exa.ai` or `search.parallel.ai`. | [registry.ts L58-60, L288-289](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/registry.ts#L58-L60), [mcp-websearch.ts L4-7](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/mcp-websearch.ts#L4-L7), [runtime-flags.ts L31-39](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L31-L39) |
| `OPENCODE_DISABLE_EMBEDDED_WEB_UI` | env, `1` or `true` | off | Do not set it. When set, the server of `opencode web` and `opencode serve` loads the web UI from `app.opencode.ai` instead of from the binary. | [ui.ts L9, L44-49](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/server/shared/ui.ts#L44-L49) |
| `disabled_providers` | config, array | `[]` | Without a key, the `opencode` (OpenCode Zen) provider still loads with its free models and the key `public`. `["opencode"]` stops that. `opencode-go` is a different ID. | [provider.ts L179-201, L1388-1395](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/provider/provider.ts#L179-L201) |
| Listening port | `--port`, `--hostname`, `--mdns` | none | The TUI opens no port unless you give one of these flags. mDNS is off. | [tui.ts L234-241](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/tui.ts#L234-L241), `opencode --help` |
| IDE extension install | none | no caller | `Ide.install` runs `code --install-extension sst-dev.opencode`. A search for its callers found none. | [ide/index.ts L36-50](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/ide/index.ts#L36-L50) |

## 5. Session sharing

Sharing is manual by default. A share uploads the session, the messages, the parts, the file diffs, and the model list to `https://opncd.ai`. It keeps them in sync after each change ([share-next.ts L124-222](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/share/share-next.ts#L124-L222), [opencode share](https://opencode.ai/docs/share/)).

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `share` | config, `"manual"`, `"auto"`, or `"disabled"` | unset, which acts as `"manual"` | `"auto"` shares each new top-level session. `"disabled"` makes each share request fail with "Sharing is disabled in configuration". A project file can override it. | [share/session.ts L26-46](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/share/session.ts#L26-L46), [config schema L57-63](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L57-L63) |
| `autoshare` | config, boolean | unset | Deprecated. `true` sets `share` to `"auto"` if `share` is unset. | [config.ts L575-577](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L575-L577) |
| `OPENCODE_DISABLE_SHARE` | env, `1` or `true` | off | The share functions `create`, `sync`, and `remove` do nothing. No request goes to a share server, even with `share: "auto"` from a project. The docs do not name it. | [share-next.ts L23, L126, L164, L248, L302, L311, L339](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/share/share-next.ts#L23) |
| `OPENCODE_AUTO_SHARE` | env, boolean | off | Shares each new session, like `share: "auto"`. | [runtime-flags.ts L17](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L17), [run.ts L538](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/run.ts#L538) |
| `enterprise.url` | config, URL | `https://opncd.ai` | The share server when no console account is active. | [share-next.ts L206-212](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/share/share-next.ts#L206-L212) |
| `SHARE` in `opencode github run` | env, `true` or `false` | unset | The CI agent shares the session of a public repository unless `SHARE=false`. | [github.handler.ts L513-518, L674-680](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/github.handler.ts#L513-L518) |

## 6. Attribution

A search of `packages/` for `co-authored`, `coauthor`, `generated with`, the robot emoji, `noreply@`, `attribution`, and `trailer` found one real hit, in `github.handler.ts`. In the binary, `Co-authored-by` occurs only in the commit function of that handler.

The git instructions of the shell tool say "Write a concise commit message that matches the repo style" and add no trailer ([shell.txt L13-21](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/shell/shell.txt#L13-L21)). The PR example of the shell tool has only a `## Summary` body ([shell/prompt.ts L221-270](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/shell/prompt.ts#L221-L270)).

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| Commit and PR attribution in a session | none | absent | Nothing to turn off. | [shell.txt L13-21](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/shell/shell.txt#L13-L21) |
| `opencode github run` commits | none | on | Adds `Co-authored-by: <actor> <actor@users.noreply.github.com>` for the GitHub user who started the workflow. | [github.handler.ts L465-469](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/github.handler.ts#L465-L469) |
| `opencode github run` PR and comment footer | `SHARE` | on | Adds a "github run" link, plus a share link and a social card image when the session is shared. | [github.handler.ts L1347-1358](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/github.handler.ts#L1347-L1358) |
| `HTTP-Referer: https://opencode.ai/`, `X-Title: opencode` | `provider.<id>.options.headers` | on | Sent to `llmgateway` (also `X-Source`), `openrouter`, `nvidia` (also `X-BILLING-INVOKE-ORIGIN: OpenCode`), `vercel`, `zenmux`, and `kilo`. A config header with the same name, in the same case, replaces the value. | [provider.ts L456-497, L594-603, L852-861](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/provider/provider.ts#L456-L497), [provider.ts L1569-1595](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/provider/provider.ts#L1569-L1595) |
| `User-Agent: opencode/1.18.13`, `x-session-affinity`, `X-Session-Id`, `x-parent-session-id` | `chat.headers` plugin hook | on | Sent with each model request to a provider other than the OpenCode ones. | [request.ts L177-205](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/llm/request.ts#L177-L205) |
| `x-opencode-project`, `x-opencode-session`, `x-opencode-request`, `x-opencode-client`, `User-Agent` | `chat.headers` plugin hook | on | Sent to each provider whose ID starts with `opencode`, which includes `opencode-go` on this machine. The project ID is a hash of the normalized git remote URL, or else the root commit. | [request.ts L177-195](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/llm/request.ts#L177-L195), [core project.ts L72-78, L104-119](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/project.ts#L72-L78) |
| `chat.headers` hook | plugin | none | Runs before the request. Its headers merge last, so it can replace each value above. | [request.ts L134-146, L202-203](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/llm/request.ts#L134-L146), [plugin index.ts L257-260](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/plugin/src/index.ts#L257-L260), `~/.config/opencode/node_modules/@opencode-ai/plugin/dist/index.d.ts:183-191` |

## 7. Uncontrolled behavior

### State and background work

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| Auto-update | `OPENCODE_DISABLE_AUTOUPDATE`, `autoupdate` | on | See category 3. | [upgrade.ts L8-53](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L8-L53) |
| `compaction.auto` | config, boolean | `true` | When the context is full, opencode summarizes the session with a model call. | [config schema L149-168](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L149-L168), [overflow.ts L22-34](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/overflow.ts#L22-L34), [prompt.ts L1160-1167](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/prompt.ts#L1160-L1167) |
| `OPENCODE_DISABLE_AUTOCOMPACT` | env, `1` or `true` | off | Sets `compaction.auto` to `false` after all config layers merge, so no file can turn it on again. A context overflow then stops the turn with an error. | [config.ts L579-581](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L579-L581), [processor.ts L607-614](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/processor.ts#L607-L614) |
| Auto-continue after compaction | plugin hook `experimental.compaction.autocontinue` | on | After an automatic compaction, opencode adds a synthetic user turn "Continue if you have next steps, or stop and ask for clarification if you are unsure how to proceed." A plugin can set `enabled: false`. No config key exists. | [compaction.ts L422-503](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/compaction.ts#L422-L503), [plugin index.ts L316-327](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/plugin/src/index.ts#L316-L327) |
| `compaction.prune` | config, boolean | `false` | When `true`, opencode removes old tool outputs from the context. | [compaction.ts L243-245](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/compaction.ts#L243-L245) |
| `OPENCODE_DISABLE_PRUNE` | env, `1` or `true` | off | Sets `compaction.prune` to `false` after all layers merge. The docs say "Disable pruning of old data", but the source shows only this effect. | [config.ts L582-584](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L582-L584) |
| Title generation | `agent.title.disable`, `small_model` | on | After the first user message, a hidden `title` agent sends that message to a small model of the same provider. `agent.title.disable: true` removes the agent, and the call stops. | [prompt.ts L193-253](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/session/prompt.ts#L193-L253), [agent.ts L234-249, L266-270](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L266-L270) |
| Background subagents | `OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS` | off | Experimental. `OPENCODE_EXPERIMENTAL=1` also turns it on. | [runtime-flags.ts L43](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L43) |
| `OPENCODE_EXPERIMENTAL` | env, boolean | off | Umbrella flag. It turns on Exa web search and each flag built with `enabledByExperimental`. Do not set it for privacy. | [runtime-flags.ts L10-14, L31-51](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L10-L14) |
| Snapshots | `snapshot` | `true` | Before and after each step, opencode runs git with a separate git directory under `~/.local/share/opencode/snapshot`. An hourly `git gc --prune=7.days` runs on it. | [snapshot/index.ts L71-75, L167-170, L301-316, L760-765](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/snapshot/index.ts#L167-L170) |
| `.git/opencode` file | no knob | on | In each git repository, opencode writes the project ID into the file `opencode` of the git common directory. | [project.ts L306-308](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/project/project.ts#L306-L308), [core project.ts L123-126](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/project.ts#L123-L126) |
| Config directory writes | no knob | on | `.gitignore`, `package.json`, `package-lock.json`, and `node_modules` in each config directory. See "Config mechanics". | [config.ts L295-312, L436-457](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L295-L312) |

### Permission knobs (not privacy)

The default ruleset lets each tool run with no prompt ([agent.ts L119-136](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L119-L136), [opencode permissions](https://opencode.ai/docs/permissions/#defaults)).

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `permission` | config, `"allow"`, `"ask"`, `"deny"`, or an object per tool | `"*": "allow"` | Keys: `read`, `edit`, `glob`, `grep`, `list`, `bash`, `task`, `external_directory`, `todowrite`, `question`, `webfetch`, `websearch`, `lsp`, `doom_loop`, `skill`, and any other tool or MCP tool name. An object maps patterns to actions. | [permission.ts L5-48](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/permission.ts#L5-L48) |
| `permission.doom_loop` | action | `"ask"` | Asks when one tool call occurs 3 times with the same input. | [agent.ts L121](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L119-L136) |
| `permission.external_directory` | action or object | `"ask"`, with the temp directory, the skill directories, and the tool output directory set to `"allow"` | Asks before a tool touches a path outside the project. | [agent.ts L108-125](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L108-L125) |
| `permission.read` for `.env` files | object | `*.env` and `*.env.*` are `"ask"`, and `*.env.example` is `"allow"` | The docs say `"deny"`. The source says `"ask"`. | [agent.ts L129-135](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/agent/agent.ts#L129-L135) |
| `permission.webfetch`, `permission.websearch` | action | `"allow"` | Each fetch or search goes to a third party with the URL or query of the model. | [permission.ts L29-30](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/permission.ts#L29-L30) |
| `tools` | config, map of booleans | unset | Legacy. `true` becomes `"allow"` and `false` becomes `"deny"`. `permission` wins over it. | [config.ts L553-564](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L553-L564) |
| `OPENCODE_PERMISSION` | env, JSON | unset | Merges into `permission` after all config layers, managed files too. | [config.ts L545-551](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L545-L551) |
| `--auto` | CLI flag, TUI toggle | off | Approves each request that would ask. A `"deny"` rule still applies. | `opencode --help`, [opencode permissions, Auto mode](https://opencode.ai/docs/permissions/) |
| `permission.ask` | plugin hook | none | A plugin can set the answer to `ask`, `deny`, or `allow`. | [plugin index.ts L261](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/plugin/src/index.ts#L261) |
| `experimental.continue_loop_on_deny` | config, boolean | unset | Continues the agent loop after a denied tool call. | [config schema L179-181](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L179-L181) |

## 8. Local persistence

This section lists the knobs only. It does not recommend that you turn them off.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `XDG_DATA_HOME`, `XDG_CACHE_HOME`, `XDG_CONFIG_HOME`, `XDG_STATE_HOME` | env, path | `~/.local/share`, `~/.cache`, `~/.config`, `~/.local/state` | The base of each opencode directory. `opencode debug paths` prints them. | [global.ts L10-43](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/global.ts#L10-L43) |
| `OPENCODE_DB` | env, path or `:memory:` | `~/.local/share/opencode/opencode.db` | The SQLite database of sessions and messages. A relative path is under the data directory. | [database.ts L43-55](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/database/database.ts#L43-L55) |
| `OPENCODE_DISABLE_CHANNEL_DB` | env, `1` or `true` | off | On a non-release channel, uses `opencode.db` and not `opencode-<channel>.db`. | [database.ts L48-54](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/database/database.ts#L48-L54) |
| `snapshot` | config, boolean | `true` | File snapshots for undo and revert, under `~/.local/share/opencode/snapshot`. | [config schema L52-55](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L52-L55), [snapshot/index.ts L71](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/snapshot/index.ts#L71) |
| `OPENCODE_LOG_LEVEL`, `--log-level` | env or flag, `DEBUG`, `INFO`, `WARN`, `ERROR` | `INFO` | Level of `~/.local/share/opencode/log/opencode.log`. The source appends to this one file. | [logging.ts L49-69](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability/logging.ts#L49-L69), [index.ts L66-68](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/index.ts#L66-L68) |
| `logLevel` | config | unset | In the schema, but a search found no code that reads it. | [config schema L37](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L37) |
| `OPENCODE_PRINT_LOGS`, `--print-logs` | env or flag | off | Also writes the log to stderr. | [logging.ts L67-69](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/observability/logging.ts#L67-L69) |
| `OPENCODE_DIRECT_TRACE` | env, `1` | off | A JSONL trace of each prompt and event, under `log/direct/`. | [trace.ts L1-12](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/run/trace.ts#L1-L12) |
| `OPENCODE_AUTO_HEAP_SNAPSHOT` | env, `1` or `true` | off | Writes a heap snapshot to the log directory when RSS exceeds 2 GiB. | [heap.ts L12-31](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/heap.ts#L12-L31) |
| `tool_output.max_lines`, `tool_output.max_bytes` | config, integers | 2000 and 51200 | A longer tool output goes to `~/.local/share/opencode/tool-output`. opencode deletes these files after 7 days. | [config schema L136-148](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/v1/config/config.ts#L136-L148), [truncate.ts L13](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/tool/truncate.ts#L13) |
| State files | none | on | `model.json` (recent models of `/models`), `kv.json` (TUI toggles), and `plugin-meta.json`, in `~/.local/state/opencode`. | [local.tsx L164](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/tui/src/context/local.tsx#L164), [kv.tsx L15](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/tui/src/context/kv.tsx#L15), [meta.ts L49](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/plugin/meta.ts#L49) |
| Credentials | `OPENCODE_AUTH_CONTENT` | `~/.local/share/opencode/auth.json` | API keys and OAuth tokens. The env var replaces the file content. | [auth/index.ts L10, L59-61](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/auth/index.ts#L10) |

Docs difference: [opencode troubleshooting, Logs](https://opencode.ai/docs/troubleshooting/#logs) says that the files have timestamps in their names and that opencode keeps the last 10. The 1.18.13 source appends to `opencode.log`, and a scratch run made only that file. The older timestamped files on this machine come from earlier versions.

## Config mechanics

### Merge order

`loadInstanceState` merges the sources in this order. A later source wins for each key ([config.ts L314-584](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L314-L584)):

1. Remote config from `<url>/.well-known/opencode`, only for each auth entry of type `wellknown` ([L356-396](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L356-L396)).
2. The global directory `~/.config/opencode`: `config.json`, then `opencode.json`, then `opencode.jsonc` ([L246-279, L398-399](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L246-L279)).
3. The file in `OPENCODE_CONFIG` ([L401-404](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L401-L404)).
4. The project files `opencode.json` and `opencode.jsonc`, from the worktree root down to the working directory. `OPENCODE_DISABLE_PROJECT_CONFIG=1` skips them ([L406-410](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L406-L410), [paths.ts L10-21](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/paths.ts#L10-L21)).
5. The config directories: each `.opencode` directory of the project, then `~/.opencode`, then `OPENCODE_CONFIG_DIR`. opencode reads `opencode.json` and `opencode.jsonc` from each, and agents, commands, modes, and plugins from all ([L424-466](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L424-L466), [paths.ts L23-41](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/paths.ts#L23-L41)).
6. `OPENCODE_CONFIG_CONTENT` ([L468-476](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L468-L476)).
7. The org config of an active console account ([L478-514](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L478-L514)). The docs do not name this layer.
8. `/Library/Application Support/opencode/opencode.json` and `opencode.jsonc`, which only root can write ([L516-522](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L516-L522), [managed.ts L20-33](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/managed.ts#L20-L33)).
9. The MDM plist of the domain `ai.opencode.managed` ([L524-534](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L524-L534), [managed.ts L43-69](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/managed.ts#L43-L69)).

After the merge, `OPENCODE_PERMISSION`, `tools`, `autoshare`, `OPENCODE_DISABLE_AUTOCOMPACT`, and `OPENCODE_DISABLE_PRUNE` apply ([L545-584](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L545-L584)). Thus these env vars beat each file, the managed files too.

The merge is `mergeDeep` from `remeda`. Objects merge key by key, and a later array replaces an earlier one. Two exceptions: `instructions` arrays join, and `plugin` entries join without duplicates ([L41-51, L330-354](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L41-L51)).

One key does not obey this order. The upgrade check reads `autoupdate` from step 2 only ([upgrade.ts L9-10](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/upgrade.ts#L9-L10)).

Scratch runs of `opencode debug config` showed this order:

- A project `opencode.json` with `share: "auto"` beat an `OPENCODE_CONFIG` file with `share: "disabled"`.
- `OPENCODE_CONFIG_CONTENT` with `share: "disabled"` beat a project `share: "auto"`.
- The `opencode.json` of an `OPENCODE_CONFIG_DIR` beat a project `opencode.json`.
- A global `opencode.json` beat a global `config.json`, and opencode read `config.json` through a symlink.
- `OPENCODE_DISABLE_AUTOCOMPACT=1` beat a project `compaction.auto: true`.

### Files that opencode writes

| Write | Target | When | Source |
| --- | --- | --- | --- |
| Adds `"$schema": "https://opencode.ai/config.json"` | Each config file that opencode loads from a path and that has no `$schema` | Each config load. A scratch run showed this on an `OPENCODE_CONFIG` file. | [config.ts L231-235](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L231-L235) |
| Seeds `{ "$schema": ... }` | `~/.config/opencode/opencode.jsonc` | Only if none of the three global files exists, and none of `OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR`, and `OPENCODE_CONFIG_CONTENT` is set | [config.ts L139-147, L248-257](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L248-L257) |
| `.gitignore` | Each config directory: the global one, each `.opencode`, and `OPENCODE_CONFIG_DIR` | If absent. A scratch run showed this in an `OPENCODE_CONFIG_DIR`. | [config.ts L295-312, L436](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L295-L312) |
| `package.json`, `package-lock.json`, `node_modules` | Each config directory | When the npm install runs | [config.ts L438-457](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L438-L457), [npm.ts L139-190](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/npm.ts#L139-L190) |
| Overwrites `config.json` | `~/.config/opencode/config.json` | Only if the legacy TOML file `~/.config/opencode/config` exists | [config.ts L262-276](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L262-L276) |
| `updateGlobal` patch | The first file that exists of `opencode.jsonc`, `opencode.json`, and `config.json` | A settings change in the web or desktop app (`global.config.update`). The TUI does not call it. | [config.ts L637-660](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L637-L660), [handlers/global.ts L86-90](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/server/routes/instance/httpapi/handlers/global.ts#L86-L90), [server-sync.tsx L661](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/app/src/context/server-sync.tsx#L661) |
| `Config.update` | `<project directory>/config.json` | The HTTP route `config.update` | [config.ts L624-631](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/config.ts#L624-L631) |
| TUI key move | Writes `tui.json` and `<file>.tui-migration.bak`, and removes `theme`, `keybinds`, and `tui` from the file | TUI start, for each `opencode.json`, `opencode.jsonc`, or `OPENCODE_CONFIG` file that has these keys, if no `tui.json` exists | [tui-migrate.ts L29-132](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/tui-migrate.ts#L29-L132), [tui.ts L174](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/config/tui.ts#L174) |
| `mcp.<name>` | `opencode.json` first, else `opencode.jsonc`, global or project | `opencode mcp add` | [mcp.ts L394-424](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/cli/cmd/mcp.ts#L394-L424) |
| `plugin` entry | `opencode.json` first, else `opencode.jsonc`, or `tui.json` | `opencode plugin <module>` and a TUI plugin install | [install.ts L333-352](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/plugin/install.ts#L333-L352) |

Not a config write: `/models` writes `~/.local/state/opencode/model.json`, TUI toggles write `kv.json`, and a provider login writes `~/.local/share/opencode/auth.json`.

### Privacy env vars in the source

The flag modules are [runtime-flags.ts L16-57](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/opencode/src/effect/runtime-flags.ts#L16-L57) and [flag.ts L15-78](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/flag/flag.ts#L15-L78). The value `1` turns on each boolean flag of both modules. `flag.ts` takes `true` or `1`. `runtime-flags.ts` uses the boolean parser of Effect, which takes `true`, `yes`, `on`, `1`, or `y` (binary strings). `OPENCODE_DISABLE_SHARE` reads its value directly and takes `true` or `1`.

| Env var | Effect | Set it? |
| --- | --- | --- |
| `OPENCODE_DISABLE_AUTOUPDATE` | No version lookup and no install. | Yes |
| `OPENCODE_DISABLE_MODELS_FETCH` | No catalog fetch at start or each hour. | Yes |
| `OPENCODE_DISABLE_SHARE` | No share traffic. | Yes |
| `OPENCODE_DISABLE_LSP_DOWNLOAD` | No LSP binary download. | Yes |
| `OPENCODE_DISABLE_AUTOCOMPACT` | Forces `compaction.auto` to `false`. | Yes |
| `OPENCODE_DISABLE_PRUNE` | Forces `compaction.prune` to `false`. | Yes |
| `OPENCODE_ALWAYS_NOTIFY_UPDATE` | Dialog in place of a silent install. The lookup still runs. | Not necessary with the first flag |
| `OPENCODE_AUTO_SHARE` | Shares each new session. | Never |
| `OPENCODE_EXPERIMENTAL` | Umbrella, which also turns on Exa web search. | Never |
| `OPENCODE_ENABLE_EXA`, `OPENCODE_EXPERIMENTAL_EXA`, `OPENCODE_ENABLE_PARALLEL`, `OPENCODE_EXPERIMENTAL_PARALLEL`, `OPENCODE_WEBSEARCH_PROVIDER` | Web search through `mcp.exa.ai` or `search.parallel.ai`. | Never |
| `OPENCODE_DISABLE_EMBEDDED_WEB_UI` | Loads the web UI from `app.opencode.ai`. | Never |
| `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS`, `OTEL_RESOURCE_ATTRIBUTES` | OTLP export of all logs and traces. | Never, globally |
| `OPENCODE_MODELS_URL`, `OPENCODE_MODELS_PATH` | Other catalog source. | Not necessary |
| `OPENCODE_DISABLE_DEFAULT_PLUGINS` | Skips the internal auth plugins. | Not necessary |
| `OPENCODE_PURE` | Skips the external plugins. It would drop the `meridian` plugin of this machine. | No |
| `OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR`, `OPENCODE_CONFIG_CONTENT`, `OPENCODE_DISABLE_PROJECT_CONFIG`, `OPENCODE_PERMISSION`, `OPENCODE_TUI_CONFIG` | Config layers. See "Merge order". | See the recommendation |
| `OPENCODE_DISABLE_CLAUDE_CODE`, `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT`, `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS`, `OPENCODE_DISABLE_EXTERNAL_SKILLS` | Stop the reads of `~/.claude` and `.agents` files. These files go to the model provider as instructions. | Already set: `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` |
| `OPENCODE_CLIENT` | Sent in headers and in the OTLP resource. | No |
| `OPENCODE_DB`, `OPENCODE_DISABLE_CHANNEL_DB`, `OPENCODE_LOG_LEVEL`, `OPENCODE_PRINT_LOGS`, `OPENCODE_DIRECT_TRACE`, `OPENCODE_AUTO_HEAP_SNAPSHOT`, `OPENCODE_AUTH_CONTENT` | Local persistence. See category 8. | No |

The docs list `OPENCODE_EXPERIMENTAL_SCOUT` ([opencode CLI, Environment variables](https://opencode.ai/docs/cli/#environment-variables)). A search of the source and of the binary strings found no such variable. The docs do not list `OPENCODE_DISABLE_SHARE`, `OPENCODE_DISABLE_EMBEDDED_WEB_UI`, `OPENCODE_DISABLE_PROJECT_CONFIG`, `OPENCODE_DISABLE_EXTERNAL_SKILLS`, or the `OTEL_` variables.

## Recommended configuration

### Env vars

Put these lines in the repository `.zshrc`, next to `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS`. The env vars are the strongest layer, and each of them wins over each config file. `OPENCODE_DISABLE_MODELS_FETCH` and `OPENCODE_DISABLE_LSP_DOWNLOAD` have no config key at all.

```sh
# opencode privacy. Research: docs/research/privacy-opencode.md
export OPENCODE_DISABLE_AUTOUPDATE=1    # no version lookup, no silent brew upgrade or git pull
export OPENCODE_DISABLE_MODELS_FETCH=1  # no fetch of models.opencode.ai; run `opencode models --refresh` by hand
export OPENCODE_DISABLE_SHARE=1         # no traffic to opncd.ai, whatever `share` a project sets
export OPENCODE_DISABLE_LSP_DOWNLOAD=1  # no LSP binary download, if a project turns LSP on
export OPENCODE_DISABLE_AUTOCOMPACT=1   # no auto-compaction, thus no synthetic "Continue" turn
export OPENCODE_DISABLE_PRUNE=1         # no removal of old tool outputs from the context
```

Do not export `OTEL_EXPORTER_OTLP_ENDPOINT`, `OPENCODE_EXPERIMENTAL`, `OPENCODE_ENABLE_EXA`, `OPENCODE_ENABLE_PARALLEL`, `OPENCODE_AUTO_SHARE`, or `OPENCODE_DISABLE_EMBEDDED_WEB_UI` in any shell file. If another tool must have an OTLP endpoint, set it for that command only.

### Config file

Keep this file in the repository as `.config/opencode/config.json`, so that stow links it to `~/.config/opencode/config.json`.

```json
{
  "$schema": "https://opencode.ai/config.json",
  "autoupdate": false,
  "share": "disabled",
  "lsp": false,
  "formatter": false,
  "compaction": {
    "auto": false,
    "prune": false
  },
  "experimental": {
    "openTelemetry": false
  }
}
```

Each key has a reason:

- `autoupdate: false` stops the upgrade check when opencode starts without the shell env, for example from the desktop app. The upgrade check reads this file.
- `share: "disabled"` makes `/share` fail with a clear error. The env var alone makes it return an empty URL.
- `lsp: false` and `formatter: false` are the 1.18.13 defaults. The explicit values keep them off if a later version changes a default.
- `compaction` gives the same values as the two compaction env vars. It applies when opencode starts without the shell env.
- `experimental.openTelemetry: false` is the default, written out. It has no env var.

### Why this layering

- The file is a new file, so the dotfiles never edit the `opencode.json` of the user. That file keeps its `plugin` and `agent` keys.
- opencode merges `config.json` first in the global directory. The `opencode.json` of the user can thus override a key here, for example `"lsp": true`. The env vars still apply over it.
- No normal opencode write goes to `config.json` while `opencode.json` exists. The `updateGlobal` patch picks `opencode.jsonc`, then `opencode.json`, then `config.json`. `mcp add` and `plugin` pick `opencode.json`.
- The upgrade check reads `config.json`, but it does not read `OPENCODE_CONFIG` or `OPENCODE_CONFIG_CONTENT`.
- The env vars cover the gap that each file layer has: a project `opencode.json` beats all the global files.

### Install without clobbering

1. Before stow runs, make sure that `~/.config/opencode` is a real directory, for example with `mkdir -p ~/.config/opencode`. Then stow links only the file. If stow folds the directory into one link, opencode writes `.gitignore`, `package.json`, and `node_modules` into the repository.
2. Keep `$schema` in the file. Without it, opencode writes `$schema` into the file at each start, through the link, into the repository.
3. Do not put `theme`, `keybinds`, or `tui` in the file. At the TUI start, opencode can move these keys to `tui.json` and edit the file.
4. Keep the `opencode.json` of the user in place. If it is absent, the `updateGlobal` patch of the web or desktop app picks `config.json` and writes through the link.
5. Do not point `OPENCODE_CONFIG_DIR` into the repository. A scratch run showed that opencode writes `.gitignore` there, and the npm install adds `package.json` and `node_modules`.
6. Add the env block to the repository `.zshrc`, which stow already links to `~/.zshrc`.
7. To make sure that the layers apply, run `opencode debug config` in a new shell. The output must show `"share": "disabled"`, `"autoupdate": false`, and `"compaction": { "auto": false, "prune": false }`.

### Optional

These keys are outside the core set, because each one changes a feature that the user can want. Add them to `config.json` if the user agrees.

```json
{
  "disabled_providers": ["opencode"],
  "agent": {
    "title": { "disable": true }
  },
  "permission": {
    "webfetch": "ask",
    "websearch": "ask"
  }
}
```

- `disabled_providers: ["opencode"]` stops the OpenCode Zen provider, which loads with free models and no key. It does not touch `opencode-go`. If the `opencode.json` of the user also sets `disabled_providers`, that array replaces this one.
- `agent.title.disable: true` stops the extra model call for the session title. The session then keeps its default title.
- The `permission` values are not privacy knobs. They make the model ask before it sends a URL or a query to a third party.

A `chat.headers` plugin can replace the values of `x-opencode-project`, `x-session-affinity`, `X-Session-Id`, and `User-Agent`. This research did not do a test of it. A changed value can break session affinity or billing on the OpenCode providers.

### Alternatives that this research does not recommend

- `~/.config/opencode/opencode.jsonc`: it beats the `opencode.json` of the user. But the `updateGlobal` patch of the web and desktop app writes into it first.
- `OPENCODE_CONFIG`: documented, and it beats the global files. But the upgrade check ignores it, and a project file beats it.
- `OPENCODE_CONFIG_CONTENT`, for example `export OPENCODE_CONFIG_CONTENT="$(< ~/.config/opencode/config.json)"`: it beats project files and `.opencode` directories. But the upgrade check ignores it, and the `opencode.json` of the user can no longer override a key.
- `/Library/Application Support/opencode/opencode.json`: it beats each user and project file. But only root can write it, and the upgrade check ignores it.
- `OPENCODE_DISABLE_PROJECT_CONFIG=1`: it stops each project file and each project `.opencode` directory, which removes project agents, commands, and plugins too.
- A jq merge into the `opencode.json` of the user: it edits a file that the user owns.

## Gaps

- **TUI syntax parsers.** The TUI registers tree-sitter WASM files and query files at GitHub URLs, and the binary holds these URLs ([session/index.tsx L86](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/tui/src/routes/session/index.tsx#L86), [parsers-config.ts](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/tui/src/parsers-config.ts)). The download code is in `@opentui/core`, which the tarball does not hold. This research did not find when and where the TUI fetches or caches them. It found no knob.
- **Header removal.** A config header or a `chat.headers` value replaces a header value. This research did not find out if an empty or `undefined` value removes the header in the AI SDK.
- **Two internal auth plugins.** `opencode-gitlab-auth` and `opencode-poe-auth` come from npm. This research did not read their source, so it cannot say that they make no request at load time.
- **`autoupdate: "notify"` with Homebrew.** The docs say that it does not work. The source shows no reason for that. No session ran to find out.
- **The embedded model catalog.** The build script puts a catalog snapshot in the binary, and the binary strings hold model IDs. This research did not find the date of that snapshot.
- **No traffic capture.** The findings come from the source and from `debug config` runs. A capture during one TUI session, for example with Little Snitch, would show the full list of hosts.
- **Desktop and web app.** `packages/desktop` and `packages/app` can have their own update or network code. This research did not read it.
- **The installed plugin types.** `~/.config/opencode/node_modules/@opencode-ai/plugin` is version 1.3.17, not 1.18.13. While `node_modules` exists, the npm install compares only package names, so it does not update this copy ([npm.ts L159-187](https://github.com/anomalyco/opencode/blob/v1.18.13/packages/core/src/npm.ts#L159-L187)). The 1.3.17 types have no `experimental.compaction.autocontinue` hook. This research did not find out if a plugin that uses the 1.18.13 hook must have the newer types.
