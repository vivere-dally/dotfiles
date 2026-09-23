# Agent code efficiency

- Research date: 2026-09-23.
- Scope: the time complexity and the data access of code that coding agents write, and the controls that change them.
- Sources: peer-reviewed papers, arXiv preprints, official tool documentation, vendor documentation, and local capability files.
- Method: a Claude agent wrote this note. A second agent, GLM-5.3 Flash in pi, fetched the same primary sources again. It found no contradiction, and it added the full model table of Zhang and Kothari.

## Conclusion

You can nudge agents, but a general instruction such as "write efficient code" has a small and unreliable effect. Specific instructions and deterministic checks have better support.

Model code is frequently slower than expert code on algorithm tasks. On real repositories, the gap is larger.

A generic efficiency prompt did not consistently improve efficiency, and it often reduced correctness ([EvalPerf, COLM 2024](https://arxiv.org/abs/2408.06450)). A specific statement of the problem changed results more ([Yi, Gay, and Leitner, 2026](https://arxiv.org/abs/2510.15494)).

Execution feedback gave the largest measured gains. Feedback from real runs also kept correctness better than feedback in prose ([ECCO, EMNLP 2024](https://aclanthology.org/2024.emnlp-main.859/)).

The evidence has two large gaps. No source measures the N+1 query rate in agent code. No source measures an efficiency rule in `AGENTS.md` or `CLAUDE.md`.

Thus the practical design has three layers:

1. A short rule names the concrete patterns: a lookup inside a loop, and a query inside a loop.
2. A review pass looks for those patterns in the diff.
3. A project test fails on the pattern: an N+1 detector or a query-count assertion.

Measure each layer on a fixture set before you trust it.

## How often model code is inefficient

### Algorithm benchmarks

These benchmarks use small, self-contained tasks, mostly in Python:

- EffiBench has 1,000 LeetCode tasks. On average, GPT-4 code used 3.12 times the execution time of the canonical solution. In the worst case, it used 13.89 times ([EffiBench, NeurIPS 2024](https://arxiv.org/abs/2402.02037)).
- A later paper quotes the EffiBench leaderboard: 2.59 to 3.44 times the human execution time on average, and up to about 68 times in the worst case ([LLM-as-a-Critique, NeurIPS 2025](https://ece.uwaterloo.ca/~wshang/pubs/NEUIPS2025_ZHU.pdf)).
- On Mercury, the best code models reached 65% on Pass but less than 50% on Beyond, a score that weights each pass by runtime ([Mercury, NeurIPS 2024](https://arxiv.org/abs/2402.07844)).
- ENAMEL reports that models "struggle in designing advanced algorithms and are barely aware of implementation optimization" ([ENAMEL, ICLR 2025](https://arxiv.org/abs/2406.06647)).
- A manual review of 492 HumanEval+ solutions from 7B-class models found a performance inefficiency in 34.15%. It found a suboptimal time complexity in 18.5% ([Abbassi and others, 2025](https://arxiv.org/abs/2503.06327)).
- Zhang and Kothari used 202 LeetCode problems that are sensitive to complexity. The Python time-limit failure rate was 9.90% for GPT-4.1, 13.86% for Claude 3.7, and 41.58% for Llama 3.3 ([Zhang and Kothari, 2025](https://arxiv.org/abs/2512.18131)).

Model size does not fix this. On EvalPerf, "the scaling law persists for code correctness but does not seem explicit for code efficiency" ([EvalPerf, COLM 2024](https://arxiv.org/abs/2408.06450)).

### Real repositories

On real repositories, the task is to make slow code faster. The results are weaker than on puzzles:

- SWE-fficiency has 498 tasks. Agents reached less than 0.23 times the expert speedup on average. They failed to localize the slow code, to reason across functions, and to keep correctness ([SWE-fficiency, ICML 2026](https://arxiv.org/abs/2511.06090)).
- On GSO, leading agents solved fewer than 5% of tasks on one attempt, and about 15% with ten attempts. The authors name lazy optimization and poor localization of bottlenecks as causes ([GSO, NeurIPS 2025](https://arxiv.org/abs/2505.23671)).
- SWE-Perf reports a significant gap between agents and expert patches on 140 instances ([SWE-Perf, 2025](https://arxiv.org/abs/2507.12415)).
- On SWE-Pro, models gave "negligible" runtime gains. Expert patches gave a 15.5 times speedup ([SWE-Pro, 2026](https://arxiv.org/abs/2606.25530)).
- On 65 Java tasks, model patches were faster than the original code with large effect sizes. But the developer patches were faster than every model configuration ([Yi, Gay, and Leitner, 2026](https://arxiv.org/abs/2510.15494)).

These benchmarks measure optimization tasks. They do not measure the efficiency of new feature code, which is the case that this question is about. No benchmark in this search measures that case on real repositories.

### Agent pull requests

Studies of the AIDev dataset of agent pull requests on GitHub give field data:

- Performance pull requests are rare: 324 of 33,596 agent pull requests carry a performance label ([arXiv 2607.05666](https://arxiv.org/abs/2607.05666)).
- Agent performance pull requests merged at 57%, against 65% for human ones ([arXiv 2512.21757](https://arxiv.org/abs/2512.21757)).
- Of the agent performance pull requests, 45.7% gave validation evidence, against 63.6% of human ones. Only 25% of the validated agent pull requests used a benchmark, against 49% of human ones ([arXiv 2512.21757](https://arxiv.org/abs/2512.21757)).

Thus agents frequently claim a speedup from static reasoning alone.

### Database access

This search found no measured rate of N+1 queries or other query anti-patterns in model or agent code. Two web searches and a direct search of arXiv gave no such study.

The nearest evidence is indirect. Research on human code detects "one-by-one processing", the N+1 pattern, as an ORM performance anti-pattern ([Chen and others, ICSE 2014](https://doi.org/10.1145/2568225.2568259)).

A 2026 study of agents that build backends found that data-layer defects were the leading root cause of failure. The defects were "incorrect query composition and ORM runtime violations" ([Constraint Decay, 2026](https://arxiv.org/abs/2605.06445)). This study measures correctness, not query efficiency.

### A caution about the measurements

Small test inputs hide complexity. Across EffiBench, ENAMEL, EvalPerf, and Mercury, only 6.11% of the "performant" solutions were significantly faster than the canonical solutions with the original tests ([Rethinking Code Performance Benchmarks, 2026](https://arxiv.org/abs/2607.07619)).

In 209 of 308 tasks that the authors examined, weak tests hid a possible improvement. The authors of a FORGE 2024 paper also found that small HumanEval and MBPP inputs hid the difference in complexity ([Niu and others, FORGE 2024](https://arxiv.org/abs/2404.06041)).

As a result, a performance check must use inputs that are large enough to separate the complexity classes.

## Which interventions help

### Generic efficiency instructions: weak

- EvalPerf added "solve the programming task efficiently by writing a fast implementation", with and without "Think step by step". These prompts "neither consistently nor noticeably improve the code efficiency", and they "commonly lead to correctness degradation" ([EvalPerf, COLM 2024](https://arxiv.org/abs/2408.06450)).
- Zhang and Kothari added "Optimize the time complexity of your algorithm." to the prompt. The authors say that it "effectively reduces algorithmic suboptimality for several models, particularly DeepSeek-R1, DeepSeek-V3, and GPT-4.1" ([Zhang and Kothari, 2025, Table 5](https://arxiv.org/html/2512.18131v1)). The Python time-limit failure rates, before and after:
  - DeepSeek-R1: 4.95% and 2.97%.
  - GPT-4.1: 9.90% and 7.43%.
  - DeepSeek-V3: 8.42% and 5.45%.
  - Qwen2.5-Coder: 12.38% and 7.92%.
  - Claude 3.7: 13.86% and 13.37%. In C++ and Go, the rate of Claude 3.7 increased, for example from 12.87% to 14.36% in Go.
- A FORGE 2024 study tried a direct prompt and chain-of-thought prompts on GPT-4, GPT-3.5, and DeepSeek Coder. The gap between the prompts was larger on medium problems than on easy problems ([Niu and others, FORGE 2024](https://arxiv.org/abs/2404.06041)).

A change of 2 percentage points on 202 problems is about 4 problems. Thus the positive results are small, and they depend on the model.

### Specific problem statements: moderate

A study of real Java code compared four prompts. With no hint, all models gave only incremental improvements. A description of the specific performance problem was "the primary driver for unlocking optimization potential" ([Yi, Gay, and Leitner, 2026](https://arxiv.org/abs/2510.15494)).

With a problem description, the rate of solutions that used a different strategy from the developer fell from 59% to 5% ([Yi, Gay, and Leitner, 2026](https://arxiv.org/abs/2510.15494)).

Anthropic gives the same direction for instruction files. "The more specific and concise your instructions, the more consistently Claude follows them" ([Claude Code memory](https://code.claude.com/docs/en/memory)). Anthropic also says that the reason for an instruction helps the model ([Anthropic prompt guidance](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)).

### Execution feedback and profiles: strong on puzzles

- EffiLearner runs the code, gives the time and memory profile to the model, and asks for a revision. For StarCoder2-15B on EffiBench, execution time fell from 0.93 s to 0.12 s (87.1%). Total memory usage fell by 90.8% ([EffiLearner, NeurIPS 2024](https://arxiv.org/abs/2405.15189)).
- ECCO found that most methods reduce correctness and moderately increase efficiency. Execution feedback "often helps maintain functional correctness", and feedback in prose "enhances more on efficiency". More refinement rounds consistently decreased pass@1 ([ECCO, EMNLP 2024](https://aclanthology.org/2024.emnlp-main.859/)).
- PIE combined retrieved examples, chain of thought, and fine-tuning on C++ code. It reached a mean speedup of 6.86 with eight generations, against 3.66 for the average human edit ([PIE, ICLR 2024](https://arxiv.org/abs/2302.07867)).
- PERFOPT-Bench warns that "raw speedup is unsafe as a benchmark score", because agents exploit shortcuts that are specific to the benchmark ([PERFOPT-Bench, 2026](https://arxiv.org/abs/2607.07744)).

Thus a speed measurement helps only together with correctness tests.

### Self-review and critique: promising, not proven for agents

The LLM-as-a-Critique study used a second model as an efficiency critic of the syntax tree, without execution. The method reduced average execution time by up to 70.6%, and it kept functionality ([LLM-as-a-Critique, NeurIPS 2025](https://ece.uwaterloo.ca/~wshang/pubs/NEUIPS2025_ZHU.pdf)).

That method scores candidates during decoding. An agent review pass after the edit is a different method. No source in this search measures the transfer.

Self-refine with prose feedback gave the largest speedups in ECCO, but it also lost the most correctness ([ECCO, EMNLP 2024](https://aclanthology.org/2024.emnlp-main.859/)).

### Rules files: no direct evidence

- No source measures an efficiency rule in an instruction file.
- Of 2,303 agent context files, only 14.5% contain performance instructions ([Agent READMEs, 2025](https://arxiv.org/abs/2511.12884)).
- Context files did not generally improve task success. They increased inference cost by more than 20%. But agents followed the instructions in the files well ([Evaluating AGENTS.md, 2026](https://arxiv.org/abs/2602.11988)).
- In 1,650 Claude Code sessions, file size, position, and structure had no detectable effect on adherence. Each additional function that the agent wrote lowered the odds of compliance by about 5.6% ([McMillan, 2026](https://arxiv.org/abs/2605.10039)).

The last result suggests that a rule is weakest late in a long session. A review pass at the end puts the rule next to the final diff. This is an inference.

Anthropic says that instruction files are "context, not enforced configuration". For a guaranteed action, it recommends a hook ([Claude Code memory](https://code.claude.com/docs/en/memory)).

### Deterministic detectors and query-count tests: strong mechanism, no agent study

These tools turn a query anti-pattern into a test failure:

| Stack | Tool | Setting that fails a test |
| --- | --- | --- |
| Rails | [Bullet](https://github.com/flyerhzm/bullet) | `Bullet.raise = true` detects N+1 queries, unused eager loads, and missing counter caches. |
| Rails | [`strict_loading`](https://guides.rubyonrails.org/active_record_querying.html) | `strict_loading_by_default`, or the `:n_plus_one_only` mode, raises `StrictLoadingViolationError`. |
| SQLAlchemy | [`raiseload`](https://docs.sqlalchemy.org/en/20/orm/queryguide/relationships.html) | `lazy="raise"` replaces a lazy load with an error. |
| Django | [`assertNumQueries`](https://docs.djangoproject.com/en/5.2/topics/testing/tools/) | The test fails when the query count differs from the expected number. |
| Django | [django-zeal](https://github.com/taobojlen/django-zeal) | It raises `ZealError` on N+1 queries by default. The last push to the repository was in August 2026. |
| Django, SQLAlchemy | [nplusone](https://github.com/jmcarp/nplusone) | `NPLUSONE_RAISE = True`. The last push to the repository was in November 2022. |
| Hibernate | [`Statistics`](https://github.com/hibernate/hibernate-orm/blob/main/hibernate-core/src/main/java/org/hibernate/stat/Statistics.java) | Assert `getPrepareStatementCount()` after the call, with `hibernate.generate_statistics` set. |
| Prisma | [Query optimization](https://www.prisma.io/docs/orm/prisma-client/queries/query-optimization-performance) | No built-in detector. Prisma batches `findUnique()` calls in one tick, and `relationLoadStrategy: "join"` uses one query. |

No source measures the effect of these tools on agent output. The mechanism is execution feedback, which ECCO and EffiLearner support. Thus the expected effect is an inference.

## The local setup

The current rule targets volume, not complexity. It says "Bound each operation whose cost grows with an input" and gives "Stream, chunk, or page it" as the fixes (`llm-capabilities/rules/engineering.template.md:25-27`).

That rule does not name a set or a map for lookups. It also does not name a query inside a loop.

The rules reach every harness. The renderer joins the rule files into one `AGENTS.md` for Codex, opencode, and pi. Claude Code reads the rules directory (`llm-capabilities/render.ts:159-170`).

Hooks do not reach every harness through one file. Each harness has its own adapter, for example `llm-capabilities/adapters/codex/hooks.json` and `llm-capabilities/adapters/pi/ste-gate.ts`.

Codex stops the addition of instruction files at 32 KiB by default ([Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md)). Anthropic recommends less than 200 lines for each `CLAUDE.md` file ([Claude Code memory](https://code.claude.com/docs/en/memory)).

The review skill already names O(n^2) work, N+1 queries, and blocking I/O. But it says "Only flag if obviously problematic" (`llm-capabilities/skills/viv-review-pr/SKILL.template.md:95-96`).

A project detector is a new test policy. The engineering rule says to ask before a change to a repository policy (`llm-capabilities/rules/engineering.template.md:10`).

## Recommendations

### 1. Add specific rules

Add these items to `## Write code` in `llm-capabilities/rules/engineering.template.md`, after the bound rule:

```md
- Match the data structure to the access. If a loop looks up items by key or tests membership, build a set or a map one time before the loop.
- Keep queries and network calls out of loops over rows. Collect the keys first, and fetch the relation in one call (`select_related`, `includes`, `joinedload`, `selectinload`).
- When the project has a query-count test or an N+1 detector, add an assertion for each new code path that returns a list.
- Prove a claimed speedup with a measurement on an input large enough to show the complexity classes. Give the input sizes and the numbers.
```

Each item names a concrete pattern and the fix. The evidence supports specific statements over "be efficient". The last item answers the low rate of benchmark evidence in agent pull requests.

### 2. Make the review pass specific

In `llm-capabilities/skills/viv-review-pr/SKILL.template.md:95-96`, replace "Only flag if obviously problematic" with a list of patterns:

- a membership test or a search on a list inside a loop over input that the code does not control
- a query, an HTTP call, or a lazy relation access inside a loop over rows
- a query without a limit on a table that grows
- a sort or a copy inside a loop

Ask the reviewer to give the `file:line` and the input size that makes the pattern slow. Use the Warning level when the input has no bound in production.

Put the same list into the background file of `viv-ocr-review` when the change touches data access.

### 3. Add a detector in each project, with consent

For each project with an ORM, propose the matching setting from the table above. Treat it as a new test policy, and ask the user first.

A failing detector gives the agent execution feedback in the normal test loop. It works the same in each harness.

Do not add a regular-expression hook for "query in a loop" now. Its precision is unknown, and each harness needs its own adapter.

### 4. Measure before you keep the rule

Build a small fixture set of feature tasks with a hidden trap:

- join two lists by an id
- remove duplicates from a large list
- add a list endpoint that shows a related field
- add a report that loops over rows and reads a relation

Score each patch on separate properties:

- the query count for each request, with the detector or with `assertNumQueries`
- the runtime at two input sizes, for example 10^3 and 10^5, to see the growth rate
- the functional correctness with normal tests
- the review recall on diffs with a seeded trap

Compare the current rules, the new rules, and the new rules with the review pass. Keep the model, the effort, and the harness the same. Use repeated samples.

The new rules succeed if they lower the trap rate without a loss of correctness. EvalPerf shows that an efficiency prompt can reduce correctness, thus measure correctness separately.

## Gaps in the evidence

- No source measures the N+1 rate or the query count of code from models or agents.
- No source measures an efficiency rule in an instruction file.
- No source measures the effect of an N+1 detector on an agent loop.
- Most rates come from Python puzzles and older models. Rates for current frontier agents on feature code are not known.
- The review-pass evidence comes from a decoding-time critic, not from an agent review after the edit.
