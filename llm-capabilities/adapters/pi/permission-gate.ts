/**
 * Pi project trust controls project extensions, not tool calls. This gate adds
 * user-level boundaries for risky host access and parent conversation disclosure.
 * It is an accident and privacy guard, not an operating-system sandbox.
 */

import { mkdir } from "node:fs/promises";
import { relative, resolve, sep } from "node:path";

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

export type SessionStartEvent = { type: "session_start" };
export type PermissionGateEvent = ToolCallEvent | BeforeAgentStartEvent | SessionStartEvent;
export type PermissionGateEventName = "session_start" | "before_agent_start" | "tool_call";
export type PermissionGateHandler = (
  event: PermissionGateEvent,
  ctx: ToolCallContext,
) => Promise<ToolCallDecision | void> | ToolCallDecision | void;

type Pi = {
  on(event: PermissionGateEventName, handler: PermissionGateHandler): void;
};

export type PermissionGateOpts = {
  makeTempDir(path: string): Promise<void>;
};

export const DEFAULT_PERMISSION_GATE_OPTS: PermissionGateOpts = {
  async makeTempDir(path) {
    await mkdir(path, { recursive: true });
  },
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

const PREVIEW_LIMIT = 500;
const PI_TEMP_DIR = "/tmp/pi";
const PI_TEMP_GUIDELINE =
  "Store temporary files that do not belong in the project under /tmp/pi/. Do not make another top-level directory under /tmp/.";

const preview = (text: string): string =>
  text.length <= PREVIEW_LIMIT ? text : `${text.slice(0, PREVIEW_LIMIT)}…`;

const inside = (cwd: string, path: string): boolean => {
  const pathFromCwd = relative(resolve(cwd), resolve(cwd, path));
  return pathFromCwd === "" || (pathFromCwd !== ".." && !pathFromCwd.startsWith(`..${sep}`));
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

export default function registerPermissionGate(
  pi: Pi,
  opts: PermissionGateOpts = DEFAULT_PERMISSION_GATE_OPTS,
) {
  pi.on("session_start", async () => {
    await opts.makeTempDir(PI_TEMP_DIR);
  });

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
      const matched = commandRules.find((rule) => rule.pattern.test(command));
      if (matched) return request(ctx, "Confirm host command", `${matched.reason}:\n\n${preview(command)}`);
    }

    if (event.toolName === "write" || event.toolName === "edit") {
      const path = typeof event.input?.path === "string" ? event.input.path : "";
      if (path && !inside(ctx.cwd, path) && !inside(PI_TEMP_DIR, path)) {
        return request(ctx, "Confirm external write", `Write outside the active project:\n\n${preview(path)}`);
      }
    }

    return undefined;
  });
}
