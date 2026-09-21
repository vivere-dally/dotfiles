local M = {}
local namespace = vim.api.nvim_create_namespace('llm_usage')

local state = {
  args = {},
  buffer = nil,
  refresh = nil,
  process = nil,
  run = 0,
  window = nil,
}

local function cancel_process()
  if not state.process then return end
  pcall(state.process.kill, state.process, 15)
  state.process = nil
end

local function window_config(title)
  local width = math.max(1, math.min(150, math.floor(vim.o.columns * 0.9)))
  local available_lines = vim.o.lines - vim.o.cmdheight
  local height = math.max(1, math.min(40, math.floor(available_lines * 0.8)))

  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((available_lines - height) / 2),
    border = 'rounded',
    title = (' %s '):format(title),
    title_pos = 'center',
    style = 'minimal',
  }
end

local function lines(text)
  text = text:gsub('\r\n', '\n'):gsub('\n$', '')
  if text == '' then return { '(no output)' } end
  return vim.split(text, '\n', { plain = true })
end

local function set_lines(buffer, text)
  if not vim.api.nvim_buf_is_valid(buffer) then return end
  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines(text))
  vim.bo[buffer].modifiable = false
end

local function open_window(title)
  if state.window and vim.api.nvim_win_is_valid(state.window) then
    vim.api.nvim_win_set_config(state.window, { title = (' %s '):format(title), title_pos = 'center' })
    vim.api.nvim_set_current_win(state.window)
    return state.buffer
  end

  state.buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buffer, 'llm-usage://report')
  vim.bo[state.buffer].bufhidden = 'wipe'
  vim.bo[state.buffer].filetype = 'text'
  vim.bo[state.buffer].swapfile = false

  state.window = vim.api.nvim_open_win(state.buffer, true, window_config(title))
  vim.wo[state.window].cursorline = true
  vim.wo[state.window].number = false
  vim.wo[state.window].relativenumber = false
  vim.wo[state.window].signcolumn = 'no'
  vim.wo[state.window].wrap = false

  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = state.buffer, desc = 'Close LLM usage' })
  vim.keymap.set('n', 'r', function()
    if state.refresh then state.refresh() end
  end, { buffer = state.buffer, desc = 'Refresh LLM usage' })

  local buffer = state.buffer
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buffer,
    once = true,
    callback = function()
      if state.buffer ~= buffer then return end
      state.run = state.run + 1
      cancel_process()
      state.buffer = nil
      state.window = nil
    end,
  })

  return state.buffer
end

local function format_tokens(value)
  if value >= 1000000000 then return ('%.1fB'):format(value / 1000000000) end
  if value >= 1000000 then return ('%.1fM'):format(value / 1000000) end
  if value >= 1000 then return ('%.1fK'):format(value / 1000) end
  return tostring(value)
end

local function bar(percent, width)
  local filled = math.floor(math.max(0, math.min(100, percent)) * width / 100 + 0.5)
  return ('█'):rep(filled) .. ('░'):rep(width - filled)
end

