/**
 * Pi project trust controls project extensions, not tool calls. This gate adds
 * user-level boundaries for risky host access and parent conversation disclosure.
 * It is an accident and privacy guard, not an operating-system sandbox.
 */

import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import type { Node, Parser } from "web-tree-sitter";

export type ToolCallEvent = {
  toolName: string;
  input?: Record<string, unknown>;
};

export type ToolCallContext = {
  cwd: string;
  hasUI: boolean;
  ui: {
    confirm(title: string, message: string): Promise<boolean>;
  };
};

export type ToolCallDecision = { block: true; reason: string } | undefined;

export type BeforeAgentStartEvent = {
  systemPromptOptions: {
    promptGuidelines: string[];
  };
};

export type PermissionGateEvent = ToolCallEvent | BeforeAgentStartEvent;
export type PermissionGateEventName = "before_agent_start" | "tool_call";
export type PermissionGateHandler = (
  event: PermissionGateEvent,
  ctx: ToolCallContext,
) => Promise<ToolCallDecision | void> | ToolCallDecision | void;

type Pi = {
  on(event: PermissionGateEventName, handler: PermissionGateHandler): void;
};

type CommandRule = {
  pattern: RegExp;
  reason: string;
};

const commandRules: CommandRule[] = [
  { pattern: /\brm\s+(?:-[^\s]*[rR][^\s]*\s+|--recursive\b)/, reason: "recursive file removal" },
  { pattern: /(?:^|[;&|\n]\s*)sudo(?:\s|$)/, reason: "elevated command" },
  { pattern: /\b(?:chmod|chown)\b[^\n]*(?:777|--recursive|-R)\b/, reason: "broad permission change" },
  { pattern: /\bgit\s+reset\s+--hard\b/, reason: "destructive Git reset" },
  { pattern: /\bgit\s+clean\b[^\n]*\s-[^\s]*f/, reason: "untracked-file removal" },
  { pattern: /\bgit\s+(?:checkout\s+--|restore\b)/, reason: "working-tree restoration" },
  { pattern: /\bgit\s+push\b[^\n]*(?:--force(?:-with-lease)?|-f)\b/, reason: "forced Git push" },
];

const filesystemMutation =
  /(?:^|[;&|\n]\s*)(?:command\s+|env(?:\s+-[^\s]+|\s+[A-Za-z_][A-Za-z0-9_]*=[^\s]+)*\s+)?(?:chmod|chown|cp|dd|install|ln|mkdir|mktemp|mv|rm|tee|touch|truncate)\b/;
const mutationCommands = new Set(["chmod", "chown", "cp", "dd", "install", "ln", "mkdir", "mktemp", "mv", "rm", "tee", "touch", "truncate"]);
const pathPrefix = /^(?:\/|~\/|\$HOME\/|\$\{HOME\}\/|\.\.?\/)/;

const PREVIEW_LIMIT = 500;
// The directory is inside the project, thus the write checks below let it without a
// prompt. The agent makes it on the first write. A session start does not make it,
// because that puts a `tmp/` directory into each project that Pi opens.
const PI_TEMP_GUIDELINE =
  "Store temporary files under tmp/pi/ at the root of the active project, not under /tmp.";

const preview = (text: string): string =>
  text.length <= PREVIEW_LIMIT ? text : `${text.slice(0, PREVIEW_LIMIT)}…`;

const inside = (cwd: string, path: string): boolean => {
  const pathFromCwd = relative(resolve(cwd), resolve(cwd, path));
  return pathFromCwd === "" || (pathFromCwd !== ".." && !pathFromCwd.startsWith(`..${sep}`));
};

const expandHome = (path: string): string => {
  if (path.startsWith("~/")) return resolve(homedir(), path.slice(2));
  if (path.startsWith("$HOME/")) return resolve(homedir(), path.slice(6));
  if (path.startsWith("${HOME}/")) return resolve(homedir(), path.slice(8));
  return path;
};

// pi loads this file through a symlink in its extensions directory. The real path
// finds the node_modules of llm-capabilities, whatever way jiti resolves a bare import.
const nodeModules = join(dirname(realpathSync(fileURLToPath(import.meta.url))), "..", "..", "node_modules");
let bashParser: Promise<Parser> | undefined;
const loadBashParser = (): Promise<Parser> =>
  (bashParser ??= (async () => {
    const treeSitter: typeof import("web-tree-sitter") = await import(
      pathToFileURL(join(nodeModules, "web-tree-sitter", "web-tree-sitter.js")).href
    );
    await treeSitter.Parser.init({ locateFile: () => join(nodeModules, "web-tree-sitter", "web-tree-sitter.wasm") });
    const parser = new treeSitter.Parser();
    parser.setLanguage(await treeSitter.Language.load(join(nodeModules, "tree-sitter-bash", "tree-sitter-bash.wasm")));
    return parser;
  })());

