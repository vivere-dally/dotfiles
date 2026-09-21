#!/usr/bin/env node

import { createHash } from 'node:crypto'
import { execFileSync } from 'node:child_process'
import { createReadStream, realpathSync } from 'node:fs'
import { mkdir, opendir, readFile, stat, writeFile } from 'node:fs/promises'
import { homedir } from 'node:os'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import readline from 'node:readline'

const FILE_BATCH_SIZE = 8
const LIMIT_CACHE_MS = 60_000
const MAX_SCAN_DEPTH = 6
const MAX_HOURS = 24 * 365

function emptyTokens() {
  return {
    input: 0,
    cacheCreation: 0,
    cacheRead: 0,
    output: 0,
    total: 0,
  }
}

function addTokens(target, source) {
  target.input += source.input
  target.cacheCreation += source.cacheCreation
  target.cacheRead += source.cacheRead
  target.output += source.output
  target.total += source.total
}

function tokenValue(value) {
  return Number.isFinite(value) && value > 0 ? value : 0
}

function usageTokens(usage) {
  const tokens = {
    input: tokenValue(usage.input_tokens),
    cacheCreation: tokenValue(usage.cache_creation_input_tokens),
    cacheRead: tokenValue(usage.cache_read_input_tokens),
    output: tokenValue(usage.output_tokens),
  }
  tokens.total = tokens.input + tokens.cacheCreation + tokens.cacheRead + tokens.output
  return tokens
}

async function* jsonlFiles(root, sinceMs, depth = 0) {
  if (depth > MAX_SCAN_DEPTH) return

  let directory
  try {
    directory = await opendir(root)
  } catch (error) {
    if (error.code === 'ENOENT') return
    throw error
  }

  const directories = []
  const files = []
  for await (const entry of directory) {
    const path = join(root, entry.name)
    if (entry.isDirectory()) {
      directories.push(path)
    } else if (entry.isFile() && entry.name.endsWith('.jsonl')) {
      files.push(path)
    }
  }

  directories.sort()
  files.sort()

  // Claude repeats some subagent turns in the parent transcript. Reading
  // directories first attributes those turns to the transcript that made them.
  for (const path of directories) {
    yield* jsonlFiles(path, sinceMs, depth + 1)
  }
  for (const path of files) {
    const metadata = await stat(path)
    if (metadata.mtimeMs >= sinceMs) yield path
  }
}

async function readUsageRecords(path, sinceMs, untilMs) {
  const records = []
  const seen = new Set()
  let lineNumber = 0
  const input = createReadStream(path, { encoding: 'utf8' })
  const lines = readline.createInterface({ input, crlfDelay: Infinity })

  for await (const line of lines) {
    lineNumber += 1
    let entry
    try {
      entry = JSON.parse(line)
    } catch {
      continue
    }

    const usage = entry?.message?.usage
    const model = entry?.message?.model
    const timestamp = Date.parse(entry?.timestamp ?? '')
    if (!usage || !model || model === '<synthetic>' || !Number.isFinite(timestamp)) continue
    if (timestamp < sinceMs || timestamp > untilMs) continue

    const messageId = entry.message.id
    const requestId = entry.requestId
    // Claude writes the same response after each streamed content block.
    const key = messageId && requestId ? `${messageId}:${requestId}` : `${path}:${lineNumber}`
    if (seen.has(key)) continue
    seen.add(key)

    const tokens = usageTokens(usage)
    if (tokens.total === 0) continue
    records.push({
      key,
      model,
      project: entry.cwd || '(unknown project)',
      reasoning: entry.perTurnEffort || entry.effort || 'default',
      tokens,
    })
  }

  return records
}

function finalizeUsage(projectsByPath, totals) {
  const projects = [...projectsByPath.values()].map((project) => {
    const models = [...project.models.values()]
      .map((model) => ({
        ...model,
        percent: project.tokens.total === 0 ? 0 : (model.tokens.total / project.tokens.total) * 100,
      }))
      .sort((left, right) => right.tokens.total - left.tokens.total)
    return {
      path: project.path,
      tokens: project.tokens,
      percent: totals.total === 0 ? 0 : (project.tokens.total / totals.total) * 100,
      models,
    }
  })
  projects.sort((left, right) => right.tokens.total - left.tokens.total)
  return projects
}

