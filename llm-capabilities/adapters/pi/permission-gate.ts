/**
 * Pi project trust controls project extensions, not tool calls. This gate adds
 * user-level boundaries for risky host access and parent conversation disclosure.
 * It is an accident and privacy guard, not an operating-system sandbox.
 */

import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

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

/**
 * `pattern` is a cheap test on the raw text, so that most commands skip the parser.
 * It is loose on purpose, because it also meets quoted text such as a grep pattern
 * that holds `rm -f`. Only `matches`, which reads the parsed words of one simple
 * command, decides.
 */
type CommandRule = {
  pattern: RegExp;
  reason: string;
  matches: (name: string, args: string[], sh: Shell) => boolean;
};

type Shell = typeof import("../../ste/shell.ts");

const hasShortFlag = (args: string[], letters: RegExp) => args.some((a) => /^-[^-]/.test(a) && letters.test(a.slice(1)));

const git = (sub: string, test: (args: string[]) => boolean) => (name: string, args: string[], sh: Shell) => {
  if (name !== "git") return false;
  const [actual, rest] = sh.gitSubcommand(args);
  return actual === sub && test(rest);
};

const commandRules: CommandRule[] = [
  {
    pattern: /\brm\b/,
    reason: "recursive file removal",
    matches: (name, args) => name === "rm" && (args.includes("--recursive") || hasShortFlag(args, /[rR]/)),
  },
  {
    pattern: /\bsudo\b/,
    reason: "elevated command",
    matches: (name) => name === "sudo",
  },
  {
    pattern: /\b(?:chmod|chown)\b/,
    reason: "broad permission change",
    matches: (name, args) =>
      (name === "chmod" || name === "chown") &&
      (args.includes("777") || args.includes("--recursive") || hasShortFlag(args, /R/)),
  },
  {
    pattern: /\bgit\b[\s\S]*\breset\b/,
    reason: "destructive Git reset",
    matches: git("reset", (args) => args.includes("--hard")),
  },
  {
    pattern: /\bgit\b[\s\S]*\bclean\b/,
    reason: "untracked-file removal",
    matches: git("clean", (args) => args.includes("--force") || hasShortFlag(args, /f/)),
  },
  {
    pattern: /\bgit\b[\s\S]*\b(?:checkout|restore)\b/,
    reason: "working-tree restoration",
    matches: (name, args, sh) =>
      git("checkout", (rest) => rest.includes("--"))(name, args, sh) || git("restore", () => true)(name, args, sh),
  },
  {
    pattern: /\bgit\b[\s\S]*\bpush\b/,
    reason: "forced Git push",
    matches: git("push", (args) => args.some((a) => a.startsWith("--force")) || hasShortFlag(args, /f/)),
  },
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
// finds ste/shell.ts, whatever way jiti resolves a relative import from a symlink.
const shellPath = join(dirname(realpathSync(fileURLToPath(import.meta.url))), "..", "..", "ste", "shell.ts");
let shellModule: Promise<typeof import("../../ste/shell.ts")> | undefined;
const loadShell = () => (shellModule ??= import(pathToFileURL(shellPath).href));

/** The words of each simple command, or `undefined` when the parser cannot read the script. */
const parseCommands = async (command: string) => (await loadShell()).parseCommands(command);

/** The reason of the first risky rule that a real command meets, not quoted text. */
const riskyCommandReason = async (command: string): Promise<string | undefined> => {
  const candidates = commandRules.filter((rule) => rule.pattern.test(command));
  if (candidates.length === 0) return undefined;
  const commands = await parseCommands(command);
  // A script that the gate cannot read fails closed, with the reason of the text match.
  if (!commands) return candidates[0].reason;
  const sh = await loadShell();
  for (const words of commands) {
    const [name, ...args] = sh.unwrap(words);
    const rule = name ? candidates.find((r) => r.matches(name, args, sh)) : undefined;
    if (rule) return rule.reason;
  }
  return undefined;
};

type ShellFinding = { kind: "external"; path: string } | { kind: "unparsed" };

const externalMutationPath = async (cwd: string, command: string): Promise<ShellFinding | undefined> => {
  if (!filesystemMutation.test(command)) return undefined;

  // This is an accident guard for common shell file commands. The shell can hide
  // a path behind arbitrary code, so operating-system isolation remains the security boundary.
  const commands = await parseCommands(command);
  if (!commands) return { kind: "unparsed" };
  const { unwrap } = await loadShell();
  let externalPath: string | undefined;
  for (const words of commands) {
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
      const reason = await riskyCommandReason(command);
      if (reason) return request(ctx, "Confirm host command", `${reason}:\n\n${preview(command)}`);
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