/** The literal text of one shell word, without its quotes. */
const wordText = (node: Node): string => {
  if (node.type === "raw_string") return node.text.slice(1, -1);
  if (node.type === "string") return node.text.slice(1, -1);
  return node.text.replace(/['"]/g, "");
};

/**
 * The words of each simple command in the script, commands inside `<(...)` and
 * `$(...)` included. Only the words of a file-changing command are checked for
 * paths, thus a sed script or a grep pattern elsewhere in the line is never read
 * as a path.
 */
const simpleCommands = (root: Node): string[][] => {
  const commands: string[][] = [];
  const walk = (node: Node) => {
    if (node.type === "command") {
      const name = node.childForFieldName("name");
      if (name) commands.push([wordText(name), ...node.childrenForFieldName("argument").map(wordText)]);
    }
    for (const child of node.namedChildren) if (child) walk(child);
  };
  walk(root);
  return commands;
};

/** `env VAR=value` and `command` only start the real command. */
const unwrap = (words: string[]): string[] => {
  let rest = words;
  for (;;) {
    if (rest[0] === "command") rest = rest.slice(1);
    else if (rest[0] === "env") {
      rest = rest.slice(1);
      while (rest[0] && (/^[A-Za-z_][A-Za-z0-9_]*=/.test(rest[0]) || rest[0].startsWith("-"))) rest = rest.slice(1);
    } else return rest;
  }
};

type ShellFinding = { kind: "external"; path: string } | { kind: "unparsed" };

const externalMutationPath = async (cwd: string, command: string): Promise<ShellFinding | undefined> => {
  if (!filesystemMutation.test(command)) return undefined;

  // This is an accident guard for common shell file commands. The shell can hide
  // a path behind arbitrary code, so operating-system isolation remains the security boundary.
  const tree = (await loadBashParser()).parse(command);
  if (!tree || tree.rootNode.hasError) return { kind: "unparsed" };
  let externalPath: string | undefined;
  for (const words of simpleCommands(tree.rootNode)) {
    const [name, ...args] = unwrap(words);
    if (!name || !mutationCommands.has(name)) continue;
    for (const arg of args) {
      // `dd of=/path` names its file after the equals sign.
      for (const candidate of [arg, arg.slice(arg.indexOf("=") + 1)]) {
        if (pathPrefix.test(candidate) && !inside(cwd, expandHome(candidate))) externalPath = candidate;
      }
    }
  }
  return externalPath === undefined ? undefined : { kind: "external", path: externalPath };
};

const inheritedContextInScript = /\b(?:context|defaultContext)\b["'`]?\s*:\s*(["'`])(?:fork|profile)\1/;

const requestsParentTranscript = (value: unknown, key?: string): boolean => {
  if (key === "workflowScript" && typeof value === "string") {
    return inheritedContextInScript.test(value);
  }
  if (Array.isArray(value)) return value.some((item) => requestsParentTranscript(item));
  if (typeof value !== "object" || value === null) return false;

  return Object.entries(value).some(([childKey, child]) => {
    if (
      (childKey === "context" || childKey === "defaultContext") &&
      (child === "fork" || child === "profile")
    ) {
      return true;
    }
    return requestsParentTranscript(child, childKey);
  });
};

const request = async (
  ctx: ToolCallContext,
  title: string,
  message: string,
): Promise<ToolCallDecision> => {
  if (!ctx.hasUI) return { block: true, reason: `${title} blocked because no confirmation UI is available` };
  return (await ctx.ui.confirm(title, message)) ? undefined : { block: true, reason: "Blocked by user" };
};

export default function registerPermissionGate(pi: Pi) {
  pi.on("before_agent_start", (event) => {
    if (!("systemPromptOptions" in event)) return;
    if (!event.systemPromptOptions.promptGuidelines.includes(PI_TEMP_GUIDELINE)) {
      event.systemPromptOptions.promptGuidelines.push(PI_TEMP_GUIDELINE);
    }
  });

  pi.on("tool_call", async (event, ctx) => {
    if (!("toolName" in event)) return;
    if (event.toolName === "subagent" && requestsParentTranscript(event.input)) {
      return {
        block: true,
        reason: "Forked subagent context is disabled; send the child an explicit task instead",
      };
    }

    if (event.toolName === "bash") {
      const command = typeof event.input?.command === "string" ? event.input.command : "";
      const finding = await externalMutationPath(ctx.cwd, command);
      if (finding?.kind === "external") {
        return request(
          ctx,
          "Confirm host command",
          `filesystem command references a path outside the active project (${finding.path}):\n\n${preview(command)}`,
        );
      }
      if (finding?.kind === "unparsed") {
        return request(ctx, "Confirm host command", `filesystem command that the gate cannot parse:\n\n${preview(command)}`);
      }
      const matched = commandRules.find((rule) => rule.pattern.test(command));
      if (matched) return request(ctx, "Confirm host command", `${matched.reason}:\n\n${preview(command)}`);
    }

    if (event.toolName === "write" || event.toolName === "edit") {
      const path = typeof event.input?.path === "string" ? event.input.path : "";
      if (path && !inside(ctx.cwd, path)) {
        return request(ctx, "Confirm external write", `Write outside the active project:\n\n${preview(path)}`);
      }
    }

    return undefined;
  });
}
