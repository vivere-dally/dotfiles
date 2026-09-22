/**
 * CLIProxyAPI holds several upstream accounts behind one local endpoint, and it
 * re-serves every model on each of its protocol paths. This registers one pi
 * provider for each upstream, so that `/model` names the real origin of a model
 * and the wire format matches that origin instead of a translation of it.
 *
 * The catalog is the only source of truth. `GET /v1/models` names the owner of
 * each model, and the Codex-flavored variant of the same route carries the
 * context window, the token limit, and the reasoning levels. A model that no
 * connected account serves is absent from both. Thus the provider list is the
 * connected list, without the management key of the proxy — that key grants full
 * control of the proxy, which is far more authority than a model list is worth.
 *
 * Deliberately absent: prices, a catalog cache, and a priority service tier. The
 * proxy is local, so a failed connection returns at once and a cache saves
 * nothing. Prices would need a second network host and would still be a guess at
 * the markup of the proxy, so each cost stays zero.
 */

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const CONFIG_PATH = join(homedir(), ".pi", "agent", "cliproxy.json");
const DEFAULT_BASE_URL = "http://127.0.0.1:8317";
const REQUEST_TIMEOUT_MS = 3000;
/**
 * The proxy owns the catalog size, so bound the body instead of trusting it. The
 * Codex-flavored entries each embed a full system prompt, hence the wide limit.
 */
const MAX_CATALOG_BYTES = 16 * 1024 * 1024;

/** Pi defaults, applied to a model that the Codex-flavored catalog omits. */
const FALLBACK_CONTEXT_WINDOW = 128_000;
const FALLBACK_MAX_TOKENS = 16_384;

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh" | "max";

const THINKING_LEVELS: readonly ThinkingLevel[] = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
];

/** CLIProxyAPI spells "no thinking" as `none`. Pi spells the same level `off`. */
const proxyEffort = (level: ThinkingLevel): string => (level === "off" ? "none" : level);

type Surface = { api: string; path: string };

/**
 * The proxy serves every model on every path, so the protocol is a choice. Select
 * the native protocol of the upstream: the proxy then translates nothing, which
 * keeps the thinking fields and the cache counters intact.
 *
 * `path` is what pi does NOT append by itself, and each protocol differs. Pi
 * builds `/v1/messages` from the bare origin for Anthropic, but it expects the
 * version in the base URL for OpenAI and for Google. The built-in defaults show
 * this: `https://api.anthropic.com`, `https://api.openai.com/v1`, and
 * `https://generativelanguage.googleapis.com/v1beta`.
 */
const SURFACES: Record<string, Surface> = {
  anthropic: { api: "anthropic-messages", path: "" },
  openai: { api: "openai-responses", path: "/v1" },
  google: { api: "google-generative-ai", path: "/v1beta" },
  gemini: { api: "google-generative-ai", path: "/v1beta" },
};

const FALLBACK_SURFACE: Surface = { api: "openai-completions", path: "/v1" };

export type PiModel = {
  id: string;
  name: string;
  reasoning: boolean;
  thinkingLevelMap?: Record<string, string | null>;
  input: Array<"text" | "image">;
  contextWindow: number;
  maxTokens: number;
  cost: { input: number; output: number; cacheRead: number; cacheWrite: number };
};

export type RefreshModelsContext = {
  allowNetwork: boolean;
  signal: AbortSignal;
};

export type ProviderConfig = {
  name: string;
  baseUrl: string;
  api: string;
  apiKey: string;
  authHeader: true;
  models: PiModel[];
  refreshModels(ctx: RefreshModelsContext): Promise<PiModel[]>;
};

type Pi = {
  registerProvider(name: string, config: ProviderConfig): void;
};

type Connection = { baseUrl: string; apiKey: string };

/** One entry of `GET /v1/models`, which is the only route that names the owner. */
type OwnedEntry = { id?: string; owned_by?: string };

/** One entry of `GET /v1/models?client_version=pi`, which carries the metadata. */
type CodexEntry = {
  id?: string;
  slug?: string;
  display_name?: string;
  context_window?: number;
  max_context_window?: number;
  max_tokens?: number;
  input_modalities?: string[];
  supported_reasoning_levels?: Array<{ effort?: string } | string>;
  visibility?: string;
};

const readConfigFile = (): Partial<Connection> => {
  try {
    const parsed: unknown = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
    if (typeof parsed !== "object" || parsed === null) return {};
    // The file is outside the repository and a person edits it, thus each field
    // is checked rather than cast.
    const record = parsed as Record<string, unknown>;
    return {
      baseUrl: typeof record.baseUrl === "string" ? record.baseUrl : undefined,
      apiKey: typeof record.apiKey === "string" ? record.apiKey : undefined,
    };
  } catch {
    // A missing file means the proxy is not set up on this host, which is normal.
    return {};
  }
};

const resolveConnection = (): Connection | undefined => {
  const file = readConfigFile();
  const apiKey = process.env.CLIPROXY_API_KEY ?? file.apiKey ?? "";
  if (apiKey === "") return undefined;

  const raw = process.env.CLIPROXY_BASE_URL ?? file.baseUrl ?? DEFAULT_BASE_URL;
  const withScheme = /^https?:\/\//i.test(raw) ? raw : `http://${raw}`;
  try {
    // Only the origin matters. Each surface below appends its own path, so a
    // trailing `/v1` or `/backend-api` in the configured value is dropped here.
    return { baseUrl: new URL(withScheme).origin, apiKey };
  } catch {
    return undefined;
  }
};

