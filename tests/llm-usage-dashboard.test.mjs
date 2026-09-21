import assert from 'node:assert/strict'
import { mkdtemp, mkdir, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'

import { collectClaudeUsage, parseClaudeLimits } from '../.local/lib/llm-usage/dashboard.mjs'

function entry({ id, request, timestamp, cwd, model, effort, usage }) {
  return JSON.stringify({
    type: 'assistant',
    requestId: request,
    timestamp,
    cwd,
    effort,
    message: { id, model, usage },
  })
}

test('groups Claude usage by project, model, and reasoning level', async () => {
  const root = await mkdtemp(join(tmpdir(), 'llm-usage-'))
  const session = join(root, 'project', 'session', 'subagents')
  await mkdir(session, { recursive: true })
  const nowMs = Date.now()
  const recent = new Date(nowMs - 60_000).toISOString()
  const old = new Date(nowMs - 6 * 60 * 60 * 1000).toISOString()
  const opus = entry({
    id: 'message-opus',
    request: 'request-opus',
    timestamp: recent,
    cwd: '/work/alpha',
    model: 'claude-opus-5',
    effort: 'high',
    usage: { input_tokens: 2, cache_creation_input_tokens: 3, cache_read_input_tokens: 100, output_tokens: 5 },
  })
  const fable = entry({
    id: 'message-fable',
    request: 'request-fable',
    timestamp: recent,
    cwd: '/work/alpha',
    model: 'claude-fable-5-1',
    effort: 'xhigh',
    usage: { input_tokens: 1, cache_creation_input_tokens: 4, cache_read_input_tokens: 40, output_tokens: 10 },
  })
  const excluded = entry({
    id: 'message-old',
    request: 'request-old',
    timestamp: old,
    cwd: '/work/beta',
    model: 'claude-opus-5',
    effort: 'medium',
    usage: { input_tokens: 100, output_tokens: 100 },
  })
  await writeFile(join(session, 'agent.jsonl'), `${opus}\n${opus}\n${fable}\n${excluded}\n`)

  const report = await collectClaudeUsage({
    projectsDir: root,
    sinceMs: nowMs - 5 * 60 * 60 * 1000,
    untilMs: nowMs,
  })

  assert.equal(report.projects.length, 1)
  assert.equal(report.projects[0].path, '/work/alpha')
  assert.deepEqual(report.projects[0].models.map(({ model, reasoning }) => [model, reasoning]), [
    ['claude-opus-5', 'high'],
    ['claude-fable-5-1', 'xhigh'],
  ])
  assert.deepEqual(report.totals, {
    input: 3,
    cacheCreation: 7,
    cacheRead: 140,
    output: 15,
    total: 165,
  })
})

test('reads current and model-specific limit windows', () => {
  const limits = parseClaudeLimits({
    limits: [
      { kind: 'session', percent: 42, resets_at: '2026-09-21T17:00:00Z' },
      { kind: 'weekly_all', percent: 31, resets_at: '2026-09-25T17:00:00Z' },
      {
        kind: 'weekly_scoped',
        percent: 73,
        resets_at: '2026-09-25T17:00:00Z',
        scope: { model: { display_name: 'Fable' } },
      },
    ],
  })

  assert.deepEqual(limits.map(({ label, utilization }) => [label, utilization]), [
    ['Current 5-hour', 42],
    ['Weekly all', 31],
    ['Weekly Fable', 73],
  ])
})
