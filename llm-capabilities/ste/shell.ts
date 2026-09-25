/**
 * Reads a shell command with tree-sitter-bash, so that a gate can tell a real
 * command from text inside a quoted argument. The pi permission gate and the STE
 * gate share it.
 *
 * Nothing here does work at import time. The parser loads on the first call, thus
 * `core.ts` can import the pure helpers and still do no I/O of its own.
 */

import { realpathSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import type { Node, Parser } from "web-tree-sitter";

let bashParser: Promise<Parser> | undefined;
const loadBashParser = (): Promise<Parser> =>
  (bashParser ??= (async () => {
    // pi and opencode load this file through links. The real path finds the
    // node_modules of llm-capabilities, whatever way the loader resolves a bare import.
    const nodeModules = join(dirname(realpathSync(fileURLToPath(import.meta.url))), "..", "node_modules");
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
 * `$(...)` included. A quoted argument stays one word, thus a sed script or a grep
 * pattern is never read as a command or a path.
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

/** The words of each simple command, or `undefined` when the parser cannot read the script. */
export const parseCommands = async (command: string): Promise<string[][] | undefined> => {
  const tree = (await loadBashParser()).parse(command);
  if (!tree || tree.rootNode.hasError) return undefined;
  return simpleCommands(tree.rootNode);
};

/** `env VAR=value` and `command` only start the real command. */
export const unwrap = (words: string[]): string[] => {
  let rest = words;
  for (;;) {
    if (rest[0] === "command") rest = rest.slice(1);
    else if (rest[0] === "env") {
      rest = rest.slice(1);
      while (rest[0] && (/^[A-Za-z_][A-Za-z0-9_]*=/.test(rest[0]) || rest[0].startsWith("-"))) rest = rest.slice(1);
    } else return rest;
  }
};

/** The Git subcommand and its arguments, after options such as `-C <dir>` and `-c <key=value>`. */
export const gitSubcommand = (args: string[]): [string | undefined, string[]] => {
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "-C" || args[i] === "-c") i++;
    else if (!args[i].startsWith("-")) return [args[i], args.slice(i + 1)];
  }
  return [undefined, []];
};
