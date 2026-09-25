/**
 * pi extension for the STE gate. pi has no command hooks, thus the gate runs in
 * process, in Node through jiti. The extension only maps pi tool events to the
 * events of `ste/core.ts`, which holds each rule.
 *
 * - `tool_call` of `bash`: a hard finding returns `{ block: true, reason }`, and pi
 *   gives the reason to the model as an error result.
 * - `tool_result` of `write` or `edit`: advice goes at the end of the tool result,
 *   which is what the model reads next.
 * - Advice about a shell command cannot go into a tool result that does not exist
 *   yet, thus it waits for the result of the same call.
 */

import { readFileSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

/**
 * pi loads this file through a symlink in its extensions directory. The real path
 * finds `ste/` and `rules/` in llm-capabilities, whatever way jiti resolves a
 * relative import from a symlink.
 */
const root = join(dirname(realpathSync(fileURLToPath(import.meta.url))), "..", "..");

const read = (path: string): string | null => {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return null;
  }
};

type TextBlock = { type: "text"; text: string };

// The pi types come from its package, which this repository does not install. The
// fields below are the only ones that the extension reads or returns.
type Pi = {
  on(event: "tool_call", handler: (event: any, ctx: { cwd: string }) => unknown): void;
  on(event: "tool_result", handler: (event: any, ctx: { cwd: string }) => unknown): void;
};

export default async function (pi: Pi) {
  const core = await import(pathToFileURL(join(root, "ste", "core.ts")).href);
  const shell = await import(pathToFileURL(join(root, "ste", "shell.ts")).href);
  const pending = new Map<string, string>();

  // The rules load for each call, so that an edit of a rule file applies at once.
  const run = (event: unknown, cwd: string) =>
    core.evaluate(event, { rules: core.loadRules(join(root, "rules"), read), projectDir: cwd, read });

  const failure = (err: unknown) => `STE gate did not run: ${err instanceof Error ? err.message : String(err)}`;

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;
    let verdict;
    try {
      const command = String(event.input?.command ?? "");
      // A parser failure leaves the text match in charge, which errs on the side of a check.
      const commands = await shell.parseCommands(command).catch(() => undefined);
      verdict = run({ kind: "shell", command, commands }, ctx.cwd);
    } catch (err) {
      // A broken gate must not stop the work, but a silent one is a fake gate: say so.
      pending.set(event.toolCallId, failure(err));
      return;
    }
    if (verdict.action === "deny") return { block: true, reason: verdict.reason };
    if (verdict.action === "advise") pending.set(event.toolCallId, verdict.text);
  });

  pi.on("tool_result", (event, ctx) => {
    const notes: string[] = [];
    const held = pending.get(event.toolCallId);
    if (held) {
      notes.push(held);
      pending.delete(event.toolCallId);
    }
    if ((event.toolName === "write" || event.toolName === "edit") && typeof event.input?.path === "string") {
      try {
        const verdict = run({ kind: "wrote", paths: [core.resolvePath(ctx.cwd, event.input.path)] }, ctx.cwd);
        if (verdict.action === "advise") notes.push(verdict.text);
      } catch (err) {
        notes.push(failure(err));
      }
    }
    if (notes.length === 0) return;
    const added: TextBlock = { type: "text", text: notes.join("\n\n") };
    return { content: [...(event.content ?? []), added] };
  });
}
