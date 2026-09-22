# Pi with CLIProxyAPI

- Research date: 2026-09-21.
- Installed Pi version: `0.86.1`.
- Sources: the Pi documentation and source, the CLIProxyAPI source, and the `pi-cliproxyapi-provider` source.
- The brief for this research is `docs/research/cliproxy-pi.md`.

## The answer

A Pi extension can do the full job. Pi lets an extension register a provider and
its models at run time. Thus no person must maintain a model list by hand.

A package for this already exists. `@router-for-me/pi-cliproxyapi-provider`
registers CLIProxyAPI as one Pi provider and reads its model catalog over HTTP.
[package manifest](https://github.com/router-for-me/pi-cliproxyapi-provider/blob/main/package.json)

But the package gives one provider only, and it sends each request to the Codex
path. It does not select between the upstream providers of the proxy, and it
does not read which accounts are connected. New code is necessary for these two items.

## What Pi gives an extension

Pi has a static provider file and a dynamic extension API. The static file is
`~/.pi/agent/models.json`. An explicit `models` array is necessary, so it cannot
discover a catalog. Pi documents no auto-discovery for that file.
[Pi models](https://pi.dev/docs/latest/models)

The extension API is the correct mechanism. An extension is a TypeScript file
with a default export. Pi loads it from `~/.pi/agent/extensions/`, from
`.pi/extensions/`, or from an installed package.
[Pi extensions](https://pi.dev/docs/latest/extensions)

- `pi.registerProvider(name, config)` adds a provider. `pi.unregisterProvider(name)` removes it and restores an overridden built-in.
- The factory can be `async`. Pi awaits it before startup continues, thus a fetch in the factory gives models to `/model` and to `pi --list-models`.
- `config.refreshModels(context)` returns a model array. Pi calls it on a model refresh and on `pi update --models`. The context gives `allowNetwork`, an abort signal, a stored snapshot, and a `publish` function.
- Pi persists a catalog snapshot in `~/.pi/agent/models-store.json` for offline use. [Pi providers](https://pi.dev/docs/latest/providers)

`config.api` selects the wire protocol. The values include
`openai-completions`, `openai-responses`, `anthropic-messages`, and
`google-generative-ai`.
[Pi custom provider](https://pi.dev/docs/latest/custom-provider)

A model entry carries `id`, `name`, `reasoning`, `input`, `contextWindow`,
`maxTokens`, `cost`, and `thinkingLevelMap`. `thinkingLevelMap` maps the Pi
levels `off`, `minimal`, `low`, `medium`, `high`, `xhigh`, and `max` to the
string that the provider expects. A `null` value hides the level. This is the
field that gives the effort selection that the brief asks for.

`apiKey` and each header value accept `"$ENV_VAR"` for an environment variable
and `"!command"` for the standard output of a shell command. `authHeader: true`
adds `Authorization: Bearer <key>`. An `oauth` block gives a `/login` flow.

Caution: do not start a background resource in the factory. Pi runs the factory
in invocations that never open a session. Use the `session_start` event and
clean up in `session_shutdown`.

## What CLIProxyAPI exposes

The client API and the management API are separate, and they use different keys.
[server routes](https://github.com/router-for-me/CLIProxyAPI/blob/main/internal/api/server_routes.go)

Client API, behind the client API key:

- `GET /v1/models` and `POST /v1/chat/completions` and `POST /v1/responses` give the OpenAI shape.
- `POST /v1/messages` and `POST /v1/messages/count_tokens` give the Anthropic shape. There is no separate Anthropic prefix.
- `GET /v1beta/models` and `POST /v1beta/models/*action` give the Gemini shape.
- `POST /backend-api/codex/responses` gives the Codex shape.

`GET /v1/models` routes to the Claude handler when the request carries an
`Anthropic-Version` header or a `claude-cli` user agent. For the Anthropic catalog,
an extension must set that header.

The client API reports models only. It has no endpoint that lists the connected
upstream accounts.

Management API, behind the management key:

- The prefix is `/v0/management`. The key goes in `Authorization: Bearer <key>` or in `X-Management-Key`. [management API](https://help.router-for.me/management/api)
- `GET /v0/management/auth-files` lists each credential with `provider`, `label`, `status`, `disabled`, `unavailable`, `next_retry_after`, `quota`, and `account`. The proxy reconciles this state live, thus an expired token shows as unavailable.
- `GET /v0/management/auth-files/models?name=<id>` lists the models that one credential serves.
- For a remote caller, `remote-management.allow-remote: true` or the `MANAGEMENT_PASSWORD` environment variable is also necessary. Five failed attempts ban the address for 30 minutes.

CLIProxyAPI accepts a reasoning effort in two forms. It reads `reasoning.effort`
in the request body, and it reads a suffix on the model name, for example
`gpt-5.2(high)` or `claude-sonnet-4-5(16384)`. The levels are `none`, `auto`,
`minimal`, `low`, `medium`, `high`, `xhigh`, and `max`. A numeric value is a
token budget, `0` is off, and `-1` is auto.

Each catalog entry carries `supported_reasoning_levels[].effort` and
`default_reasoning_level`. Thus a client can build `thinkingLevelMap` from the
catalog without a hard-coded table.

## The existing package

`@router-for-me/pi-cliproxyapi-provider` is active, not a stub. Its last release
is version `1.4.18` on 2026-09-20. It has tests, Biome, and `tsc --noEmit`.

What it does:

- It registers one provider with the id `cliproxyapi` and the custom API id `cliproxyapi-codex-responses`. It sends inference to `{origin}/backend-api/codex/responses`.
- It fetches `{origin}/v1/models?client_version=pi` with `Authorization: Bearer <key>`, and it accepts a bare array, `{models: []}`, or `{data: []}`.
- It maps `slug` to `id`, `display_name` to `name`, `context_window` to `contextWindow`, and `supported_reasoning_levels[].effort` to `thinkingLevelMap`. It skips a model with `visibility: "hide"`.
- It caches the catalog in `~/.pi/agent/cliproxyapi-models.json` and keeps a missing model as stale for 7 days.
- It reads prices from `https://models.dev/api.json` and caches them for 24 hours.
- It adds the commands `/fast`, `/pause`, `/continue`, and `/cliproxyapi-refresh`.
- It declares itself as an OAuth provider, because the Pi `/login` multi-field prompt is on the account path only.

Known limits, from its README and its source:

- `/logout` clears `auth.json` only. A person must delete `cliproxyapi.json` by hand.
- The price data is best-effort. An ambiguous price becomes zero.
- Token streaming does not resume at the point of an interruption.
- It patches the installed `@earendil-works/pi-ai` build at run time with a string substitution on `extractAccountId`. This is deliberate, but it depends on the text of the upstream source.
- It calls no management endpoint, thus it cannot show the connected accounts.

## What a probe of a live proxy shows

These facts come from a local proxy at `http://127.0.0.1:8317`, not from the
documentation. They decide the design.

- `GET /v1/models` gives the OpenAI shape, and each entry carries `owned_by`, for example `anthropic`. This is the only route that names the upstream of a model.
- `GET /v1/models?client_version=pi` gives the Codex shape. Each entry carries `slug`, `display_name`, `context_window`, `max_tokens`, `input_modalities`, `supported_reasoning_levels`, `default_reasoning_level`, and `visibility`. It does not carry `owned_by`.
- The proxy translates each model onto each path. A model of an Anthropic account also appears on `/v1beta/models` in the Gemini shape. Thus the path is a choice, not a limit.
- `Authorization: Bearer <key>` and `x-api-key: <key>` both pass the client middleware. A wrong key gives HTTP 401 with `Invalid API key`. Thus `authHeader: true` is enough for each path.
- The management key is separate. `GET /v0/management/auth-files` with the client key gives HTTP 401 and `invalid management key`.
- A catalog holds the models of the connected accounts only. Thus `owned_by` is a connected-provider list, and the management key is unnecessary.
- But a catalog entry is not a promise. `claude-3-5-haiku-20241022` is in the catalog, and a request for it gives HTTP 404 with `not_found_error` from the upstream. Only a request finds such an entry, thus the extension keeps it.

## The solution in this repository

`llm-capabilities/adapters/pi/cliproxy-provider.ts` holds the extension, and
`scripts/llm-capabilities.sh:138` links it into `~/.pi/agent/extensions/`.

It reads both catalogs at the same time and joins them on the model id. It then
groups the models by `owned_by`, and it registers one Pi provider for each group.
The protocol of a group matches the upstream, so that the proxy translates
nothing:

| `owned_by` | Provider id | `api` | Base URL |
| --- | --- | --- | --- |
| `anthropic` | `cliproxy-anthropic` | `anthropic-messages` | `{origin}` |
| `openai` | `cliproxy-openai` | `openai-responses` | `{origin}/v1` |
| `google` or `gemini` | `cliproxy-google` | `google-generative-ai` | `{origin}/v1beta` |
| any other | `cliproxy-<owner>` | `openai-completions` | `{origin}/v1` |

The base URL is what Pi does not build by itself, and each protocol differs. Pi
appends `/v1/messages` to a bare origin for Anthropic, but it reads the version
from the base URL for OpenAI and for Google. The built-in defaults show the
difference: `https://api.anthropic.com`, `https://api.openai.com/v1`, and
`https://generativelanguage.googleapis.com/v1beta`. A `/v1` on the Anthropic row
gives HTTP 404 with no body.

A live account confirms the Anthropic row only. The other rows use the same
built-in defaults, but no account of those upstreams was connected.

`supported_reasoning_levels` becomes `thinkingLevelMap`. An absent level becomes
`null`, thus `/model` hides it. Pi calls `off` what the proxy calls `none`.

The connection comes from `CLIPROXY_BASE_URL` and `CLIPROXY_API_KEY`, or from
`~/.pi/agent/cliproxy.json`. `scripts/llm-capabilities.sh:187-201` writes that
file from the same two variables, with mode 600. The key is a secret, thus this
repository never holds it. Without a key, the extension registers nothing.

The extension reads the catalog in its `async` factory, not in `refreshModels`
alone. `PI_OFFLINE=1` is always set (`.zshrc:137`), and it sets `allowNetwork` to
false on the refresh path. The proxy is a local process, and the offline rule is
about the network of Pi itself.

## What this drops on purpose

- Prices. A price needs a second network host, and it stays a guess at the markup of the proxy. Each cost is zero.
- A catalog cache. The proxy is local, thus a refused connection returns at once and a cache saves nothing.
- The Fast service tier. It raises the bill, and a person can add it later.
- The management API. See the probe above.

## The call

Do not install `@router-for-me/pi-cliproxyapi-provider`. It solves a different
problem well, but its cost is high for this one:

- It sends each request to the Codex path, thus it cannot select an upstream. This is the opposite of what the brief asks for.
- It patches the installed `@earendil-works/pi-ai` build at run time.
- It reaches a second host for prices, and it adds a service tier that raises the bill.
- It adds a footer, a pause command, and a WebSocket lifecycle that this setup does not use.