export async function collectClaudeUsage({ projectsDir, sinceMs, untilMs }) {
  const totals = emptyTokens()
  const projectsByPath = new Map()
  const seen = new Set()
  let batch = []

  const mergeBatch = async () => {
    const recordSets = await Promise.all(batch.map((path) => readUsageRecords(path, sinceMs, untilMs)))
    for (const records of recordSets) {
      for (const record of records) {
        if (seen.has(record.key)) continue
        seen.add(record.key)

        let project = projectsByPath.get(record.project)
        if (!project) {
          project = { path: record.project, tokens: emptyTokens(), models: new Map() }
          projectsByPath.set(record.project, project)
        }
        const modelKey = `${record.model}\0${record.reasoning}`
        let model = project.models.get(modelKey)
        if (!model) {
          model = { model: record.model, reasoning: record.reasoning, tokens: emptyTokens() }
          project.models.set(modelKey, model)
        }

        addTokens(totals, record.tokens)
        addTokens(project.tokens, record.tokens)
        addTokens(model.tokens, record.tokens)
      }
    }
    batch = []
  }

  // A fixed-width batch keeps disk throughput without retaining every transcript.
  for await (const path of jsonlFiles(projectsDir, sinceMs)) {
    batch.push(path)
    if (batch.length === FILE_BATCH_SIZE) await mergeBatch()
  }
  if (batch.length > 0) await mergeBatch()

  return { totals, projects: finalizeUsage(projectsByPath, totals) }
}

function credentialFromJson(raw) {
  try {
    const parsed = JSON.parse(raw)
    return parsed?.claudeAiOauth?.accessToken || null
  } catch {
    return null
  }
}

