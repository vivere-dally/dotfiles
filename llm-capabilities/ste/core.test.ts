import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { evaluate, loadRules, patchFiles, type GateContext } from "./core.ts";

const rulesDir = join(import.meta.dir, "..", "rules");
const read = (path: string): string | null => {
  try {
    return readFileSync(path, "utf8");
  } catch {
    return null;
  }
};
const context: GateContext = {
  rules: loadRules(rulesDir, read),
  projectDir: join(import.meta.dir, "..", ".."),
  read,
};

describe("shell gate", () => {
  test("denies a commit without a sign-off", () => {
    const verdict = evaluate({ kind: "shell", command: 'git commit -m "Repair parser"' }, context);
    expect(verdict.action).toBe("deny");
    if (verdict.action === "deny") expect(verdict.reason).toContain("sign-off");
  });

  test("accepts a signed commit", () => {
    const verdict = evaluate({ kind: "shell", command: 'git commit -s -m "Repair parser"' }, context);
    expect(verdict).toEqual({ action: "none" });
  });

  test("denies an unreadable GitHub body", () => {
    const verdict = evaluate(
      { kind: "shell", command: 'gh issue create --title "Parser" --body-file "$BODY_FILE"' },
      context,
    );
    expect(verdict.action).toBe("deny");
    if (verdict.action === "deny") expect(verdict.reason).toContain("shell expansion");
  });
});

test("extracts every destination from an apply_patch payload", () => {
  const patch = [
    "*** Begin Patch",
    "*** Update File: one.md",
    "*** Move to: two.md",
    "*** Add File: three.md",
    "*** End Patch",
  ].join("\n");
  expect(patchFiles(patch)).toEqual(["one.md", "two.md", "three.md"]);
});

describe("write gate", () => {
  test("ignores a Markdown file in an openspec directory", () => {
    const prose = "The value can be adjusted; e.g. it's done.";
    const verdict = evaluate(
      { kind: "wrote", paths: ["/repo/openspec/changes/add-x/proposal.md", "/repo/docs/guide.md"] },
      { ...context, projectDir: "/repo", read: (path) => (path.startsWith("/repo/") ? prose : read(path)) },
    );
    expect(verdict.action).toBe("advise");
    if (verdict.action === "advise") {
      expect(verdict.text).toContain("docs/guide.md");
      expect(verdict.text).not.toContain("openspec");
    }
  });
});