const readBounded = async (response: Response, url: string): Promise<unknown> => {
  const body = response.body;
  if (body === null) throw new Error(`${url} returned no body`);

  const decoder = new TextDecoder();
  let text = "";
  let size = 0;
  // Node's web ReadableStream is async-iterable at run time, but the DOM lib type
  // does not declare it. Iterating is what bounds the body; `.text()` would not.
  for await (const chunk of body as unknown as AsyncIterable<Uint8Array>) {
    size += chunk.byteLength;
    if (size > MAX_CATALOG_BYTES) throw new Error(`${url} sent more than ${MAX_CATALOG_BYTES} bytes`);
    text += decoder.decode(chunk, { stream: true });
  }
  text += decoder.decode();
  return JSON.parse(text);
};

const fetchCatalog = async (url: string, connection: Connection, signal: AbortSignal): Promise<unknown[]> => {
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${connection.apiKey}`, Accept: "application/json" },
    signal,
  });
  if (!response.ok) throw new Error(`${url} answered ${response.status}`);

  const payload = await readBounded(response, url);
  if (Array.isArray(payload)) return payload;
  if (typeof payload === "object" && payload !== null) {
    const record = payload as Record<string, unknown>;
    // The proxy answers `{data: []}` on the OpenAI route and `{models: []}` on the
    // Codex route.
    for (const key of ["data", "models"]) {
      const value = record[key];
      if (Array.isArray(value)) return value;
    }
  }
  return [];
};

const thinkingLevelMap = (entry: CodexEntry): Record<string, string | null> | undefined => {
  const efforts = new Set(
    (entry.supported_reasoning_levels ?? [])
      .map((level) => (typeof level === "string" ? level : level.effort))
      .filter((effort): effort is string => typeof effort === "string" && effort !== ""),
  );
  if (efforts.size === 0) return undefined;

  const map: Record<string, string | null> = {};
  for (const level of THINKING_LEVELS) {
    const effort = proxyEffort(level);
    // A level the catalog omits becomes null, which hides it in `/model`. A model
    // that lists no `none` effort thus shows no way to turn thinking off, which
    // is the truth about that model.
    map[level] = efforts.has(effort) ? effort : null;
  }
  return map;
};

const toPiModel = (id: string, entry: CodexEntry | undefined): PiModel | undefined => {
  if (entry !== undefined && (entry.visibility ?? "").toLowerCase() === "hide") return undefined;

  const map = entry === undefined ? undefined : thinkingLevelMap(entry);
  const modalities = new Set(entry?.input_modalities ?? ["text"]);
  const input: Array<"text" | "image"> = ["text"];
  if (modalities.has("image")) input.push("image");

  return {
    id,
    name: entry?.display_name?.trim() || id,
    reasoning: map !== undefined,
    ...(map === undefined ? {} : { thinkingLevelMap: map }),
    input,
    contextWindow: entry?.context_window ?? entry?.max_context_window ?? FALLBACK_CONTEXT_WINDOW,
    maxTokens: entry?.max_tokens ?? FALLBACK_MAX_TOKENS,
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  };
};

/** Model lists by upstream owner, keyed as the provider ids that pi registers. */
const collect = async (connection: Connection, signal: AbortSignal): Promise<Map<string, PiModel[]>> => {
  const [owned, codex] = await Promise.all([
    fetchCatalog(`${connection.baseUrl}/v1/models`, connection, signal),
    // `client_version` selects the Codex-flavored answer. The proxy gates the
    // extended levels on a dotted version, and `pi` is not one, thus the gate
    // opens and the answer keeps `xhigh` and `max`.
    fetchCatalog(`${connection.baseUrl}/v1/models?client_version=pi`, connection, signal),
  ]);

  const metadata = new Map<string, CodexEntry>();
  for (const raw of codex) {
    const entry = raw as CodexEntry;
    const id = (entry.slug ?? entry.id ?? "").trim();
    if (id !== "") metadata.set(id, entry);
  }

  const byOwner = new Map<string, PiModel[]>();
  for (const raw of owned) {
    const entry = raw as OwnedEntry;
    const id = (entry.id ?? "").trim();
    const owner = (entry.owned_by ?? "").trim().toLowerCase();
    if (id === "" || owner === "") continue;

    const model = toPiModel(id, metadata.get(id));
    if (model === undefined) continue;

    const models = byOwner.get(owner);
    if (models === undefined) byOwner.set(owner, [model]);
    else models.push(model);
  }
  return byOwner;
};

export default async function registerCliProxy(pi: Pi) {
  const connection = resolveConnection();
  if (connection === undefined) return;

  let byOwner: Map<string, PiModel[]>;
  try {
    // Fetched here, not in refreshModels alone: PI_OFFLINE sets `allowNetwork` to
    // false on the refresh path, and the proxy is a local process that the
    // offline rule is not about. Pi awaits this factory, so `/model` and
    // `--list-models` both see the result.
    byOwner = await collect(connection, AbortSignal.timeout(REQUEST_TIMEOUT_MS));
  } catch (error) {
    // A configured proxy that does not answer is worth one line. Registering
    // nothing would look the same as no configuration at all.
    console.warn(`cliproxy: no models from ${connection.baseUrl}: ${(error as Error).message}`);
    return;
  }

  for (const [owner, models] of byOwner) {
    const surface = SURFACES[owner] ?? FALLBACK_SURFACE;
    pi.registerProvider(`cliproxy-${owner}`, {
      name: `CLIProxyAPI ${owner}`,
      baseUrl: `${connection.baseUrl}${surface.path}`,
      api: surface.api,
      apiKey: connection.apiKey,
      authHeader: true,
      models,
      async refreshModels(ctx) {
        if (!ctx.allowNetwork) return models;
        const refreshed = await collect(connection, ctx.signal);
        return refreshed.get(owner) ?? [];
      },
    });
  }
}
