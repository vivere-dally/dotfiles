#!/usr/bin/env bun
/**
 * Command entry of the STE gate, for the harnesses whose hooks run a shell command:
 * Claude Code and Codex. Both send one JSON event on stdin and read one JSON answer
 * on stdout, in nearly the same dialect. The differences that matter here:
 *
 * - Codex rejects `suppressOutput`, and a rejected answer loses its
 *   `additionalContext`. Claude Code ignores the field. Thus no answer carries it.
 * - Codex edits a file through `apply_patch`, with the patch text in
 *   `tool_input.command` and no `file_path`.
 * - Codex does not set `CLAUDE_PROJECT_DIR`, thus the payload `cwd` is the project.
 *
 * As `cli.ts --file <path>` it prints a plain report and exits 1 on a hard finding,
 * so a person and a CI job get the same verdict.
 */

import { existsSync, readFileSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  checkDocument,
  evaluate,
  lastReplyText,
  loadRules,
  patchFiles,
  report,
  resolvePath,
  type GateEvent,
  type ReadText,
} from "./core.ts";
import { parseCommands } from "./shell.ts";

const read: ReadText = (path) => {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return null;
  }
};

/**
 * The rules sit beside this directory in llm-capabilities. The real path keeps that
 * true when a harness reaches this file through a symlink.
 */
const rulesDir = join(dirname(realpathSync(fileURLToPath(import.meta.url))), "..", "rules");

function checkFile(path: string): number {
  const rules = loadRules(rulesDir, read);
  const source = read(path);
  if (source === null) throw new Error(`cannot read ${path}`);
  const findings = checkDocument(path, source, rules, process.cwd());
  const where = path.replace(`${process.cwd()}/`, "");
  if (findings.length === 0) {
    console.log(`Repository gate — ${where}: no finding.`);
    return 0;
  }
  console.log(report(findings, where));
  return findings.some((f) => f.severity === "hard") ? 1 : 0;
}

/** Maps one hook payload of Claude Code or Codex to the event that the core knows. */
async function toGateEvent(input: any, event: string, projectDir: string): Promise<GateEvent | null> {
  if (event === "UserPromptSubmit") return { kind: "prompt" };
  if (event === "Stop") {
    // One correction for each turn. When the model already continues because of
    // this hook, a second block can make a loop with no end.
    if (input.stop_hook_active) return null;
    return { kind: "reply", text: lastReplyText(read(input.transcript_path ?? "") ?? "") };
  }

  const tool: string = input.tool_name ?? "";
  const toolInput = input.tool_input ?? {};
  // Codex can give an exec command as an argument vector. The gate reads the words.
  const command = Array.isArray(toolInput.command) ? toolInput.command.join(" ") : String(toolInput.command ?? "");

  if (tool === "Bash") return { kind: "shell", command, commands: await parseCommandsOrNothing(command) };
  if (tool === "Write" || tool === "Edit" || tool === "MultiEdit") {
    const file: string = toolInput.file_path ?? "";
    return file ? { kind: "wrote", paths: [file] } : null;
  }
  if (tool === "apply_patch") {
    return { kind: "wrote", paths: patchFiles(command).map((p) => resolvePath(projectDir, p)) };
  }
  return null;
}

/** A parser failure leaves the text match of `core.ts` in charge, which errs on the side of a check. */
async function parseCommandsOrNothing(command: string): Promise<string[][] | undefined> {
  try {
    return await parseCommands(command);
  } catch {
    return undefined;
  }
}

async function main(): Promise<number> {
  // The command entry answers before any read of standard input. With no hook to
  // close the stream, a read there waits on a terminal that never sends an end.
  const flag = process.argv[2] ?? "";
  if (flag === "--file" || flag.startsWith("--file=")) {
    const path = flag.startsWith("--file=") ? flag.slice("--file=".length) : process.argv[3];
    if (!path) {
      console.error("usage: cli.ts --file <path>");
      return 2;
    }
    return checkFile(path);
  }

  // Only Claude Code sets CLAUDE_PROJECT_DIR, and only Claude Code runs the gate that
  // a repository keeps in `.claude/hooks/`. Such a repository owns its rules, and a
  // second run would only repeat each finding. Codex runs no project gate of that
  // kind, thus there this gate always runs.
  const claudeProject = process.env.CLAUDE_PROJECT_DIR;
  if (claudeProject && existsSync(`${claudeProject}/.claude/hooks/ste-check.ts`)) return 0;

  const input = JSON.parse(readFileSync(0, "utf8") || "{}");
  const event: string = input.hook_event_name ?? (input.tool_response ? "PostToolUse" : "PreToolUse");
  const projectDir: string = claudeProject ?? input.cwd ?? process.cwd();

  const gateEvent = await toGateEvent(input, event, projectDir);
  if (!gateEvent) return 0;
  const verdict = evaluate(gateEvent, { rules: loadRules(rulesDir, read), projectDir, read });

  switch (verdict.action) {
    case "none":
      return 0;
    case "deny":
      // A deny exists only before a tool runs. After it, the reason can only advise.
      console.log(
        JSON.stringify({
          hookSpecificOutput:
            event === "PreToolUse"
              ? { hookEventName: event, permissionDecision: "deny", permissionDecisionReason: verdict.reason }
              : { hookEventName: event, additionalContext: verdict.reason },
        }),
      );
      return 0;
    case "advise":
    case "context":
      console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: event, additionalContext: verdict.text } }));
      return 0;
    case "block-reply":
      console.log(JSON.stringify({ decision: "block", reason: verdict.reason }));
      return 0;
  }
}

try {
  process.exit(await main());
} catch (err) {
  const message = err instanceof Error ? err.message : String(err);
  // Under the command entry a broken checker must fail loudly, because a CI job
  // that reads exit 0 would call the text clean.
  if (process.argv.some((a) => a === "--file" || a.startsWith("--file="))) {
    console.error(`STE check did not run: ${message}`);
    process.exit(2);
  }
  // As a hook it must never stop work, but a silent one is a fake gate: say so.
  console.log(JSON.stringify({ systemMessage: `STE hook did not run: ${message}` }));
  process.exit(0);
}
