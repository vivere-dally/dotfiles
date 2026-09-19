/**
 * opencode plugin for the STE gate. opencode has no command hooks, thus the gate runs
 * in process, in the Bun runtime of opencode. The plugin only maps opencode tool calls
 * to the events of `ste/core.ts`, which holds each rule.
 *
 * - Before `bash`: a hard finding throws, and opencode gives the error text to the
 *   model as the result of the refused call.
 * - After `write`, `edit`, or `apply_patch` (the edit tool for GPT models): advice
 *   goes at the end of the tool output, which is what the model reads next.
 * - Advice about a shell command cannot go into a tool result that does not exist
 *   yet, thus it waits for the result of the same call.
 */

import { readFileSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

/**
 * opencode loads this file through a symlink in its plugins directory. The real path
 * finds `ste/` and `rules/` in llm-capabilities, whatever way the runtime resolves a
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

export const SteGate = async ({ directory }: { directory: string }) => {
  const core = await import(pathToFileURL(join(root, "ste", "core.ts")).href);
  const pending = new Map<string, string>();

  // The rules load for each call, so that an edit of a rule file applies at once.
  const run = (event: unknown) =>
    core.evaluate(event, { rules: core.loadRules(join(root, "rules"), read), projectDir: directory, read });

  const writtenPaths = (tool: string, args: any): string[] => {
    if ((tool === "write" || tool === "edit") && typeof args?.filePath === "string") {
      return [core.resolvePath(directory, args.filePath)];
    }
    if (tool === "apply_patch" && typeof args?.patchText === "string") {
      return core.patchFiles(args.patchText).map((p: string) => core.resolvePath(directory, p));
    }
    return [];
  };

  return {
    "tool.execute.before": async (input: { tool: string; callID: string }, output: { args: any }) => {
      if (input.tool !== "bash") return;
      let verdict;
      try {
        verdict = run({ kind: "shell", command: String(output.args?.command ?? "") });
      } catch (err) {
        // A broken gate must not stop the work, but a silent one is a fake gate: say so.
        pending.set(input.callID, `STE gate did not run: ${err instanceof Error ? err.message : String(err)}`);
        return;
      }
      if (verdict.action === "deny") throw new Error(verdict.reason);
      if (verdict.action === "advise") pending.set(input.callID, verdict.text);
    },

    "tool.execute.after": async (
      input: { tool: string; callID: string; args: any },
      output: { output: string },
    ) => {
      const notes: string[] = [];
      const held = pending.get(input.callID);
      if (held) {
        notes.push(held);
        pending.delete(input.callID);
      }
      const paths = writtenPaths(input.tool, input.args);
      if (paths.length > 0) {
        try {
          const verdict = run({ kind: "wrote", paths });
          if (verdict.action === "advise") notes.push(verdict.text);
        } catch (err) {
          notes.push(`STE gate did not run: ${err instanceof Error ? err.message : String(err)}`);
        }
      }
      if (notes.length > 0) output.output = `${output.output}\n\n${notes.join("\n\n")}`;
    },
  };
};
