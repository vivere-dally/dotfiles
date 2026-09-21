import { describe, expect, test } from "bun:test";
import registerAskUser, {
  type AskUserContext,
  type AskUserTool,
} from "../adapters/pi/ask-user.ts";
import registerPermissionGate, {
  type ToolCallContext,
  type ToolCallDecision,
  type ToolCallEvent,
} from "../adapters/pi/permission-gate.ts";

const askTool = (): AskUserTool => {
  let registered: AskUserTool | undefined;
  registerAskUser({
    registerTool(tool) {
      registered = tool;
    },
  });
  if (!registered) throw new Error("ask_user was not registered");
  return registered;
};

const permissionHandler = (): ((event: ToolCallEvent, ctx: ToolCallContext) => Promise<ToolCallDecision>) => {
  let registered: ((event: ToolCallEvent, ctx: ToolCallContext) => Promise<ToolCallDecision>) | undefined;
  registerPermissionGate({
    on(_event, handler) {
      registered = handler;
    },
  });
  if (!registered) throw new Error("permission handler was not registered");
  return registered;
};

describe("Pi ask_user tool", () => {
  test("returns the selected option label", async () => {
    const ctx: AskUserContext = {
      hasUI: true,
      ui: {
        async select(_title, options) {
          return options[1];
        },
        async input() {
          return undefined;
        },
      },
    };
    const response = await askTool().execute(
      "call-1",
      {
        question: "Which scope?",
        options: [
          { label: "Current file", description: "Limit the edit" },
          { label: "Project", description: "Apply it throughout the project" },
        ],
      },
      undefined,
      undefined,
      ctx,
    );

    expect(response.details).toEqual({ question: "Which scope?", answer: "Project", custom: false });
  });

  test("collects a free-form answer", async () => {
    const ctx: AskUserContext = {
      hasUI: true,
      ui: {
        async select(_title, options) {
          return options.at(-1);
        },
        async input() {
          return "  Use the library default  ";
        },
      },
    };
    const response = await askTool().execute(
      "call-2",
      { question: "Which value?", options: [{ label: "Fast" }, { label: "Safe" }] },
      undefined,
      undefined,
      ctx,
    );

    expect(response.details.answer).toBe("Use the library default");
    expect(response.details.custom).toBe(true);
  });

  test("keeps the free-form choice distinct from an option label", async () => {
    const ctx: AskUserContext = {
      hasUI: true,
      ui: {
        async select(_title, options) {
          return options.at(-1);
        },
        async input() {
          return "A different answer";
        },
      },
    };
    const response = await askTool().execute(
      "call-3",
      { question: "What next?", options: [{ label: "Type something" }, { label: "Stop" }] },
      undefined,
      undefined,
      ctx,
    );

    expect(response.details).toEqual({
      question: "What next?",
      answer: "A different answer",
      custom: true,
    });
  });
});

describe("Pi permission gate", () => {
  test("leaves routine repository commands automatic", async () => {
    let promptCount = 0;
    const decision = await permissionHandler()(
      { toolName: "bash", input: { command: "git status --short" } },
      {
        cwd: "/workspace/project",
        hasUI: true,
        ui: {
          async confirm() {
            promptCount += 1;
            return false;
          },
        },
      },
    );

    expect(decision).toBeUndefined();
    expect(promptCount).toBe(0);
  });

  test("blocks a destructive command when the user rejects it", async () => {
    const decision = await permissionHandler()(
      { toolName: "bash", input: { command: "rm -rf build" } },
      {
        cwd: "/workspace/project",
        hasUI: true,
        ui: {
          async confirm() {
            return false;
          },
        },
      },
    );

    expect(decision).toEqual({ block: true, reason: "Blocked by user" });
  });

  test("asks before a write outside the active project", async () => {
    const prompts: string[] = [];
    const decision = await permissionHandler()(
      { toolName: "write", input: { path: "/tmp/report.md" } },
      {
        cwd: "/workspace/project",
        hasUI: true,
        ui: {
          async confirm(title, message) {
            prompts.push(`${title}\n${message}`);
            return true;
          },
        },
      },
    );

    expect(decision).toBeUndefined();
    expect(prompts[0]).toContain("Confirm external write");
  });
});
