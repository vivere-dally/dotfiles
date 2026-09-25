import { describe, expect, test } from "bun:test";
import { join } from "node:path";
import { SteGate } from "../adapters/opencode/ste-gate.ts";
import registerPi from "../adapters/pi/ste-gate.ts";

const projectDir = join(import.meta.dir, "..", "..");
const unsignedCommit = 'git commit -m "Repair parser"';

describe("command adapter", () => {
  test("returns a denial in the Claude and Codex hook dialect", async () => {
    const input = JSON.stringify({
      hook_event_name: "PreToolUse",
      tool_name: "Bash",
      tool_input: { command: unsignedCommit },
      cwd: projectDir,
    });
    const child = Bun.spawn({
      cmd: [process.execPath, join(import.meta.dir, "cli.ts")],
      cwd: projectDir,
      stdin: "pipe",
      stdout: "pipe",
    });
    child.stdin.write(input);
    child.stdin.end();
    expect(await child.exited).toBe(0);
    const output = JSON.parse(await new Response(child.stdout).text());
    expect(output.hookSpecificOutput.permissionDecision).toBe("deny");
    expect(output.hookSpecificOutput.permissionDecisionReason).toContain("sign-off");
  });
});

describe("commit detection", () => {
  // The text of a commit command inside a quoted argument is not a commit.
  const quotedCommit = `grep -rn "${unsignedCommit.replace(/"/g, "'")}" docs`;

  test("the command adapter lets a command that only quotes a commit run", async () => {
    const input = JSON.stringify({
      hook_event_name: "PreToolUse",
      tool_name: "Bash",
      tool_input: { command: quotedCommit },
      cwd: projectDir,
    });
    const child = Bun.spawn({
      cmd: [process.execPath, join(import.meta.dir, "cli.ts")],
      cwd: projectDir,
      stdin: "pipe",
      stdout: "pipe",
    });
    child.stdin.write(input);
    child.stdin.end();
    expect(await child.exited).toBe(0);
    expect((await new Response(child.stdout).text()).trim()).toBe("");
  });

  test("the pi adapter lets a command that only quotes a commit run", async () => {
    const handlers: Record<string, (event: any, context: { cwd: string }) => unknown> = {};
    await registerPi({
      on(event, handler) {
        handlers[event] = handler;
      },
    });
    const verdict = await handlers.tool_call?.(
      { toolName: "bash", toolCallId: "call-2", input: { command: quotedCommit } },
      { cwd: projectDir },
    );
    expect(verdict).toBeUndefined();
  });
});

describe("opencode adapter", () => {
  test("blocks an unsigned commit before execution", async () => {
    const hooks = await SteGate({ directory: projectDir });
    await expect(
      hooks["tool.execute.before"](
        { tool: "bash", callID: "call-1" },
        { args: { command: unsignedCommit } },
      ),
    ).rejects.toThrow("sign-off");
  });
});

describe("pi adapter", () => {
  test("blocks an unsigned commit before execution", async () => {
    const handlers: Record<string, (event: any, context: { cwd: string }) => unknown> = {};
    await registerPi({
      on(event, handler) {
        handlers[event] = handler;
      },
    });
    const verdict = await handlers.tool_call?.(
      { toolName: "bash", toolCallId: "call-1", input: { command: unsignedCommit } },
      { cwd: projectDir },
    );
    expect(verdict).toMatchObject({ block: true });
    expect((verdict as { reason: string }).reason).toContain("sign-off");
  });
});
