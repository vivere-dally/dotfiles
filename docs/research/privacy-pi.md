# Maximum-privacy configuration of pi 0.85.1

- Date of the research: 2026-09-19.
- Version: pi 0.85.1, package `@earendil-works/pi-coding-agent`. The source is tag `v0.85.1` of `github.com/earendil-works/pi`, directory `packages/coding-agent`.
- `PI` is a short name for the installed package: `/Users/s-ved/dotfiles/.nvm/versions/node/v24.11.1/lib/node_modules/@earendil-works/pi-coding-agent`. A citation such as `PI/dist/core/telemetry.js:6-8` means that file, lines 6 to 8.
- `PI-AI` is a short name for `PI/node_modules/@earendil-works/pi-ai`, the provider library that pi installs.
- A link to `github.com` points to the TypeScript source at tag `v0.85.1`, with line anchors.

This research read files only. It started no pi session, ran no git command, and wrote nothing to `~/.pi`. The `pi` command runs `PI/dist/bundle/cli.js`. The same build makes that bundle from the files in `PI/dist`. The citations use the files in `PI/dist` because a person can read them. Each key string of this report is also in `PI/dist/bundle/chunks/chunk-JVUZSMYM.js`, for example `api/report-install`, `api/latest-version`, `PI_TELEMETRY`, and `X-OpenRouter-Title`.

Three tests ran the `SettingsManager` module of pi on files in a scratchpad directory, not in `~/.pi`. A fourth test ran the `jq` merge of the recommendation on scratchpad files. The tests confirmed the write behavior in "Config mechanics".

## Summary

- Without a request from you, pi sends three kinds of requests to `pi.dev`: an install and update ping, a version check, and model catalog requests.
- `PI_OFFLINE=1` stops all three. It also stops the package update check, the automatic install of missing packages, and the download of `fd` and `rg`.
- `PI_OFFLINE=1` does not stop the provider attribution headers for OpenRouter, NVIDIA NIM, and Cloudflare. Only `PI_TELEMETRY=0` or `"enableInstallTelemetry": false` stops them. The same knob stops the install ping, and nothing else.
- `PI_TELEMETRY` wins over the settings files. A trusted project can set `enableInstallTelemetry` to `true` in `.pi/settings.json`, but a project cannot change an environment variable.
- pi 0.85.1 has no remote error report, no analytics sender, no feedback survey, and no automatic update.
- pi adds no `Co-Authored-By` trailer and no "Generated with" line. Its system prompt has no git instruction.
- `/share` uploads the session only when you type the command. No knob disables it.
- `compaction.enabled` and `retry.enabled` are settings only. No environment variable or flag controls them.
- pi writes some keys into `~/.pi/agent/settings.json`. It reads the file again, replaces only the keys that it changed, and keeps all other keys.
- Recommendation: put the environment variables in the shell profile. Merge a small managed JSON object into `~/.pi/agent/settings.json` with `jq` from an install script. Do not symlink the file.

## Claude Code settings and the pi equivalents

| Claude Code setting | pi equivalent | Details |
| --- | --- | --- |
| `DISABLE_TELEMETRY` | `PI_TELEMETRY=0` and `"enableInstallTelemetry": false`. Also set `"enableAnalytics": false`, which no code reads in 0.85.1. | Section 1 |
| `DISABLE_ERROR_REPORTING` | No equivalent is necessary. pi has no remote error report. | Section 2 |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `PI_OFFLINE=1`, which also sets `PI_SKIP_VERSION_CHECK=1`. pi has no automatic update to stop. | Sections 3 and 4 |
| Empty commit and PR attribution, no `Co-Authored-By` | Nothing to set for commits. For the provider attribution headers, set `PI_TELEMETRY=0`. | Section 6 |
| No session URL | Nothing to set. pi adds no session URL to a commit or a pull request. | Section 6 |
| Feedback surveys off | Nothing to set. A search found no survey. | Section 2 |
| Auto-compact off | `"compaction": { "enabled": false }` | Section 7 |
| Auto-continue off | The closest pi behaviors are the compaction retry after a context overflow and the retry after a transient error. `compaction.enabled: false` stops the first. `retry.enabled: false` stops the second. | Section 7 |

