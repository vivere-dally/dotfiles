# Research: Browser vision for the Pi coding agent

## The question

The user builds React apps and wants the Pi coding agent to catch visual bugs in the components that it wrote. Pi has no built-in way to see a web page. The agent reads local image files with its read tool. So a screenshot file on disk plugs into the model with no extra plumbing. This document evaluates the options and ranks them for this setup.

Primary sources: the Pi docs in the local install, the GitHub repositories of each candidate, and the npm pages. The local Pi install is `@earendil-works/pi-coding-agent` 0.86.1 ([package.json](https://www.npmjs.com/package/@earendil-works/pi-coding-agent), local install). Pi registers custom tools with `pi.registerTool()` in TypeScript extensions, and installs packages through the `packages` key in `settings.json` ([Pi extensions doc](https://github.com/earendil-works/pi), local `docs/extensions.md` and `docs/packages.md`). Pi intentionally ships no built-in MCP in this installed version ([Pi usage doc](https://github.com/earendil-works/pi), local `docs/usage.md`, "Design Principles").

## Trusted authors

The user asked to weight the ranking toward authors already in use. The map below is the basis for the ranking.

| Author | Already in use here | Browser-related packages in their catalog |
| --- | --- | --- |
| Nico Bailon (npm `nicopreme`, GitHub [nicobailon](https://github.com/nicobailon)) | pi-subagents, pi-web-access, pi-intercom | [surf-cli](https://github.com/nicobailon/surf-cli), [pi-annotate](https://github.com/nicobailon/pi-annotate), [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) |
| narumitw (GitHub [narumiruna](https://github.com/narumiruna/pi-extensions)) | pi-goal | [@narumitw/pi-chrome-devtools](https://github.com/narumiruna/pi-extensions) |
| Mario Zechner (Pi author, GitHub [badlogic](https://github.com/badlogic/pi-skills), [earendil-works](https://github.com/earendil-works/pi)) | Pi itself | no first-party browser package. [pi-skills](https://github.com/badlogic/pi-skills) ships a browser-tools skill |
| Platform vendors | not installed here, vendor-owned | Google: [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp). Microsoft: [playwright-mcp](https://github.com/microsoft/playwright-mcp), [playwright-cli](https://github.com/microsoft/playwright-cli) |

All other packages below come from authors outside this map. They stay listed, and the doc flags them as unvetted provenance.

## What was evaluated

### Zero install: the Chrome headless one-liner

- **What it gives the agent:** a PNG of a page on disk. The `--screenshot` flag saves `screenshot.png` in the current working directory. `--window-size` sets the viewport. `--timeout` bounds the wait. `--virtual-time-budget` fast-forwards time-dependent page code, which helps with React apps ([Chrome headless command-line reference](https://developer.chrome.com/docs/automation-and-testing/headless-cli)). Chrome runs headless with the `--headless` flag ([Chrome headless mode](https://developer.chrome.com/docs/automation-and-testing/headless)).
- **Transport into Pi:** none. The agent runs one `bash` command, then reads the PNG with its read tool. No extension, no MCP, no npm package.
- **Install cost:** zero on macOS with Chrome present. No processes stay alive.
- **Risks:** no clicks, no console, no network, no sign-in state. The agent must pick a wait budget for a single-page app. Full-page captures beyond the viewport are not possible. Author: Google (browser vendor). Trust: platform vendor, and the command uses the user's own Chrome.

### badlogic/pi-skills browser-tools skill

- **What it gives the agent:** small Node scripts that talk to Chrome over the Chrome DevTools Protocol on port 9222. Scripts start Chrome, navigate, evaluate JavaScript, screenshot (returns a temp file path), pick elements, and read cookies. The skill text tells the agent to parse the DOM first and to save screenshots for visual state ([browser-tools SKILL.md](https://github.com/badlogic/pi-skills)).
- **Transport into Pi:** a skill folder plus `bash`. A one-time `npm install` in the skill directory.
- **Install cost:** a git clone into `~/.pi/agent/skills/` and one `npm install`.
- **Risks:** `browser-start.js --profile` copies the user profile with cookies and logins, so page content can reach the model provider. The scripts are thin and readable. Author: Mario Zechner, the Pi author. Trust: trusted.

### @narumitw/pi-chrome-devtools

- **What it gives the agent:** native Pi tools. The set covers list pages, select a page, navigate, and evaluate JavaScript. `chrome_devtools_screenshot` always saves a PNG to disk, at a temp path or at a `savePath` in the project ([package README](https://github.com/narumiruna/pi-extensions), `packages/pi-chrome-devtools`). The tool result carries an inline image block when the model can take images. When it cannot, the README says to ask the agent to read the saved path. The extension attaches to a Chrome DevTools Protocol endpoint at `127.0.0.1:9222` or launches an isolated Chromium-family browser on first use.
- **Transport into Pi:** a Pi package. `pi install npm:@narumitw/pi-chrome-devtools`, or a `"packages"` entry in `settings.json`. Tool definitions stay small through a loader tool on models with native deferred tools, and through eager exposure otherwise.
- **Install cost:** one Pi package install. No Chrome extension, no native host, no MCP config.
- **Risks:** the README states that the design follows chrome-devtools-mcp, but that compatibility is not guaranteed. Single maintainer. On this 0.86.1 install the tools load eagerly, which costs some context. Author: narumiruna. Trust: trusted. The user already runs pi-goal from this author.

### surf-cli (nicobailon)

- **What it gives the agent:** a CLI that controls the real Chrome the user already runs, through a companion browser extension and a native host. Commands cover `surf go`, `surf read` (accessibility tree and visible text), `surf click`, `surf type`, `surf element.styles`, and `surf snap`. Screenshots auto-save to `/tmp` as `surf-surf-snap-*.png` files, with `--output`, `--fullpage`, and `--full` options. Actions auto-capture a screenshot after they run. Network capture is automatic, with export to HAR ([surf-cli README](https://github.com/nicobailon/surf-cli)).
- **Transport into Pi:** plain `bash`. The repository also ships a Pi extension (`pi-extension/surf.ts`) and a skill ([repository tree](https://github.com/nicobailon/surf-cli)).
- **Install cost:** `npm install -g surf-cli`, then load the unpacked extension in Chrome and run `surf install <extension-id>`. Setup needs manual steps in Chrome.
- **Risks:** it drives the real browser profile of the user, so page content with signed-in data can reach the model provider. Sessions isolate agents from each other. More moving parts than an isolated headless browser. Author: Nico Bailon. Trust: trusted.

### pi-annotate (nicobailon)

- **What it gives the agent:** human-in-the-loop visual feedback. The user clicks elements in Chrome, adds comments, and submits. The output holds selectors, box model, accessibility data, CSS styles, and screenshot file paths, plus before-and-after screenshots for recorded DevTools edits ([pi-annotate README](https://github.com/nicobailon/pi-annotate)).
- **Transport into Pi:** a Pi package with a `/annotate` command and a tool. Needs an unpacked Chrome extension and a native messaging host.
- **Install cost:** `pi install npm:pi-annotate` plus extension and native host setup.
- **Risks:** it does not help the agent find bugs on its own. A person must mark the page. Author: Nico Bailon. Trust: trusted.

### chrome-devtools-mcp (Google) with pi-mcp-adapter

- **What it gives the agent:** a Google-maintained MCP server that controls a live Chrome through Puppeteer. It takes screenshots, reads console messages with source-mapped stack traces, inspects network requests, and records performance traces. It supports Google Chrome and Chrome for Testing. It ships a `--slim` mode with only navigate, evaluate, and screenshot, and a `--headless` flag ([chrome-devtools-mcp README](https://github.com/ChromeDevTools/chrome-devtools-mcp), [slim tool reference](https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/slim-tool-reference.md)). Version 1.10.1, Apache-2.0 (clone of the repository, `package.json` and `LICENSE`).
- **Transport into Pi:** Pi has no built-in MCP at 0.86.1, so an adapter extension is necessary. The [pi-mcp-adapter README](https://github.com/nicobailon/pi-mcp-adapter) uses chrome-devtools-mcp as its quick-start example and shows the `chrome_devtools_take_screenshot` call with `format` and `fullPage` parameters. The adapter exposes one small proxy tool, starts servers only on use, and ships a Chrome DevTools preset in its setup flow. The adapter is MIT, by Nico Bailon, and active (npm shows a release one day before this search, and the default branch on GitHub is at 4.0.0). The adapter states that its `mcpScript` mode works on Pi before 0.99, so it targets this install.
- **Install cost:** `pi install npm:pi-mcp-adapter`, restart, then a server entry in `.mcp.json`. The server runs through `npx`, which downloads the package on first use.
- **Risks:** Google collects usage statistics by default, with a `--no-usage-statistics` opt-out. The adapter renders compact text for MCP results. Inline images depend on the Pi image display settings, so the model can miss the image. The file path in the result then matters. Two dependencies instead of one. Trust: Google is a platform vendor. The adapter author is trusted.

### microsoft/playwright-mcp

- **What it gives the agent:** browser automation through structured accessibility snapshots, not pixel input. The README states "Uses Playwright's accessibility tree, not pixel-based input" and "No vision models needed" ([playwright-mcp README](https://github.com/microsoft/playwright-mcp)). Screenshots exist, with `--caps vision` and image response modes. Console messages, network requests, persistent profiles per workspace, `--isolated` mode, `--headless`, and an extension mode for a real logged-in browser. Version 0.0.83, Apache-2.0 (clone, `package.json` and `LICENSE`).
- **Transport into Pi:** the same pi-mcp-adapter step as chrome-devtools-mcp.
- **Install cost:** one `npx` server entry. Browsers come from Playwright.
- **Risks:** the design puts page structure, not pixels, in context, and accessibility trees cost tokens. The Playwright team itself now points coding agents at its CLI instead ([playwright-mcp README](https://github.com/microsoft/playwright-mcp), "Playwright MCP vs Playwright CLI"). Trust: platform vendor.

### microsoft/playwright-cli (@playwright/cli)

- **What it gives the agent:** a CLI built for coding agents, "token-efficient: does not force page data into LLM". Commands cover open, goto, click, fill, snapshot, `screenshot --filename=f`, console, requests, cookies, storage state, and sessions with `-s=name`. Headless by default. An idle headless session stops after one hour ([playwright-cli README](https://github.com/microsoft/playwright-cli)). Apache-2.0 (clone, `LICENSE`).
- **Transport into Pi:** plain `bash`. `playwright-cli install --skills` writes skill files aimed at Claude Code and Copilot. Pi can use the CLI without those skills.
- **Install cost:** `npm install -g @playwright/cli@latest`.
- **Risks:** the skills are written for other agents, so Pi depends on a short skill or prompt note of its own. Browser binaries come with Playwright. Author: Microsoft. Trust: platform vendor.

### AgentDeskAI browser-tools-mcp

- **What it gives the agent:** console logs, network logs, screenshots, and Lighthouse audits from the real Chrome session, attached through a DevTools extension. `takeScreenshot` returns an image plus a file path. The setup depends on Node 22.19 or newer, and capture starts when DevTools is open. Version 2.0 is a security rewrite: loopback only, per-run token, credential redaction ([browser-tools-mcp README](https://github.com/AgentDeskAI/browser-tools-mcp)). MIT (clone, `LICENSE`).
- **Transport into Pi:** through pi-mcp-adapter, plus a manually loaded Chrome extension.
- **Install cost:** `npx` server plus an unpacked extension. The heaviest setup in this list.
- **Risks:** the README warns that version 1.2.x has a critical vulnerability and calls for an upgrade. A person must keep DevTools open. The README also records that Chrome 136 and later refuse remote debugging on the default profile, which shapes every real-profile tool here. Author: AgentDesk LLC. Trust: unvetted provenance for this user.

### Pi packages from unvetted authors

- [pi-chrome](https://github.com/tianrendong/pi-chrome) (MIT): Pi tools for the real Chrome profile: pages, clicks, typing, screenshots, console, and network, through a companion extension with `/chrome authorize` approval windows. Capability is close to surf-cli, but the author is outside the trust map.
- [pi-chrome-use](https://github.com/citrolabs/pi-chrome-use): a CDP execution extension for Pi. Not examined in depth.
- [pi-agent-browser-native](https://pi.dev/packages/pi-agent-browser-native) and [agent-browser](https://www.npmjs.com/package/agent-browser): a Pi browser package and a Vercel browser CLI for agents. Not examined in depth. Third-party write-ups name Vercel as the publisher of agent-browser. The npm page text available here does not confirm that.
- [browser-use](https://github.com/browser-use/browser-use) (MIT, by Gregor Zunic): a Python browser agent. Its README names Pi among agents that its CLI and skill support. It runs its own agent loop on top of the page, which is heavier than a screenshot-and-read loop. MCP wrappers around it are third-party.

Trust note: unvetted provenance means the user has not vetted these authors. The doc does not claim the packages are unsafe.

### Rejected: the Puppeteer MCP server

The reference Puppeteer server moved to the archived repository and gets no security fixes ([modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers)). A security advisory records SSRF and prompt injection problems in the archived servers ([advisory issue](https://github.com/modelcontextprotocol/servers/issues/3662)). chrome-devtools-mcp covers the same ground with Puppeteer under active maintenance.

### pi-web-access (checked, not a fit for screenshots)

The installed pi-web-access package gives web search, URL fetch, GitHub clone, PDF extraction, and video understanding ([npm page](https://www.npmjs.com/package/pi-web-access)). It does not list screenshot capture. It stays useful for documentation research, not for seeing the app.

## Comparison table

| Option | Author (trust) | Agent gets | Enters Pi as | Install cost | License |
| --- | --- | --- | --- | --- | --- |
| Chrome `--headless --screenshot` | Google (vendor) | PNG file, viewport only | bash + read tool | none | Chrome binary |
| pi-skills browser-tools | Mario Zechner (trusted) | CDP scripts, screenshot file path, element pick | skill + bash | clone + `npm install` | MIT |
| @narumitw/pi-chrome-devtools | narumiruna (trusted) | Pi tools: navigate, evaluate, PNG on disk | Pi package | `pi install` | MIT |
| surf-cli | Nico Bailon (trusted) | real Chrome: a11y tree, screenshots in `/tmp`, network, styles | bash (+ bundled Pi extension and skill) | global npm + extension + native host | MIT |
| pi-annotate | Nico Bailon (trusted) | human annotations: selectors, styles, screenshots | Pi package + extension + native host | `pi install` + manual steps | MIT |
| chrome-devtools-mcp + pi-mcp-adapter | Google (vendor) + Nico Bailon (trusted) | screenshots, console, network, performance traces | Pi package + MCP config | `pi install` + `.mcp.json` | Apache-2.0 / MIT |
| playwright-mcp | Microsoft (vendor) | a11y snapshots, screenshots, profiles | MCP config + adapter | `npx` entry | Apache-2.0 |
| @playwright/cli | Microsoft (vendor) | CLI: snapshot, screenshot to file, console, requests | bash (+ skills for other agents) | global npm | Apache-2.0 |
| browser-tools-mcp | AgentDesk (unvetted) | real session: console, network, screenshots, audits | MCP config + adapter + extension | `npx` + unpacked extension | MIT |
| pi-chrome | tianrendong (unvetted) | real profile: pages, screenshots, console, network | Pi package + extension | `pi install` + manual steps | MIT |
| browser-use | Gregor Zunic (unvetted) | full agent loop on the page, skill for Pi | skill + bash, Python runtime | `uv` tooling | MIT |

## Recommendation

### Ranking

1. **@narumitw/pi-chrome-devtools**. Trusted author, native Pi tools, screenshots always land on disk inside the project, isolated headless Chromium by default, no MCP layer, no Chrome extension. This is the primary choice.
2. **The Chrome headless one-liner, today, before any install**. It proves the screenshot-and-read loop in one command and costs nothing. Mario Zechner's published position favors simple CLI tools over MCP for exactly this shape of task ([pi-mcp-adapter README](https://github.com/nicobailon/pi-mcp-adapter), "Why This Exists").
3. **surf-cli** when the app depends on a signed-in real Chrome, or when the agent must see the browser the user sees. Trusted author, disk screenshots, network capture.
4. **pi-mcp-adapter + chrome-devtools-mcp** (`--slim --headless`, `--no-usage-statistics`) when the user wants the wider MCP ecosystem anyway. Trusted adapter author, Google-maintained server.
5. **@playwright/cli** as a Microsoft-maintained CLI fallback. Equal capability, but no author overlap with this setup, and the skills target other agents.
6. **browser-tools-mcp, pi-chrome, agent-browser, browser-use**: listed, flagged as unvetted provenance, and not ranked ahead of the trusted options at comparable capability.

A complement, not a rank: **pi-annotate** fits the case where the user, not the agent, spots the visual bug and wants to hand the agent precise evidence.

### Integration sketch for the winner

One-time install:

```bash
pi install npm:@narumitw/pi-chrome-devtools
```

Then add `npm:@narumitw/pi-chrome-devtools` to the `"packages"` array in `~/.pi/agent/settings.json` if the install did not do it, and restart Pi. The permission-gate extension needs no change. The browser tools are extension tools, not `bash` commands, so the auto-deny rules for host commands do not touch them. The isolated Chromium process binds to localhost only.

The agent loop for a visual bug, as one prompt pattern:

```text
Start the dev server. Load the browser tools with chrome_devtools_load.
Navigate to http://localhost:5173.
Take a full-page screenshot with chrome_devtools_screenshot
and savePath tmp/pi/home.png. Read tmp/pi/home.png.
Compare the rendered page with src/components/*.tsx and report visual bugs.
```

Properties of the loop, each from the package README:

- The screenshot always becomes a PNG file, so the read tool can open it on every model.
- `savePath` inside the working directory keeps the artifact with the project. A `tmp/pi/` path keeps it out of git.
- `fullPage: true` captures the whole scroll, which catches layout and overflow bugs that a viewport crop hides.
- The agent can navigate, evaluate JavaScript, and screenshot again after each edit, so it can confirm its own fix.

Day-zero fallback, before any install:

```bash
cd tmp/pi
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless \
  --screenshot --window-size=1280,2000 --timeout=8000 \
  --virtual-time-budget=5000 http://localhost:5173
```

Chrome then writes `screenshot.png` in `tmp/pi`, and the agent reads it. The flags come from the [Chrome headless command-line reference](https://developer.chrome.com/docs/automation-and-testing/headless-cli).

## Notes on conflicts

- The local Pi docs state that Pi does not include built-in MCP, and the installed version is 0.86.1. The pi-mcp-adapter README states that Pi 0.99 added MCP support of its own. Both statements hold at their own versions. Consequence for this setup: the installed Pi depends on the adapter for MCP, and an update to Pi 0.99 or later changes that.
- The npm search snapshot showed pi-mcp-adapter at 3.0.0 while the default branch on GitHub carries 4.0.0. This is publication lag between the two sources, not a conflict about the package itself.

## Gaps in the evidence

- pi-mcp-adapter states no minimum Pi version in the files read here. The README says `mcpScript` works on Pi before 0.99, but the full minimum is not published in that text.
- The chrome-devtools-mcp screenshot result shape, inline image versus file path, is not confirmed from its tool reference. The adapter example proves the tool exists with `format` and `fullPage`, not where the bytes land.
- Whether the deferred-tool loader of @narumitw/pi-chrome-devtools activates on Pi 0.86.1 is not tested here. The README documents an eager fallback, so the tools work either way, with more context cost.
- The exact npm versions of pi-chrome, pi-agent-browser-native, and agent-browser, and the publisher of agent-browser on npm, are not confirmed from the npm pages themselves.
- The task list mentioned a candidate named "pivot". No browser MCP server of that name turned up in any search. The doc treats it as a note for "Puppeteer", which is covered in the rejected section.

## Sources

Kept:

- [Pi repository and docs](https://github.com/earendil-works/pi) — extension API, packages, and the no-built-in-MCP design, from the source that owns Pi. Local install cross-checked at version 0.86.1.
- [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) — the MCP bridge option, its Pi 0.99 comparison, and the chrome-devtools example. Local clone read for `package.json` and `LICENSE`.
- [@narumitw/pi-chrome-devtools README](https://github.com/narumiruna/pi-extensions) — the recommended package, with its screenshot-to-disk contract. Local clone read.
- [surf-cli](https://github.com/nicobailon/surf-cli) — the real-Chrome CLI from a trusted author, with screenshot auto-save details.
- [pi-annotate](https://github.com/nicobailon/pi-annotate) — the human-annotation complement.
- [badlogic/pi-skills](https://github.com/badlogic/pi-skills) — the Pi author's own browser-tools skill. Local clone read of `SKILL.md`.
- [chrome-devtools-mcp](https://github.com/ChromeDevTools/chrome-devtools-mcp) — the Google server. Local clone read of `README.md`, slim tool reference, `package.json`, `LICENSE`.
- [playwright-mcp](https://github.com/microsoft/playwright-mcp) — the Microsoft server and its own CLI-over-MCP guidance. Local clone read.
- [playwright-cli](https://github.com/microsoft/playwright-cli) — the Microsoft coding-agent CLI. Local clone read.
- [browser-tools-mcp](https://github.com/AgentDeskAI/browser-tools-mcp) — the real-session MCP server and the Chrome 136 remote-debugging note. Local clone read.
- [Chrome headless command-line reference](https://developer.chrome.com/docs/automation-and-testing/headless-cli) and [Chrome headless mode](https://developer.chrome.com/docs/automation-and-testing/headless) — the zero-install command, from Google's own docs.
- [pi-web-access](https://www.npmjs.com/package/pi-web-access) — capability boundary of the installed web package.
- [modelcontextprotocol/servers](https://github.com/modelcontextprotocol/servers) and its [security advisory](https://github.com/modelcontextprotocol/servers/issues/3662) — the Puppeteer server archive status.
- [browser-use](https://github.com/browser-use/browser-use) — the agent-loop alternative and its Pi skill path. Local clone read of `LICENSE`.

Deprioritized:

- Third-party blog posts about pi setup, Chrome DevTools MCP, and agent-browser. Useful for discovery. Each claim here comes from the repository or npm page that owns it.
- [pi-chrome-use](https://github.com/citrolabs/pi-chrome-use), [pi-agent-browser-native](https://pi.dev/packages/pi-agent-browser-native), [agent-browser](https://www.npmjs.com/package/agent-browser) — real candidates, left unexamined in depth because the trusted options cover this use.
