#!/usr/bin/env bun
/**
 * Builds one copy of the skills and rules for each agent harness, so that each
 * harness reads its own tool names instead of a phrase that has to fit all four.
 *
 *   usage: bun render.ts <out-dir>        (<out-dir>/src must link to this directory)
 *
 * A `*.template.md` file holds placeholders such as `{{ask_user}}` or
 * `{{load_skill:viv-grilling}}`. `harnesses/<harness>.json` gives the value of each
 * placeholder for that harness, and `skills/<skill>/SKILL.<harness>.json` can
 * override a value for one skill. In a value, `{0}` receives the text after the
 * colon.
 *
 * The output is `<out-dir>/<harness>/skills/<skill>/`, `<out-dir>/<harness>/rules/`,
 * and `<out-dir>/<harness>/AGENTS.md`. A rendered file, and each `SKILL.md`, is a real,
 * read-only file. Each other file is a link back through `<out-dir>/src`, so an edit
 * of a script or a plain document reaches every harness without a rebuild.
 *
 * A placeholder without a value, and a hard STE finding in a rendered file, stop the
 * build before any harness changes. The last good build then stays in place.
 */

import {
  chmodSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  realpathSync,
  renameSync,
  rmSync,
  statSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { checkDocument, loadRules, report } from "./ste/core.ts";

type Values = Record<string, string>;

const srcRoot = dirname(realpathSync(fileURLToPath(import.meta.url)));
const outDir = process.argv[2];
if (!outDir) {
  console.error("usage: bun render.ts <out-dir>");
  process.exit(2);
}
const linkBase = join(outDir, "src");

const read = (path: string): string | null => {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return null;
  }
};

const readJson = (path: string): Values => {
  const value = JSON.parse(readFileSync(path, "utf8"));
  for (const [key, text] of Object.entries(value)) {
    if (typeof text !== "string") throw new Error(`${relative(srcRoot, path)}: "${key}" is not a string`);
  }
  return value as Values;
};

const PLACEHOLDER = /\{\{([a-z_]+)(?::([^{}]+))?\}\}/g;
/** A per-skill override file: the build reads it and never ships it. */
const OVERRIDE = /^SKILL\.[a-z]+\.json$/;
const TEMPLATE = ".template.md";

function render(text: string, values: Values, where: string): string {
  return text.replace(PLACEHOLDER, (all, key: string, arg: string | undefined, offset: number) => {
    const line = text.slice(0, offset).split("\n").length;
    const value = values[key];
    if (value === undefined) throw new Error(`${where}:${line}: no value for ${all}`);
    const takesArg = value.includes("{0}");
    if (takesArg && arg === undefined) throw new Error(`${where}:${line}: ${all} needs a name, for example {{${key}:<name>}}`);
    if (!takesArg && arg !== undefined) throw new Error(`${where}:${line}: ${all} takes no name`);
    return arg === undefined ? value : value.replaceAll("{0}", arg);
  });
}

/**
 * The notice goes after the frontmatter, because each harness finds the frontmatter
 * only on the first line. An HTML comment stays out of the prose that the model and
 * the STE gate read.
 */
function withNotice(text: string, source: string, harness: string): string {
  const notice = `<!-- Generated for ${harness} from llm-capabilities/${source}. Edit that file, then run scripts/llm-capabilities.sh. -->\n`;
  const frontmatter = /^---\n[\s\S]*?\n---\n/.exec(text);
  if (!frontmatter) return notice + text;
  return frontmatter[0] + notice + text.slice(frontmatter[0].length);
}

function walk(dir: string): string[] {
  const files: string[] = [];
  for (const name of readdirSync(dir).sort()) {
    if (name === ".DS_Store") continue;
    const path = join(dir, name);
    if (statSync(path).isDirectory()) files.push(...walk(path));
    else files.push(path);
  }
  return files;
}

/** The rendered files of one harness, for the STE check after the build. */
type Rendered = { path: string; text: string };

/**
 * Builds one source directory into `stage`. A template becomes a rendered file, and
 * each other file becomes a link to its source through `linkBase`.
 *
 * The exception is a plain `SKILL.md`, which becomes a copy. Codex 0.154 follows a
 * link to a skill directory, but it skips a skill whose `SKILL.md` is itself a link:
 * `codex debug prompt-input` listed only the skills with a rendered `SKILL.md`.
 */