function keychainSecret(service) {
  try {
    return execFileSync('security', ['find-generic-password', '-s', service, '-w'], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim()
  } catch {
    return null
  }
}

function keychainServices() {
  try {
    const dump = execFileSync('security', ['dump-keychain'], {
      encoding: 'utf8',
      maxBuffer: 8 * 1024 * 1024,
      stdio: ['ignore', 'pipe', 'ignore'],
    })
    return [...new Set([...dump.matchAll(/"svce"<blob>="(Claude Code-credentials-[^"]+)"/g)].map((match) => match[1]))]
  } catch {
    return []
  }
}

async function claudeToken(configDir) {
  if (process.platform === 'darwin') {
    const rawConfigDir = process.env.CLAUDE_SECURESTORAGE_CONFIG_DIR ?? process.env.CLAUDE_CONFIG_DIR ?? ''
    const services = rawConfigDir
      ? [`Claude Code-credentials-${createHash('sha256').update(rawConfigDir.normalize('NFC')).digest('hex').slice(0, 8)}`]
      : ['Claude Code-credentials', ...keychainServices()]
    for (const service of services) {
      const secret = keychainSecret(service)
      const token = secret && credentialFromJson(secret)
      if (token) return token
    }
  }

  try {
    return credentialFromJson(await readFile(join(configDir, '.credentials.json'), 'utf8'))
  } catch {
    return null
  }
}

function titleCase(value) {
  return value.replaceAll('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase())
}

function limitItem(kind, label, bucket) {
  const utilization = bucket?.percent ?? bucket?.utilization
  if (!Number.isFinite(utilization)) return null
  return {
    kind,
    label,
    utilization,
    resetsAt: bucket?.resets_at || null,
  }
}

export function parseClaudeLimits(response) {
  const items = []
  const keys = new Set()
  const add = (item) => {
    if (!item || keys.has(item.kind)) return
    keys.add(item.kind)
    items.push(item)
  }

  if (Array.isArray(response?.limits)) {
    for (const limit of response.limits) {
      const model = limit?.scope?.model?.display_name
      if (!model && (limit?.percent ?? 0) === 0 && !limit?.resets_at) continue
      const label = limit.kind === 'session'
        ? 'Current 5-hour'
        : limit.kind === 'weekly_all'
          ? 'Weekly all'
          : limit.kind === 'weekly_scoped' && model
            ? `Weekly ${model}`
            : titleCase(limit.kind || 'usage')
      const kind = limit.kind === 'weekly_scoped' && model ? `weekly_${model.toLowerCase()}` : limit.kind
      add(limitItem(kind, label, limit))
    }
  }

  add(limitItem('session', 'Current 5-hour', response?.five_hour))
  add(limitItem('weekly_all', 'Weekly all', response?.seven_day))
  for (const [name, bucket] of Object.entries(response || {})) {
    const match = /^seven_day_(.+)$/.exec(name)
    if (match) add(limitItem(`weekly_${match[1]}`, `Weekly ${titleCase(match[1])}`, bucket))
  }

  const order = { session: 0, weekly_all: 1 }
  items.sort((left, right) => (order[left.kind] ?? 2) - (order[right.kind] ?? 2) || left.label.localeCompare(right.label))
  return items
}

function limitCachePath() {
  const root = process.env.XDG_CACHE_HOME || join(homedir(), '.cache')
  return join(root, 'llm-usage', 'claude-limits.json')
}

async function cachedLimits(path, tokenHash, nowMs) {
  try {
    const cached = JSON.parse(await readFile(path, 'utf8'))
    if (cached.tokenHash !== tokenHash || nowMs - cached.fetchedAt >= LIMIT_CACHE_MS) return null
    return cached.items
  } catch {
    return null
  }
}

async function writeLimitCache(path, tokenHash, nowMs, items) {
  try {
    await mkdir(dirname(path), { recursive: true })
    await writeFile(path, JSON.stringify({ tokenHash, fetchedAt: nowMs, items }), { mode: 0o600 })
  } catch {
    // Limit data remains available for this render when the cache is read-only.
  }
}

async function fetchClaudeLimits(configDir, nowMs) {
  const token = await claudeToken(configDir)
  if (!token) return { items: [], error: 'Claude Code OAuth login not found; run claude /login to show account limits.' }

  const tokenHash = createHash('sha256').update(token).digest('hex').slice(0, 16)
  const cachePath = limitCachePath()
  const cached = await cachedLimits(cachePath, tokenHash, nowMs)
  if (cached) return { items: cached, error: null }

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 5_000)
  try {
    // Refuse redirects so the OAuth token can only reach Anthropic's fixed host.
    const response = await fetch('https://api.anthropic.com/api/oauth/usage', {
      headers: {
        Authorization: `Bearer ${token}`,
        'anthropic-beta': 'oauth-2025-04-20',
      },
      redirect: 'error',
      signal: controller.signal,
    })
    if (!response.ok) return { items: [], error: `Anthropic usage request failed with HTTP ${response.status}.` }
    const items = parseClaudeLimits(await response.json())
    if (items.length === 0) return { items, error: 'Anthropic returned no account limit windows.' }
    await writeLimitCache(cachePath, tokenHash, nowMs, items)
    return { items, error: null }
  } catch (error) {
    const reason = error.name === 'AbortError' ? 'timed out' : 'failed'
    return { items: [], error: `Anthropic usage request ${reason}.` }
  } finally {
    clearTimeout(timeout)
  }
}

function parseArguments(arguments_) {
  let harness = 'claude'
  let hours = 5
  if (arguments_[0]) {
    const firstNumber = Number(arguments_[0])
    if (Number.isFinite(firstNumber)) hours = firstNumber
    else harness = arguments_[0]
  }
  if (arguments_[1]) hours = Number(arguments_[1])
  if (harness !== 'claude') throw new Error(`The ${harness} dashboard provider is not available yet.`)
  if (!Number.isFinite(hours) || hours <= 0 || hours > MAX_HOURS) {
    throw new Error(`Hours must be greater than 0 and no greater than ${MAX_HOURS}.`)
  }
  return { harness, hours }
}

async function main() {
  const { harness, hours } = parseArguments(process.argv.slice(2))
  const nowMs = Date.now()
  const sinceMs = nowMs - hours * 60 * 60 * 1000
  const configDir = process.env.CLAUDE_CONFIG_DIR || join(homedir(), '.claude')
  const [usage, limits] = await Promise.all([
    collectClaudeUsage({ projectsDir: join(configDir, 'projects'), sinceMs, untilMs: nowMs }),
    fetchClaudeLimits(configDir, nowMs),
  ])
  limits.items = limits.items.map((item) => ({
    ...item,
    resetsInSeconds: item.resetsAt ? Math.max(0, Math.floor((Date.parse(item.resetsAt) - nowMs) / 1000)) : null,
  }))
  process.stdout.write(JSON.stringify({
    harness,
    hours,
    generatedAt: new Date(nowMs).toISOString(),
    generatedAtEpoch: Math.floor(nowMs / 1000),
    since: new Date(sinceMs).toISOString(),
    sinceEpoch: Math.floor(sinceMs / 1000),
    limits,
    ...usage,
  }))
}

if (process.argv[1] && fileURLToPath(import.meta.url) === realpathSync(process.argv[1])) {
  main().catch((error) => {
    process.stderr.write(`llm-usage dashboard: ${error.message}\n`)
    process.exitCode = 1
  })
}