## 1. Telemetry, analytics, and usage metrics

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `enableInstallTelemetry` | boolean setting | `true` | When `true`, pi sends the install and update ping, and the provider attribution headers. | `PI/dist/core/settings-manager.js:697-699`, `PI/docs/settings.md:60`, `PI/docs/settings.md:82-84`, [settings-manager.ts#L1009-L1011](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/settings-manager.ts#L1009-L1011) |
| `PI_TELEMETRY` | environment variable | unset | When set, it replaces the setting. `1`, `true`, and `yes` mean on. Each other value means off. | `PI/dist/core/telemetry.js:1-8`, [telemetry.ts#L3-L13](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/telemetry.ts#L3-L13) |
| `enableAnalytics` | boolean setting | `false` | Stored consent for usage analytics. No code in 0.85.1 reads it to send data. | `PI/dist/core/settings-manager.js:705-720`, `PI/docs/settings.md:61` |
| `trackingId` | string setting | unset | A random UUID that pi writes when `enableAnalytics` changes to `true`. No code reads it to send data. | `PI/dist/core/settings-manager.js:708-718`, `PI/docs/settings.md:62` |
| `PI_EXPERIMENTAL` | environment variable | unset | `1` shows the first-time setup, which asks for analytics consent. The setup shows only when `settings.json` is absent. | `PI/dist/core/experimental.js:2-4`, `PI/dist/cli/startup-ui.js:82-104` |
| `PI_OFFLINE`, `--offline` | environment variable, flag | unset | Stops the install ping before pi reads the telemetry knob. It does not stop the attribution headers. | `PI/dist/modes/interactive/interactive-mode.js:930-936` |

The install and update ping:

- The request is `GET https://pi.dev/api/report-install?version=<version>`. pi sets one header, `User-Agent: pi/<version> (<platform>; node/<node version>; <arch>)` (`PI/dist/modes/interactive/interactive-mode.js:930-945`, `PI/dist/utils/pi-user-agent.js:1-4`, [interactive-mode.ts#L1239-L1256](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/modes/interactive/interactive-mode.ts#L1239-L1256)).
- Only the interactive mode sends it. It goes out on the first interactive start with no `lastChangelogVersion`, and on the first interactive start after an update of pi (`PI/dist/modes/interactive/interactive-mode.js:908-929`).
- A search of `PI/dist` outside the bundle for `reportInstallTelemetry` found only `interactive-mode.js`. Thus print mode, JSON mode, and RPC mode do not send the ping.
- The gates come in this order: `PI_OFFLINE`, then `PI_TELEMETRY`, then the merged settings (`PI/dist/modes/interactive/interactive-mode.js:930-936`, `PI/dist/core/telemetry.js:6-8`).
- `getEnableInstallTelemetry` reads the merged settings, not the global file only (`PI/dist/core/settings-manager.js:151`, `PI/dist/core/settings-manager.js:697-699`). Thus a trusted project can set the knob to `true` again. `PI_TELEMETRY=0` prevents this.
- The `/settings` item "Install telemetry" says "Send an anonymous version/update ping after changelog-detected updates" (`PI/dist/modes/interactive/components/settings-selector.js:331-337`). The source also uses this knob for the attribution headers (`PI/dist/core/provider-attribution.js:27-30`). The source wins. `PI/docs/settings.md:84` agrees with the source.

Analytics:

- The only code that writes `enableAnalytics` is the experimental first-time setup (`PI/dist/cli/startup-ui.js:125-137`).
- The setup runs only when four conditions are true: the official distribution, `PI_EXPERIMENTAL=1`, no `PI_CODING_AGENT_DIR`, and no `settings.json` (`PI/dist/cli/startup-ui.js:82-104`).
- The setup selects "Share anonymous usage data" as the first choice (`PI/dist/modes/interactive/components/first-time-setup.js:10-13`, `PI/dist/modes/interactive/components/first-time-setup.js:19`). A settings file from the dotfiles prevents the setup.
- A search of `PI/dist` and `PI/node_modules/@earendil-works` for `getEnableAnalytics`, `getTrackingId`, `trackingId`, and `enableAnalytics` found only the definitions and the setup. The bundle chunk has the same result. Thus no code sends analytics in 0.85.1.
- The setup text says "You can observe what is shared using /privacy" (`PI/dist/modes/interactive/components/first-time-setup.js:44`). The list of built-in commands has no `/privacy` command (`PI/dist/core/slash-commands.js:2-26`).
- pi installs the package `@earendil-works/pi-telemetry`. Its README says that it has "no exporter" (`PI/node_modules/@earendil-works/pi-telemetry/README.md:11`). The agent core uses a no-op context when the application gives none (`PI/node_modules/@earendil-works/pi-agent-core/dist/harness/context.js:4-7`).
- A search of `PI/dist` outside the bundle for `TelemetryContext` and `NOOP_TELEMETRY` found no use.

## 2. Error and crash reporting

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| Remote error report | none | none | pi 0.85.1 sends no error report and no crash report. | Searches below |
| `pi-tui-crash.log` | local file | written on a render crash | When a rendered line is wider than the terminal, the TUI writes all rendered lines to `<agent dir>/pi-tui-crash.log`. The lines can contain transcript text. | `PI/node_modules/@earendil-works/pi-tui/dist/tui-main-screen.js:469-481`, `PI/dist/modes/interactive/interactive-mode.js:324` |
| Uncaught exception | stderr only | on | pi restores the terminal, prints the error to stderr, and stops. | `PI/dist/modes/interactive/interactive-mode.js:3291-3293`, `PI/dist/modes/interactive/interactive-mode.js:3333-3337` |

Searches that found no remote report and no survey:

- A word search, not case-sensitive, of `PI/dist` and `PI/node_modules/@earendil-works` for `sentry`, `posthog`, `mixpanel`, `amplitude`, `datadog`, `opentelemetry`, `bugsnag`, `rollbar`, and `statsig`. It found no match. The search skipped the vendored highlight.js files.
- A search of `PI/dist` for `crash`, `uncaughtException`, and `unhandledRejection`. It found only the local handlers above and comments.
- A word search of `PI/dist` for `survey`, `feedback`, `rating`, and `nps`. It found only a code comment and a word in the HTML export template.

## 3. Update checks

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `PI_SKIP_VERSION_CHECK` | environment variable | unset | Any value that is not empty stops the request to `https://pi.dev/api/latest-version`. | `PI/dist/utils/version-check.js:65-67`, `PI/docs/environment-variables.md:85`, [version-check.ts#L97-L109](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/utils/version-check.ts#L97-L109) |
| `PI_OFFLINE` | environment variable | unset | `1`, `true`, or `yes` puts the process in offline mode. pi then sets `PI_OFFLINE=1` and `PI_SKIP_VERSION_CHECK=1`. | `PI/dist/main.js:440-444`, [main.ts#L565-L569](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/main.ts#L565-L569) |
| `--offline` | flag | off | The same as `PI_OFFLINE=1` for one run. | `PI/dist/main.js:440`, `PI/dist/cli/args.js:211-213`, `PI/dist/cli/args.js:309` |
| Automatic update | none | none | pi does not update itself. It shows a notice with the command `pi update`. | `PI/dist/modes/interactive/interactive-mode.js:3530-3552` |
| Package update check | no own knob | on | At an interactive start, pi asks npm and git about newer versions of each unpinned entry in `packages`. It shows a notice only. `PI_OFFLINE` stops it. | `PI/dist/modes/interactive/interactive-mode.js:769-782`, `PI/dist/modes/interactive/interactive-mode.js:846-862`, `PI/dist/core/package-manager.js:925-980` |
| Model catalog refresh | no own knob | on | pi requests `https://pi.dev/api/models/providers/<provider>` for each built-in provider that has a credential. `PI_OFFLINE` stops it. | `PI/dist/core/remote-catalog-provider.js:4-6`, `PI/dist/core/remote-catalog-provider.js:56-75`, `PI/dist/core/model-runtime.js:83-88`, `PI-AI/dist/models.js:133-162`, [remote-catalog-provider.ts#L68-L90](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/remote-catalog-provider.ts#L68-L90) |
| `pi update --models` | command | none | Forces a catalog refresh. It sets `allowNetwork: true`, thus it works with `PI_OFFLINE=1`. | `PI/dist/package-manager-cli.js:511-527`, `PI/dist/package-manager-cli.js:786-790` |
| Changelog display | local | on | After an update, pi shows the new entries of its local `CHANGELOG.md`. It uses no network. | `PI/dist/modes/interactive/interactive-mode.js:505-530`, `PI/dist/modes/interactive/interactive-mode.js:908-929` |
| `collapseChangelog` | boolean setting | `false` | Shows one line in place of the full changelog. | `PI/docs/settings.md:59`, `PI/dist/modes/interactive/interactive-mode.js:517-521` |
| `lastChangelogVersion` | string setting that pi writes | unset | pi compares it with the version that runs, to find the new changelog entries. | `PI/dist/core/settings-manager.js:442-449` |

The version check:

- The request is `GET https://pi.dev/api/latest-version` with the pi `User-Agent` and a timeout of 10 seconds (`PI/dist/utils/version-check.js:4-5`, `PI/dist/utils/version-check.js:36-47`).
- Only the interactive mode starts it (`PI/dist/modes/interactive/interactive-mode.js:763-768`, [interactive-mode.ts#L1034-L1066](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/modes/interactive/interactive-mode.ts#L1034-L1066)).
- The response can have a `note`. pi shows that text from the server in the update notice (`PI/dist/utils/version-check.js:54-60`, `PI/dist/modes/interactive/interactive-mode.js:3538-3548`).

The `pi update` command:

- `pi update` with no target updates pi itself. It asks `pi.dev` for the latest release, and it installs the `packageName` that the response names (`PI/dist/package-manager-cli.js:574-596`).
- With `PI_OFFLINE=1`, the self-update stops with the error "Could not determine latest pi version." (`PI/dist/utils/version-check.js:37-38`, `PI/dist/package-manager-cli.js:584-586`). Package updates also stop (`PI/dist/core/package-manager.js:842-845`).
- To update, remove the variable for one command: `env -u PI_OFFLINE pi update`.

The model catalog refresh:

- It runs at an interactive start, when `/model` opens, for `/model <search>` with no cached match, for `/scoped-models`, after `/login`, and at an RPC start.
- The sources of these triggers are `PI/dist/modes/interactive/interactive-mode.js:755-762`, `PI/dist/modes/interactive/interactive-mode.js:4060-4071`, `PI/dist/modes/interactive/interactive-mode.js:4256-4263`, `PI/dist/modes/interactive/interactive-mode.js:4793-4796`, `PI/dist/modes/interactive/components/model-selector.js:125-133`, and `PI/dist/main.js:743-750`.
- After a request with a stored result, pi skips that provider for 4 hours, unless the refresh is forced (`PI/dist/core/remote-catalog-provider.js:6`, `PI/dist/core/remote-catalog-provider.js:58-63`).
- Each request tells `pi.dev` the ID of a provider that has a credential on this machine (`PI/dist/core/remote-catalog-provider.js:67-75`, `PI-AI/dist/models.js:157-162`).
- A refresh can also renew an expired OAuth token of that provider (`PI-AI/dist/models.js:189-204`).
- No setting, flag, or environment variable changes the catalog URL. A search of `PI/dist` for `catalogBaseUrl` found only an option of the SDK (`PI/dist/core/model-runtime.js:83-87`, `PI/dist/core/remote-catalog-provider.js:41`).

Different checks read `PI_OFFLINE` in different ways:

- `main.js`, the package manager, and the tool download accept only `1`, `true`, or `yes` (`PI/dist/main.js:75-79`, `PI/dist/core/package-manager.js:37-42`, `PI/dist/utils/tools-manager.js:12-17`).
- The version check, the startup catalog refresh, the startup package check, and the install ping accept any value that is not empty (`PI/dist/utils/version-check.js:37`, `PI/dist/modes/interactive/interactive-mode.js:755`, `PI/dist/modes/interactive/interactive-mode.js:847`, `PI/dist/modes/interactive/interactive-mode.js:931`).
- The model runtime stops the catalog network when the variable exists at all, even with an empty value (`PI/dist/core/model-runtime.js:88`, [model-runtime.ts#L196](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/model-runtime.ts#L196)).
- Thus `PI_OFFLINE=0` gives a mixed state. Set `PI_OFFLINE=1`. To use the network for one command, remove the variable with `env -u PI_OFFLINE`.

## 4. Other background network at startup or during a session

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `fd` and `rg` download | no own knob | on when a tool is missing | If `fd` or `rg` is not in `~/.pi/agent/bin` and not on `PATH`, pi downloads the latest release from GitHub. The interactive start and the `find` and `grep` tools do this. `PI_OFFLINE` stops it. | `PI/dist/utils/tools-manager.js:75-121`, `PI/dist/utils/tools-manager.js:229-248`, `PI/dist/utils/tools-manager.js:300-324`, `PI/dist/modes/interactive/interactive-mode.js:699-705`, `PI/dist/core/tools/grep.js:52`, `PI/dist/core/tools/find.js:119` |
| Install of a missing package | no own knob | on | At each start, pi installs each entry of `packages` that is absent, with npm or git, and with no prompt. `PI_OFFLINE` stops the install and skips the package. | `PI/dist/core/package-manager.js:981-1037`, `PI/dist/core/resource-loader.js:263-276` |
| Refresh of a temporary git source | no own knob | on | An unpinned `git:` source that you give with `-e` gets a pull at each start. `PI_OFFLINE` stops it. | `PI/dist/core/package-manager.js:1030-1032`, `PI/dist/core/package-manager.js:1618-1627` |
| llama.cpp built-in extension | none | inactive | It contacts a llama.cpp server only after you configure it with `/login llama.cpp` or `LLAMA_BASE_URL`. | `PI/dist/extensions/index.js:1-2`, `PI/dist/extensions/llama/provider.js:88-125` |
| `httpProxy` | string setting, global only | unset | pi sets `HTTP_PROXY` and `HTTPS_PROXY` from it. | `PI/docs/settings.md:92`, `PI/dist/main.js:454-456`, `PI/dist/main.js:685-686` |

On this machine, `fd` and `rg` are on `PATH` from Homebrew. Thus pi does not download them here. The tmux keyboard check at startup runs the local `tmux` command only (`PI/dist/modes/interactive/interactive-mode.js:863-903`).

## 5. Session sharing and upload of transcripts

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `/share` | command | available | Uploads the current session branch. No setting, flag, or environment variable disables it. | `PI/dist/core/slash-commands.js:10`, `PI/dist/modes/interactive/interactive-mode.js:2399-2403`, `PI/dist/modes/interactive/interactive-mode.js:5135-5144` |
| `PI_SHARE_VIEWER_URL` | environment variable | `https://pi.dev/session/` | Changes only the viewer link that pi prints. It does not change the upload target. | `PI/dist/config.js:411-416` |
| `/export`, `--export` | command, flag | none | Writes an HTML or JSONL file on the local disk. It uses no network. | `PI/dist/core/slash-commands.js:8`, `PI/dist/main.js:487-500` |
| `pi-share-hf` | separate tool | not installed | The README asks open-source users to publish sessions with this separate tool. pi does not include it. | `PI/README.md:21-29` |

How `/share` works:

- `/share` runs only for the exact text `/share`. pi shows no confirmation (`PI/dist/modes/interactive/interactive-mode.js:2399-2403`).
- The submit handler runs the built-in commands first, before `session.prompt` (`PI/dist/modes/interactive/interactive-mode.js:2361-2403`). The extension commands and the `input` event run later, in the prompt (`PI/docs/extensions.md:911-921`). Thus an extension cannot block `/share` with the `input` event.
- First, pi tries Radius. If the `radius` provider has a token, pi sends the session JSONL with `POST https://radius.pi.dev/v1/artifacts?visibility=organization&title=Pi+session` (`PI/dist/modes/interactive/session-share.js:77-107`, `PI-AI/dist/providers/radius-config.js:1`, [session-share.ts#L87-L146](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/modes/interactive/session-share.ts#L87-L146)).
- Else pi exports HTML, runs `gh gist create --public=false`, and prints a link to `https://pi.dev/session/#<gist id>` (`PI/dist/modes/interactive/session-share.js:48-66`, `PI/dist/modes/interactive/session-share.js:130-170`).
- The upload contains the system prompt and the tool definitions, in addition to the messages (`PI/dist/modes/interactive/session-share.js:14-31`).

## 6. Attribution

### Provider attribution headers

| Provider match | Headers | Source |
| --- | --- | --- |
| OpenRouter: provider `openrouter`, or a base URL that contains `openrouter.ai` | `HTTP-Referer: https://pi.dev`, `X-OpenRouter-Title: pi`, `X-OpenRouter-Categories: cli-agent` | `PI/dist/core/provider-attribution.js:15-17`, `PI/dist/core/provider-attribution.js:31-37` |
| NVIDIA NIM: provider `nvidia`, or host `integrate.api.nvidia.com` | `X-BILLING-INVOKE-ORIGIN: Pi` | `PI/dist/core/provider-attribution.js:18-20`, `PI/dist/core/provider-attribution.js:38-42` |
| Cloudflare: provider `cloudflare-workers-ai` or `cloudflare-ai-gateway`, or host `api.cloudflare.com` or `gateway.ai.cloudflare.com` | `User-Agent: pi-coding-agent` | `PI/dist/core/provider-attribution.js:21-26`, `PI/dist/core/provider-attribution.js:43-47` |

- The knob is `"enableInstallTelemetry": false` or `PI_TELEMETRY=0` (`PI/dist/core/provider-attribution.js:27-30`, [provider-attribution.ts#L36-L65](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/provider-attribution.ts#L36-L65)).
- The same knob also stops the install and update ping. It changes nothing else. A search of `PI/dist` outside the bundle for `isInstallTelemetryEnabled(` found only these two callers (`PI/dist/core/provider-attribution.js:28`, `PI/dist/modes/interactive/interactive-mode.js:934`).
- `PI_OFFLINE` does not stop these headers, because the header code reads only the telemetry knob.
- pi adds the headers to each provider request through `transformHeaders` (`PI/dist/core/sdk.js:200-205`). The headers of the request come after the defaults, thus they win (`PI/dist/core/provider-attribution.js:60-71`).
- An extension can remove a header with the `before_provider_headers` event (`PI/docs/extensions.md:687-703`).

These identifiers have no knob:

| Where | Identifier | Source |
| --- | --- | --- |
| opencode: provider `opencode` or `opencode-go`, or host `opencode.ai` | `x-opencode-session: <session id>`, `x-opencode-client: pi` | `PI/dist/core/provider-attribution.js:50-59`, [provider-attribution.ts#L67-L77](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/provider-attribution.ts#L67-L77) |
| OpenAI Codex requests | `originator: pi` and the pi `User-Agent` | `PI-AI/dist/api/openai-codex-responses.js:1274-1275` |
| xAI OAuth login | `referrer: pi` in the device-code request | `PI-AI/dist/auth/oauth/xai.js:118` |

### Commit and pull request attribution

- The default system prompt has no git instruction, no trailer, and no "Generated with" text (`PI/dist/core/system-prompt.js:77-115`).
- The only guideline of the `bash` tool is about the `PI_*` environment variables (`PI/dist/core/tools/bash.js:30-33`).
- A search, not case-sensitive, of `PI/dist` outside the bundle used these terms: `co-authored`, `coauthored`, `generated with`, `generated by`, `trailer`, `attribution`, `git commit`, `commit message`, and `pull request`.
- The search found only the header code in `provider-attribution.js` and `sdk.js`, and two code comments. Thus pi adds no attribution to a commit or a pull request.
- pi sets `AI_AGENT=pi` and `PI_CODING_AGENT=true` in its own process. Child processes, for example git hooks, get these variables. pi does not write them into a commit (`PI/dist/cli/setup.js:3-7`, `PI/docs/environment-variables.md:11-18`).

## 7. Uncontrolled behavior

### Automatic behavior

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `compaction.enabled` | boolean setting | `true` | When `false`, pi does no automatic compaction, at the threshold or after a context overflow. `/compact` still works. | `PI/dist/core/settings-manager.js:548-550`, `PI/dist/core/compaction/compaction.js:160-164`, `PI/dist/core/agent-session.js:274-286`, `PI/dist/core/agent-session.js:1634-1640` |
| Retry after a context overflow | no own knob | on | pi compacts and then continues the interrupted turn one time. `compaction.enabled: false` stops it. | `PI/dist/core/agent-session.js:1655-1695`, `PI/dist/core/agent-session.js:1845-1862` |
| `retry.enabled` | boolean setting | `true` | When `true`, pi waits and then continues the turn after a transient provider error, up to `retry.maxRetries` times. | `PI/dist/core/settings-manager.js:581-598`, `PI/dist/core/agent-session.js:429-440`, `PI/dist/core/agent-session.js:2285-2300` |
| `retry.maxRetries`, `retry.baseDelayMs` | number settings | `3`, `2000` | The number of agent retries and the first delay. | `PI/docs/settings.md:143-145`, `PI/dist/core/settings-manager.js:592-598` |
| `retry.provider.maxRetries` | number setting | `0` | Retries in the provider SDK. The default is already `0`. | `PI-AI/dist/utils/provider-retry.js:75-77`, `PI/docs/settings.md:147` |
| `defaultProjectTrust` | string setting, global only | `"ask"` | What pi does for a project with `.pi` resources and no saved decision: `"ask"`, `"always"`, or `"never"`. Without a UI, `"ask"` ignores the project resources. | `PI/dist/core/settings-manager.js:664-667`, `PI/dist/core/project-trust.js:17-58`, `PI/docs/security.md:18-29` |
| `--approve` or `-a`, `--no-approve` or `-na` | flags | none | Trust or ignore the project resources for one run. | `PI/dist/cli/args.js:205-210` |
| Project packages and extensions | no own knob | after trust | After you trust a project, pi installs its missing packages and runs its extensions. | `PI/docs/security.md:20-25`, `PI/dist/core/package-manager.js:981-1037` |
| User extensions | no own knob | on | pi loads each extension from `~/.pi/agent/extensions` and from `extensions` and `packages` in the global settings, with no prompt. | `PI/docs/extensions.md:109-135` |
| `--no-extensions` or `-ne` | flag | off | Stops extension discovery. Paths that you give with `-e` still load. | `PI/dist/cli/args.js:139-141`, `PI/dist/cli/args.js:294` |
| Context files | no own knob | on | pi loads `AGENTS.md` and `CLAUDE.md` files before project trust, and without it. `--no-context-files` or `-nc` stops this. | `PI/docs/security.md:27`, `PI/dist/cli/args.js:173-175` |
| Automatic write of `theme` | no own knob | on when `theme` is unset | pi detects the terminal background and writes `theme` when the detection has "high" confidence. | `PI/dist/modes/interactive/theme/theme-controller.js:38-49` |
| Automatic update | none | none | pi does not update itself or its packages without a command. | `PI/dist/modes/interactive/interactive-mode.js:3530-3561` |

### Tool and permission knobs

These knobs are not privacy knobs.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| `defaultTools` | string array setting | `read`, `bash`, `edit`, `write` | The built-in tools at the start. | `PI/docs/settings.md:222-244`, `PI/dist/core/system-prompt.js:13` |
| `--tools` or `-t` | flag | none | An allowlist of all tools. | `PI/dist/cli/args.js:100-105`, `PI/dist/cli/args.js:288-289` |
| `--exclude-tools` or `-xt` | flag | none | A denylist of tools. | `PI/dist/cli/args.js:106-111` |
| `--no-tools` or `-nt` | flag | off | No tools. | `PI/dist/cli/args.js:94-96` |
| `--no-builtin-tools` or `-nbt` | flag | off | No built-in tools. Extension tools stay. | `PI/dist/cli/args.js:97-99` |
| Permission prompt | none | none | pi has no permission prompt and no sandbox. An extension can block a tool call with the `tool_call` event. | `PI/README.md:503`, `PI/docs/security.md:31-37` |
| `images.blockImages` | boolean setting | `false` | Stops all images to the model. | `PI/docs/settings.md:190` |
| `shellPath`, `shellCommandPrefix` | string settings | unset | The shell and a prefix for each bash command. | `PI/docs/settings.md:196-197` |
| `enableSkillCommands` | boolean setting | `true` | Registers each skill as a `/skill:name` command. | `PI/docs/settings.md:290` |

## 8. Local persistence

This section lists the knobs only. This report does not recommend a change to them.

| Knob | Type | Default | Effect | Source |
| --- | --- | --- | --- | --- |
| Session files | directory | `~/.pi/agent/sessions/` | One JSONL file for each session, in a directory for each working directory. | `PI/docs/sessions.md:7` |
| `--no-session` | flag | off | Keeps the session in memory only. | `PI/dist/cli/args.js:76-78`, `PI/dist/main.js:280-281` |
| `--session-dir` | flag | unset | The session directory for one run. | `PI/dist/cli/args.js:88-90` |
| `PI_CODING_AGENT_SESSION_DIR` | environment variable | unset | The session directory. | `PI/dist/config.js:407`, `PI/dist/main.js:531-535` |
| `sessionDir` | string setting | unset | The session directory. The flag wins, then the environment variable, then the setting. | `PI/docs/settings.md:246-256`, `PI/dist/main.js:531-535` |
| `PI_CODING_AGENT_DIR` | environment variable | `~/.pi/agent` | Moves the whole agent directory: settings, credentials, sessions, trust, and caches. | `PI/dist/config.js:406`, `PI/dist/config.js:421-427` |
| `models-store.json` | file | in the agent directory | The model catalog cache. | `PI/dist/core/model-runtime.js:76-81` |
| `trust.json` | file | in the agent directory | The saved project trust decisions. | `PI/docs/settings.md:14`, `PI/docs/settings.md:22` |
| `auth.json` | file | in the agent directory | The provider credentials. | `PI/dist/config.js:437-439` |
| `bin/`, `npm/`, `git/` | directories | in the agent directory | The downloaded tools and the installed packages. | `PI/dist/config.js:449`, `PI/README.md:438` |
| `pi-tui-crash.log` | file | in the agent directory | The TUI writes it on a render crash. | `PI/node_modules/@earendil-works/pi-tui/dist/tui-main-screen.js:469-481` |

## Config mechanics

### Files and precedence

1. The global file is `<agent dir>/settings.json`. The agent directory is `~/.pi/agent`, or the value of `PI_CODING_AGENT_DIR` (`PI/dist/core/settings-manager.js:51-56`, `PI/dist/config.js:421-427`).
2. The project file is `<cwd>/.pi/settings.json`. pi reads it only for a trusted project. Else pi uses an empty object (`PI/dist/core/settings-manager.js:188-191`).
3. pi merges the project file over the global file. Objects merge key by key. An array or another value replaces the global value (`PI/dist/core/settings-manager.js:9-30`, `PI/dist/core/settings-manager.js:151`).
4. The only flag that overrides a setting is `--use-theme`. It replaces `theme` for one run (`PI/dist/main.js:523-525`, `PI/dist/core/settings-manager.js:316-318`).
5. `PI_TELEMETRY` wins over `enableInstallTelemetry` (`PI/dist/core/telemetry.js:6-8`).
6. For the session directory, `--session-dir` wins, then `PI_CODING_AGENT_SESSION_DIR`, then `sessionDir` (`PI/dist/main.js:531-535`).
7. `PI_OFFLINE`, `PI_SKIP_VERSION_CHECK`, and `PI_EXPERIMENTAL` have no settings key.

More facts about the files:

- pi reads `defaultProjectTrust` and `httpProxy` from the global file only. A project file cannot change them (`PI/dist/core/settings-manager.js:664-667`, `PI/dist/main.js:455`, `PI/dist/main.js:685`).
- pi reads all other keys from the merged settings. Thus a trusted project can change `enableInstallTelemetry`, `compaction`, `retry`, and `packages` (`PI/dist/core/settings-manager.js:548-550`, `PI/dist/core/settings-manager.js:581-583`, `PI/dist/core/settings-manager.js:697-699`).
- The file is strict JSON. pi reads it with `JSON.parse`, thus a comment is not permitted (`PI/dist/core/settings-manager.js:200`).
- If the global file is not valid JSON, pi uses an empty object and shows a warning. It then does not write the file (`PI/dist/core/settings-manager.js:203-210`, `PI/dist/core/settings-manager.js:401-405`, `PI/dist/core/settings-diagnostics.js:1-6`). Thus a syntax error removes each privacy setting until you correct the file. A scratchpad test confirmed that pi did not write an invalid file.
- There is no include mechanism and no flag for a settings file. A search of `settings-manager.js` for `include`, `extends`, `$ref`, and `import(` found only calls of `.includes(`. A search of `cli/args.js` for `--settings` and `--config` found nothing.
- `PI_CODING_AGENT_DIR` is the only way to point pi at a different global file. It also moves the credentials, the sessions, and the trust decisions. It also stops the first-time setup (`PI/dist/cli/startup-ui.js:100-102`).

### The keys that pi writes

| Key | When pi writes it | Source |
| --- | --- | --- |
| `lastChangelogVersion` | At an interactive start of a new session, when the key is absent or older than the version that runs. pi writes it also in offline mode. | `PI/dist/modes/interactive/interactive-mode.js:599-604`, `PI/dist/modes/interactive/interactive-mode.js:908-929` |
| `theme` | At an interactive start when `theme` is unset and the detection has "high" confidence. Also from `/settings` and from the first-time setup. | `PI/dist/modes/interactive/theme/theme-controller.js:38-49`, `PI/dist/modes/interactive/interactive-mode.js:3879`, `PI/dist/cli/startup-ui.js:135` |
| `defaultProvider`, `defaultModel` | Ctrl+S in `/model`. After `/login`, when pi does not know the current model. | `PI/dist/core/agent-session.js:1254-1265`, `PI/dist/modes/interactive/interactive-mode.js:4171-4178`, `PI/dist/modes/interactive/interactive-mode.js:4741-4766` |
| `enabledModels` | `/scoped-models`. Also when you save a default model while a model scope is active. | `PI/dist/modes/interactive/interactive-mode.js:4255`, `PI/dist/core/agent-session.js:1272-1285` |
| `defaultThinkingLevel` | Ctrl+S in `/thinking`. | `PI/dist/core/agent-session.js:1360-1369`, `PI/dist/modes/interactive/interactive-mode.js:4010-4015` |
| `modelThinkingLevels` and each other `/settings` item, for example `compaction.enabled`, `enableInstallTelemetry`, and `defaultProjectTrust` | When you change the item in `/settings`. | `PI/dist/modes/interactive/interactive-mode.js:3805-3990` |
| `compaction.enabled`, `retry.enabled` | The RPC commands for automatic compaction and automatic retry. | `PI/dist/modes/rpc/rpc-mode.js:424`, `PI/dist/modes/rpc/rpc-mode.js:431` |
| `packages` | `pi install`, `pi remove`, and `pi config`. | `PI/dist/core/package-manager.js:633-662`, `PI/dist/modes/interactive/components/config-selector.js:509-512` |
| `extensions`, `skills`, `prompts`, `themes` | `pi config`. | `PI/dist/modes/interactive/components/config-selector.js:441-464` |
| `enableAnalytics`, `trackingId` | The experimental first-time setup only. | `PI/dist/cli/startup-ui.js:135-137` |
| `apiKeys` (removal) | A one-time migration moves a legacy `apiKeys` object to `auth.json`. | `PI/dist/migrations.js:41-55` |

On this machine, `~/.pi/agent/settings.json` holds `lastChangelogVersion`, `theme`, `defaultProvider`, and `defaultModel`. The table above explains each of these four keys.

### How pi writes the file

1. pi keeps a list of the keys that it changed in the session (`PI/dist/core/settings-manager.js:320-338`).
2. For a write, pi reads the current file again, and applies the legacy migrations. Then it replaces only the changed keys (`PI/dist/core/settings-manager.js:376-400`, [settings-manager.ts#L620-L648](https://github.com/earendil-works/pi/blob/v0.85.1/packages/coding-agent/src/core/settings-manager.ts#L620-L648)).
3. For a nested key such as `compaction.enabled`, pi replaces only that nested key. For a key at the top level, pi writes the value that it holds in memory.
4. pi keeps each key that it did not change, and each unknown key. A new key goes at the end.
5. pi writes `JSON.stringify(settings, null, 2)`. The result has a two-space indent and no final newline (`PI/dist/core/settings-manager.js:398`).
6. pi writes in place with `writeFileSync` (`PI/dist/core/settings-manager.js:81-109`). A scratchpad test confirmed that a symlink stays, and that the write changes the target file of the symlink.
7. The lock is a `settings.json.lock` directory beside the file (`PI/dist/core/settings-manager.js:57-64`, `PI/node_modules/proper-lockfile/lib/lockfile.js:11-13`).

A scratchpad test changed the file from outside while a `SettingsManager` was open. Then pi wrote `compaction.enabled`. The external key stayed, and pi added `enabled` into the existing `compaction` object.

### What this means for the dotfiles

- A symlink from `~/.pi/agent/settings.json` into the repository does not work well. pi writes `lastChangelogVersion` after each update, and `theme` and the model defaults on some actions. Each write goes into the repository file and changes its format.
- Environment variables alone do not work. `compaction.enabled` and `retry.enabled` have no environment variable.
- `PI_CODING_AGENT_DIR` also moves the credentials and the sessions. It does not give a layer for settings only.
- A project `.pi/settings.json` applies only to one trusted directory tree.
- Thus the best approach is a merge step. The dotfiles own a small JSON object. An install script merges that object into the live file, and pi keeps its own keys.

## Recommended configuration

### Environment variables

Put these lines in the shell profile, for example beside `OPENSPEC_TELEMETRY=0` in the `.zshrc` of the dotfiles:

```sh
# pi: no install ping, no provider attribution headers (wins over settings files)
export PI_TELEMETRY=0
# pi: no startup network (version check, package checks, catalog refresh, fd/rg download)
export PI_OFFLINE=1
# pi: no version check even when PI_OFFLINE is removed for one command
export PI_SKIP_VERSION_CHECK=1
```

What each variable does:

- `PI_TELEMETRY=0` stops the install ping and the provider attribution headers. A project file cannot change it.
- `PI_OFFLINE=1` stops the version check, the package update check, and the model catalog refresh.
- `PI_OFFLINE=1` also stops the install of missing packages, the refresh of temporary git sources, and the download of `fd` and `rg`.
- `PI_SKIP_VERSION_CHECK=1` keeps the version check off when you run `env -u PI_OFFLINE pi ...` for an update.

The cost of `PI_OFFLINE=1`:

- The model list stays at the catalog in the installed package plus the cache in `models-store.json`. Run `pi update --models` to refresh it on request.
- `pi update` cannot find the latest release, and it skips package updates. Run `env -u PI_OFFLINE pi update` to update.
- A package in `packages` that is not installed does not load. Install it with `env -u PI_OFFLINE pi install <source>`.
- `fd` and `rg` must be on `PATH`. They are on this machine.

A process that does not read the shell profile does not get these variables. For that case, the settings keys below stop the ping and the headers, but not the other traffic.

### Settings

The dotfiles own this JSON object, for example as `llm-capabilities/adapters/pi/settings.json`:

```json
{
  "enableInstallTelemetry": false,
  "enableAnalytics": false,
  "defaultProjectTrust": "ask",
  "compaction": { "enabled": false },
  "retry": { "enabled": false }
}
```

What each key does:

- `enableInstallTelemetry: false` is the second barrier for the ping and the headers, for a process without `PI_TELEMETRY`.
- `enableAnalytics: false` keeps the analytics consent off. No code reads it in 0.85.1, but a later version can read it.
- `defaultProjectTrust: "ask"` is the default. The key makes the choice explicit. pi asks before it loads project settings, installs project packages, or runs project extensions. `"never"` is stricter: pi ignores those resources until you use `--approve` or `/trust`.
- `compaction.enabled: false` stops the automatic compaction and the retry after a context overflow. The Claude Code settings also have auto-compact off.
- `retry.enabled: false` stops the automatic retry after a transient provider error. A transient error then ends the turn. Remove this key if that behavior is a problem.

Do not put `lastChangelogVersion`, `theme`, `defaultProvider`, `defaultModel`, `packages`, or `enabledModels` in the managed object. pi writes these keys.

### Install without a loss of the keys that pi writes

Add a merge step to the install script, for example to `scripts/llm-capabilities.sh`:

```bash
PI_SETTINGS="$HOME/.pi/agent/settings.json"
PI_MANAGED="$DOTFILES/llm-capabilities/adapters/pi/settings.json"

mkdir -p "$(dirname "$PI_SETTINGS")"
if [[ -d "$PI_SETTINGS.lock" ]]; then
    echo "pi holds $PI_SETTINGS.lock. Stop pi, then run this script again." >&2
    exit 1
fi
if [[ -L "$PI_SETTINGS" ]]; then
    move_aside "$PI_SETTINGS"          # an old symlink into the repository
fi
if [[ -f "$PI_SETTINGS" ]]; then
    tmp="$(mktemp "$PI_SETTINGS.XXXXXX")"
    # Deep merge: objects merge key by key, the managed value wins, arrays replace.
    # jq stops with an error on invalid JSON, and set -e keeps the old file.
    jq --indent 2 -s '.[0] * .[1]' "$PI_SETTINGS" "$PI_MANAGED" > "$tmp"
    chmod 644 "$tmp"
    mv "$tmp" "$PI_SETTINGS"
else
    install -m 644 "$PI_MANAGED" "$PI_SETTINGS"
fi
```

Why this step is correct:

- The `jq` operator `*` merges objects key by key and replaces arrays. This is the same rule as the merge of pi. A scratchpad test merged the object above into a file with `lastChangelogVersion`, `theme`, and nested `compaction` and `retry` keys. The test kept each key that pi owns.
- The managed keys win at each run of the script. If you change one of them in `/settings`, the next run sets it back. This is the ownership that the dotfiles want.
- If the live file is not valid JSON, `jq` stops with an error, and the script keeps the old file.
- The lock directory exists only while pi reads or writes the file, or after a crash of pi. The script stops in that case.
- pi reads the file again before each write, and it writes only the keys that it changed. Thus a merge while pi runs keeps the managed keys. The exception is a managed key that you change in `/settings` in that session.
- `move_aside` is the backup function of `scripts/llm-capabilities.sh`. In another script, move the old symlink out of the way first.
- On a new machine, the script makes the file before the first start of pi. The file prevents the experimental first-time setup. The first interactive start then writes `lastChangelogVersion`, and the knobs stop the ping.

## Differences between the docs and the source

- The `/settings` item for install telemetry says that it controls the ping only. The source also uses it for the attribution headers. `PI/docs/settings.md:84` agrees with the source.
- The docs describe `PI_OFFLINE` as a switch for "startup network operations" (`PI/docs/environment-variables.md:84`). The source also uses it for the catalog refresh of `/model` during a session. It uses it for the download of `fd` and `rg` by the tools, and for the install of missing packages.
- The docs say that `PI_OFFLINE` takes `1`, `true`, or `yes` (`PI/dist/cli/args.js:424`). Some checks accept any value that is not empty (section 3).
- The docs say that `PI_TELEMETRY` takes `0`, `false`, or `no` for off (`PI/docs/environment-variables.md:86`). The source treats each value other than `1`, `true`, or `yes` as off (`PI/dist/core/telemetry.js:1-8`).
- The first-time setup names a `/privacy` command. pi 0.85.1 has no such command (`PI/dist/core/slash-commands.js:2-26`).

## Gaps

- This research did not observe the network at runtime. The findings come from the source only.
- This research cannot see what `pi.dev` stores from the ping, the version check, or the catalog requests.
- The citations use the files in `PI/dist`. The `pi` command runs the bundle. This research compared key strings only, not the full bundle.
- This research did not read all provider request code in `PI-AI`. Other providers can send more identifiers than the three in section 6, for example session affinity headers.
- This research did not read the Radius provider beyond the share upload.
- The meaning of "auto-continue" in Claude Code comes from the brief, not from Claude Code sources. Section 7 gives the closest pi behavior.
- This research did not examine npm and git, which pi starts for package installs. These tools can send their own traffic.
- The fetch of `pi.dev/docs/latest/settings` matched the local docs. The page does not name a version.