function buildTree(source: string, stage: string, values: Values, harness: string, rendered: Rendered[]): void {
  for (const file of walk(source)) {
    const rel = relative(source, file);
    if (OVERRIDE.test(rel)) continue;
    const sourceRel = relative(srcRoot, file);
    const isTemplate = rel.endsWith(TEMPLATE);
    if (isTemplate || rel === "SKILL.md") {
      const outRel = isTemplate ? rel.slice(0, -TEMPLATE.length) + ".md" : rel;
      if (isTemplate && existsSync(join(source, outRel))) {
        throw new Error(`${sourceRel}: ${outRel} exists next to its template. Keep one of the two.`);
      }
      const body = readFileSync(file, "utf8");
      const out = join(stage, outRel);
      const text = withNotice(isTemplate ? render(body, values, sourceRel) : body, sourceRel, harness);
      mkdirSync(dirname(out), { recursive: true });
      writeFileSync(out, text);
      // Read-only, so that an edit through the harness directory fails at once
      // instead of silently vanishing at the next build.
      chmodSync(out, 0o444);
      rendered.push({ path: out, text });
      continue;
    }
    const out = join(stage, rel);
    mkdirSync(dirname(out), { recursive: true });
    symlinkSync(join(linkBase, sourceRel), out);
  }
}

function buildHarness(harness: string, stage: string): Rendered[] {
  const base = readJson(join(srcRoot, "harnesses", `${harness}.json`));
  const rendered: Rendered[] = [];

  for (const skill of readdirSync(join(srcRoot, "skills")).sort()) {
    const dir = join(srcRoot, "skills", skill);
    if (!statSync(dir).isDirectory()) continue;
    const overridePath = join(dir, `SKILL.${harness}.json`);
    const values = existsSync(overridePath) ? { ...base, ...readJson(overridePath) } : base;
    buildTree(dir, join(stage, "skills", skill), values, harness, rendered);
  }

  buildTree(join(srcRoot, "rules"), join(stage, "rules"), base, harness, rendered);

  // Codex, opencode, and pi read one user instruction file each, thus the rules go
  // into one file for them. Claude Code reads the rules directory.
  const ruleFiles = readdirSync(join(stage, "rules")).filter((f) => f.endsWith(".md")).sort();
  const parts = ruleFiles.map((f) => readFileSync(join(stage, "rules", f), "utf8").trim());
  writeFileSync(
    join(stage, "AGENTS.md"),
    `<!-- Generated for ${harness} from llm-capabilities/rules. Edit those files, then run scripts/llm-capabilities.sh. -->\n\n${parts.join("\n\n")}\n`,
  );
  chmodSync(join(stage, "AGENTS.md"), 0o444);
  return rendered;
}

function main(): number {
  const harnesses = readdirSync(join(srcRoot, "harnesses"))
    .filter((f) => f.endsWith(".json"))
    .map((f) => f.slice(0, -".json".length))
    .sort();
  const steRules = loadRules(join(srcRoot, "rules"), read);
  const staged: [string, string][] = [];
  const failures: string[] = [];

  mkdirSync(outDir, { recursive: true });
  for (const harness of harnesses) {
    const stage = join(outDir, `${harness}.new`);
    rmSync(stage, { recursive: true, force: true });
    staged.push([harness, stage]);
    try {
      for (const { path, text } of buildHarness(harness, stage)) {
        // A value can make a sentence longer than its template, thus the gate
        // reads the rendered file, not only the template.
        const hard = checkDocument(path, text, steRules, stage).filter((f) => f.severity === "hard");
        if (hard.length > 0) failures.push(report(hard, `${harness}/${relative(stage, path)}`));
      }
    } catch (err) {
      failures.push(err instanceof Error ? err.message : String(err));
    }
  }

  if (failures.length > 0) {
    for (const [, stage] of staged) rmSync(stage, { recursive: true, force: true });
    console.error(`llm-capabilities: the build stopped, and no harness changed.\n\n${failures.join("\n\n")}`);
    return 1;
  }

  for (const [harness, stage] of staged) {
    const live = join(outDir, harness);
    rmSync(live, { recursive: true, force: true });
    renameSync(stage, live);
  }
  console.log(`llm-capabilities: built ${harnesses.join(", ")} in ${outDir}`);
  return 0;
}

process.exit(main());
