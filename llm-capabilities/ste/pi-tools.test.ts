import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import registerAskUser, {
  type AskUserContext,
  type AskUserTool,
} from "../adapters/pi/ask-user.ts";
import registerPermissionGate, {
  type PermissionGateEventName,
  type PermissionGateHandler,
  type ToolCallContext,
  type ToolCallDecision,
  type ToolCallEvent,
} from "../adapters/pi/permission-gate.ts";
import registerTmuxStatus from "../adapters/pi/tmux-status.ts";

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

const permissionHandlers = (): Map<PermissionGateEventName, PermissionGateHandler> => {
  const handlers = new Map<PermissionGateEventName, PermissionGateHandler>();
  registerPermissionGate({
    on(event, handler) {
      handlers.set(event, handler);
    },
  });
  return handlers;
};

const permissionHandler = (): ((event: ToolCallEvent, ctx: ToolCallContext) => Promise<ToolCallDecision | void>) => {
  const registered = permissionHandlers().get("tool_call");
  if (!registered) throw new Error("permission handler was not registered");
  return async (event, ctx) => registered(event, ctx);
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
  test("points the Pi temporary directory into the project", async () => {
    const handlers = permissionHandlers();
    const ctx: ToolCallContext = {
      cwd: "/workspace/project",
      hasUI: true,
      ui: {
        async confirm() {
          return false;
        },
      },
    };

    const promptGuidelines: string[] = [];
    const promptEvent = { systemPromptOptions: { promptGuidelines } };
    await handlers.get("before_agent_start")?.(promptEvent, ctx);
    await handlers.get("before_agent_start")?.(promptEvent, ctx);

    expect(promptEvent.systemPromptOptions.promptGuidelines).toEqual([
      "Store temporary files under tmp/pi/ at the root of the active project, not under /tmp.",
    ]);
  });

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

  test("asks before a write to the global Pi temporary directory", async () => {
    const prompts: string[] = [];
    const decision = await permissionHandler()(
      { toolName: "write", input: { path: "/tmp/pi/reviews/report.md" } },
      {
        cwd: "/workspace/project",
        hasUI: true,
        ui: {
          async confirm(title, message) {
            prompts.push(`${title}\n${message}`);
            return false;
          },
        },
      },
    );

    expect(decision).toEqual({ block: true, reason: "Blocked by user" });
    expect(prompts[0]).toContain("Confirm external write");
  });

  test("leaves writes inside the project Pi temporary directory automatic", async () => {
    let promptCount = 0;
    const decision = await permissionHandler()(
      { toolName: "write", input: { path: "tmp/pi/viv-issue-subagents/coordinator-prompt.md" } },
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

  test("asks before a shell command changes files outside the active project", async () => {
    const prompts: string[] = [];
    const decision = await permissionHandler()(
      {
        toolName: "bash",
        input: {
          command:
            "ln -s /opt/pi/lib/node_modules/@earendil-works/pi-coding-agent ~/.pi/agent/npm/node_modules/pi-subagents/node_modules/@earendil-works/pi-coding-agent",
        },
      },
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
    expect(prompts[0]).toContain("filesystem command references a path outside the active project");
    expect(prompts[0]).toContain("~/.pi/agent/npm");
  });

  test("leaves shell file changes inside the project Pi temporary directory automatic", async () => {
    let promptCount = 0;
    const decision = await permissionHandler()(
      { toolName: "bash", input: { command: "mkdir -p ./tmp/pi/reviews" } },
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

  test("blocks inherited context for direct and scripted subagent launches", async () => {
    const ctx: ToolCallContext = {
      cwd: "/workspace/project",
      hasUI: true,
      ui: {
        async confirm() {
          throw new Error("forked context must not reach a confirmation prompt");
        },
      },
    };

    for (const input of [
      { action: "run", context: "fork" },
      { action: "run", context: "profile" },
      { action: "workflow", workflowScript: 'await runs.run({ context: "fork", task: "review" })' },
    ]) {
      const decision = await permissionHandler()({ toolName: "subagent", input }, ctx);
      expect(decision).toEqual({
        block: true,
        reason: "Forked subagent context is disabled; send the child an explicit task instead",
      });
    }
  });

  test("permits a fresh subagent with an explicit task", async () => {
    const decision = await permissionHandler()(
      { toolName: "subagent", input: { action: "run", context: "fresh", task: "Review the parser" } },
      {
        cwd: "/workspace/project",
        hasUI: true,
        ui: {
          async confirm() {
            throw new Error("fresh context must not reach a confirmation prompt");
          },
        },
      },
    );

    expect(decision).toBeUndefined();
  });
});

describe("Pi issue workflow", () => {
  test("lets the coordinator resume without unrestricted child roles", () => {
    const coordinator = readFileSync(
      new URL("../pi/agents/viv-issue-coordinator.md", import.meta.url),
      "utf8",
    );

    expect(coordinator).toContain(
      "allowedAgents: viv-issue-coordinator, viv-issue-implementor, viv-issue-reviewer",
    );
    expect(coordinator).toContain(
      "Do not start a fresh viv-issue-coordinator. The parent resumes this role only from its retained run.",
    );
  });
});

describe("Pi tmux status", () => {
  test("names the window and marks the final settled state", async () => {
    const previousPane = process.env.TMUX_PANE;
    process.env.TMUX_PANE = "%42";
    const handlers = new Map<string, () => Promise<void>>();
    const calls: string[][] = [];

    registerTmuxStatus({
      on(event, handler) {
        handlers.set(event, handler);
      },
      async exec(command, args) {
        calls.push([command, ...args]);
      },
    });

    try {
      await handlers.get("session_start")?.();
      await handlers.get("agent_start")?.();
      await handlers.get("ui_prompt_start")?.();
      await handlers.get("ui_prompt_end")?.();
      await handlers.get("agent_settled")?.();
      await handlers.get("session_shutdown")?.();
    } finally {
      if (previousPane === undefined) delete process.env.TMUX_PANE;
      else process.env.TMUX_PANE = previousPane;
    }

    const markUnlessViewed = [
      "tmux",
      "if-shell",
      "-F",
      "-t",
      "%42",
      "#{&&:#{window_active},#{session_attached}}",
      "set-option -w -t %42 -q @llm_agent_waiting 0",
      "set-option -w -t %42 -q @llm_agent_waiting 1",
    ];
    expect(calls).toEqual([
      ["tmux", "set-option", "-w", "-t", "%42", "-q", "@llm_agent_name", "pi"],
      markUnlessViewed,
      ["tmux", "set-option", "-w", "-t", "%42", "-q", "@llm_agent_waiting", "0"],
      markUnlessViewed,
      ["tmux", "set-option", "-w", "-t", "%42", "-q", "@llm_agent_waiting", "0"],
      markUnlessViewed,
      ["tmux", "set-option", "-w", "-t", "%42", "-q", "-u", "@llm_agent_name"],
      ["tmux", "set-option", "-w", "-t", "%42", "-q", "-u", "@llm_agent_waiting"],
    ]);
  });

  // A real server, because the rule lives in a tmux format that only tmux evaluates.
  // The control-mode client counts as attached, like a terminal that shows the session.
  test.skipIf(!Bun.which("tmux"))("marks only a window that the user does not view", async () => {
    const socket = `pi-status-test-${process.pid}`;
    const tmuxCmd = (...args: string[]) => {
      const run = Bun.spawnSync(["tmux", "-L", socket, "-f", "/dev/null", ...args]);
      if (run.exitCode !== 0) throw new Error(`tmux ${args.join(" ")}: ${run.stderr.toString()}`);
      return run.stdout.toString().trim();
    };
    const previousPane = process.env.TMUX_PANE;
    tmuxCmd("new-session", "-d", "-s", "t", "-x", "80", "-y", "24");
    const viewedPane = tmuxCmd("display-message", "-p", "-t", "t:0", "#{pane_id}");
    const hiddenPane = tmuxCmd("new-window", "-d", "-P", "-F", "#{pane_id}", "-t", "t:1");
    const client = Bun.spawn(["tmux", "-L", socket, "-C", "attach", "-t", "t"], { stdin: "pipe", stdout: "ignore" });

    const settle = async (pane: string) => {
      process.env.TMUX_PANE = pane;
      const handlers = new Map<string, () => Promise<void>>();
      registerTmuxStatus({
        on(event, handler) {
          handlers.set(event, handler);
        },
        async exec(command, args) {
          Bun.spawnSync([command, "-L", socket, ...args]);
        },
      });
      await handlers.get("agent_start")?.();
      await handlers.get("agent_settled")?.();
      return tmuxCmd("show-options", "-w", "-v", "-t", pane, "@llm_agent_waiting");
    };

    try {
      for (let i = 0; i < 50 && tmuxCmd("display-message", "-p", "-t", "t", "#{session_attached}") === "0"; i++) {
        await Bun.sleep(20);
      }
      expect(await settle(hiddenPane)).toBe("1");
      expect(await settle(viewedPane)).toBe("0");
    } finally {
      if (previousPane === undefined) delete process.env.TMUX_PANE;
      else process.env.TMUX_PANE = previousPane;
      client.kill();
      Bun.spawnSync(["tmux", "-L", socket, "kill-server"]);
    }
  });

  test("does not let a detached subagent change the parent window", () => {
    const previousPane = process.env.TMUX_PANE;
    const previousChild = process.env.PI_SUBAGENT_CHILD;
    process.env.TMUX_PANE = "%42";
    process.env.PI_SUBAGENT_CHILD = "1";
    let handlerCount = 0;

    try {
      registerTmuxStatus({
        on() {
          handlerCount += 1;
        },
        async exec() {
          throw new Error("a child must not reach tmux");
        },
      });
    } finally {
      if (previousPane === undefined) delete process.env.TMUX_PANE;
      else process.env.TMUX_PANE = previousPane;
      if (previousChild === undefined) delete process.env.PI_SUBAGENT_CHILD;
      else process.env.PI_SUBAGENT_CHILD = previousChild;
    }

    expect(handlerCount).toBe(0);
  });
});
