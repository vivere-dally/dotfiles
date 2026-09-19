# Applying Approved Findings

Runs only after the user names the IDs to apply. Never in the same turn as the report.

Compaction rides the normal OpenSpec change pipeline rather than editing `openspec/specs/**`
directly. A change is reviewable, has a proposal explaining *why* each merge happened, and
is revertible as one commit. A silent rewrite of 40 spec files is none of those.

## 1. Create the change

```bash
openspec new change compact-specs-<YYYY-MM>
```

Structure:

```
openspec/changes/compact-specs-<YYYY-MM>/
  proposal.md
  tasks.md
  specs/<capability>/spec.md    <- one delta file per touched capability
```

In a monorepo, one change **per OpenSpec root** — a change cannot span `app/openspec` and
`lib/openspec`.

`proposal.md` states what compaction found and why each class of operation is safe. Cite the
report `Ref:` fingerprints so the change traces back to the plan that justified it.

## 2. Write the deltas

Delta files use only these sections. At least one is required, or apply refuses
(`specs-apply.ts:297`).

```markdown
## MODIFIED Requirements
### Requirement: <exact existing header text>
<full new requirement body, including all scenarios>

## REMOVED Requirements
### Requirement: <exact existing header text>

## RENAMED Requirements
- FROM: `### Requirement: <old name>`
- TO: `### Requirement: <new name>`

## ADDED Requirements
### Requirement: <new header text>
<full body with scenarios>
```

Rules verified against the parser and applier:

- **`MODIFIED` carries the complete replacement body**, not a diff. The block replaces the
  original wholesale, so an omitted scenario is a deleted scenario.
- **`REMOVED` needs only the header line.** It matches on exact header text. If a header
  differs only in case or interior whitespace, apply treats it as a typo and **hard-aborts**
  with the near-miss named (`specs-apply.ts:404-420`). Copy headers, never retype them.
- **`RENAMED` requires the `FROM:`/`TO:` pair**, each wrapping a full
  `### Requirement: <name>` in backticks. Order matters: `TO:` closes the pair.
- **A requirement must not appear in both `RENAMED` and `REMOVED`** (`specs-apply.ts:271`),
  and **`ADDED` must not collide with a `RENAMED` TO** (`specs-apply.ts:283`).
- **`MODIFIED` and `RENAMED` are illegal on a spec that does not exist yet**
  (`specs-apply.ts:328`) — a brand-new merged capability takes `ADDED` only.

Apply order is fixed: **RENAMED → REMOVED → MODIFIED → ADDED** (`specs-apply.ts:375`).
Write deltas that are correct under that order — rename before removing, never after.

## 3. Mapping operations to deltas

| Operation | Delta shape |
|---|---|
| `REPAIR` (moved ref) | `MODIFIED` on the owning requirement, path corrected |
| `REPAIR` (dead ref) | Only after the user answers; then `MODIFIED` or `REMOVED` |
| `FOLD` | `REMOVED` in the source spec; `MODIFIED` on the owner if it absorbs wording |
| `MERGE` | `REMOVED` for every requirement in the absorbed spec; `ADDED`/`MODIFIED` on the survivor |
| `ABSORB` | Same as `MERGE`, usually a single requirement |
| `TRIM` | `MODIFIED` with the consolidated scenario set |

**Capability retirement is automatic.** Removing a spec's last requirement deletes its
`spec.md` and prunes empty directories (`specs-apply.ts:758-760`). Do not delete spec files
by hand — let the delta do it, so the removal is recorded as a change.

Retirement **refuses** when the file holds content the merge cannot account for — authored
prose outside requirement structure, extra `## ` sections (`specs-apply.ts:153-178`). That
guard is correct: it means hand-written context would have been lost. Move that prose into
the surviving spec first, then retire.

## 4. Verify before handing back

```bash
openspec validate <change-name> --strict --json
openspec validate --specs --strict --json
```

Then the **conservation ledger** — the number that makes compaction trustworthy:

```bash
python3 <skill>/scripts/scan.py <repo-root> --out /tmp/opsx-after.json
```

Report before/after for specs, requirements, scenarios, and tokens, and reconcile the
requirement delta against the plan. If more requirements disappeared than the plan
accounted for, **stop and report it** — do not rationalize the difference.

## 5. Hand off

Do not run `/opsx:apply`, `/opsx:sync`, or `/opsx:archive` yourself. Compaction produces the
change. The user drives their own pipeline. `/opsx:sync` is agent-driven for a reason, and
its intelligent merge is exactly what a partial delta needs.

Report: change name, files written, the conservation ledger, and the suggested next command.

Never `git commit` or `git push` without explicit per-action confirmation.