local function duration(seconds)
  if not seconds then return 'reset time unavailable' end
  local days = math.floor(seconds / 86400)
  local hours = math.floor((seconds % 86400) / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  if days > 0 then return ('resets in %dd %dh'):format(days, hours) end
  if hours > 0 then return ('resets in %dh %dm'):format(hours, minutes) end
  return ('resets in %dm'):format(minutes)
end

local function usage_highlight(percent)
  if percent >= 80 then return 'DiagnosticError' end
  if percent >= 50 then return 'DiagnosticWarn' end
  return 'DiagnosticOk'
end

local function set_dashboard(buffer, report)
  if not vim.api.nvim_buf_is_valid(buffer) then return end
  local output = {}
  local highlights = {}
  local function add(text, highlight)
    table.insert(output, text)
    if highlight then table.insert(highlights, { line = #output - 1, group = highlight }) end
  end

  local harness_name = report.harness:gsub('^%l', string.upper)
  add(('%s usage · last %sh'):format(harness_name, report.hours), 'Title')
  add(('Local window: %s → %s'):format(
    os.date('%Y-%m-%d %H:%M', report.sinceEpoch),
    os.date('%Y-%m-%d %H:%M', report.generatedAtEpoch)
  ), 'Comment')
  add('')
  add('ACCOUNT LIMITS', 'Special')
  if report.limits.error then
    add(report.limits.error, 'DiagnosticWarn')
  else
    for _, limit in ipairs(report.limits.items) do
      add(('%-22s %s %6.1f%%  %s'):format(
        limit.label,
        bar(limit.utilization, 28),
        limit.utilization,
        duration(limit.resetsInSeconds)
      ), usage_highlight(limit.utilization))
    end
  end

  add('')
  add('LOCAL ACTIVITY', 'Special')
  local totals = report.totals
  local cache_percent = totals.total == 0 and 0 or totals.cacheRead / totals.total * 100
  add(('%s tokens · %.1f%% cache reads · %s cache writes · %s output'):format(
    format_tokens(totals.total),
    cache_percent,
    format_tokens(totals.cacheCreation),
    format_tokens(totals.output)
  ))
  add('Account bars come from Anthropic. Project bars show local token share; quota attribution is approximate.', 'Comment')

  if #report.projects == 0 then
    add('')
    add('No Claude activity exists in this window.', 'Comment')
  end

  for _, project in ipairs(report.projects) do
    add('')
    add(project.path, 'Directory')
    add(('%s %6.1f%%  %s'):format(bar(project.percent, 34), project.percent, format_tokens(project.tokens.total)), 'Number')
    for _, model in ipairs(project.models) do
      add(('  %-24s reasoning %-7s %6.1f%%  %s'):format(
        model.model,
        model.reasoning,
        model.percent,
        format_tokens(model.tokens.total)
      ), 'Identifier')
      add(('    read %s · cache %s · output %s · input %s'):format(
        format_tokens(model.tokens.cacheRead),
        format_tokens(model.tokens.cacheCreation),
        format_tokens(model.tokens.output),
        format_tokens(model.tokens.input)
      ), 'Comment')
    end
  end

  add('')
  add('r refresh · q close', 'Comment')

  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, output)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buffer, namespace, highlight.group, highlight.line, 0, -1)
  end
  vim.bo[buffer].modifiable = false
end

local function execute(command, title, loading, on_success)
  cancel_process()
  state.run = state.run + 1
  local run = state.run
  local buffer = open_window(title)

  set_lines(buffer, loading)

  local process
  process = vim.system(command, { text = true, timeout = 60000 }, function(result)
    vim.schedule(function()
      if state.process == process then state.process = nil end
      if run ~= state.run or not vim.api.nvim_buf_is_valid(buffer) then return end

      local output = result.stdout or ''
      local stderr = result.stderr or ''
      if result.code ~= 0 then
        output = ('Command failed with exit code %d.\n\n%s'):format(result.code, stderr ~= '' and stderr or output)
      elseif stderr ~= '' then
        output = output .. '\n\n' .. stderr
      end

      if result.code == 0 then on_success(buffer, output) else set_lines(buffer, output) end
      if state.window and vim.api.nvim_win_is_valid(state.window) then
        vim.api.nvim_win_set_cursor(state.window, { 1, 0 })
      end
    end)
  end)
  state.process = process
end

function M.open(args)
  state.args = vim.deepcopy(args or {})
  state.refresh = function() M.open(state.args) end
  if state.buffer and vim.api.nvim_buf_is_valid(state.buffer) then vim.bo[state.buffer].filetype = 'text' end
  local command = { 'llm-usage' }
  vim.list_extend(command, state.args)
  table.insert(command, '--no-color')
  execute(command, 'LLM Usage', 'Loading LLM usage...', set_lines)
end

function M.dashboard(harness, hours)
  harness = harness or 'claude'
  hours = hours or 5
  if type(hours) ~= 'number' then
    vim.notify('The usage dashboard hours must be a number.', vim.log.levels.ERROR)
    return
  end
  state.refresh = function() M.dashboard(harness, hours) end
  local title = ('%s Usage · %sh'):format(harness:gsub('^%l', string.upper), hours)
  execute({ 'llm-usage', 'dashboard', harness, tostring(hours) }, title, 'Loading usage dashboard...', function(buffer, output)
    local ok, report = pcall(vim.json.decode, output)
    if not ok then
      set_lines(buffer, 'The usage dashboard returned invalid JSON.\n\n' .. output)
      return
    end
    vim.bo[buffer].filetype = 'llmusage'
    set_dashboard(buffer, report)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command('LlmUsage', function(command)
    M.open(command.fargs)
  end, {
    nargs = '*',
    desc = 'Show local LLM harness usage',
    complete = function()
      return { 'daily', 'weekly', 'monthly', 'session', 'blocks', 'claude', 'codex', 'opencode', 'pi' }
    end,
  })

  vim.api.nvim_create_user_command('LlmUsageDashboard', function(command)
    local harness = 'claude'
    local hours = 5
    if command.fargs[1] then
      if tonumber(command.fargs[1]) then hours = tonumber(command.fargs[1])
      else harness = command.fargs[1] end
    end
    if command.fargs[2] then hours = tonumber(command.fargs[2]) end
    M.dashboard(harness, hours)
  end, {
    nargs = '*',
    desc = 'Show the LLM usage dashboard for a recent window',
    complete = function() return { 'claude' } end,
  })
end

return M
