local M = {}

local state = {
  args = {},
  buffer = nil,
  process = nil,
  run = 0,
  window = nil,
}

local function cancel_process()
  if not state.process then return end
  pcall(state.process.kill, state.process, 15)
  state.process = nil
end

local function window_config()
  local width = math.max(1, math.min(140, math.floor(vim.o.columns * 0.9)))
  local available_lines = vim.o.lines - vim.o.cmdheight
  local height = math.max(1, math.min(40, math.floor(available_lines * 0.8)))

  return {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((available_lines - height) / 2),
    border = 'rounded',
    title = ' LLM Usage ',
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
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines(text))
  vim.bo[buffer].modifiable = false
end

local function open_window()
  if state.window and vim.api.nvim_win_is_valid(state.window) then
    vim.api.nvim_set_current_win(state.window)
    return state.buffer
  end

  state.buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(state.buffer, 'llm-usage://report')
  vim.bo[state.buffer].bufhidden = 'wipe'
  vim.bo[state.buffer].filetype = 'text'
  vim.bo[state.buffer].swapfile = false

  state.window = vim.api.nvim_open_win(state.buffer, true, window_config())
  vim.wo[state.window].cursorline = true
  vim.wo[state.window].number = false
  vim.wo[state.window].relativenumber = false
  vim.wo[state.window].signcolumn = 'no'
  vim.wo[state.window].wrap = false

  vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = state.buffer, desc = 'Close LLM usage' })
  vim.keymap.set('n', 'r', function()
    M.open(state.args)
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

function M.open(args)
  cancel_process()
  state.args = vim.deepcopy(args or {})
  state.run = state.run + 1
  local run = state.run
  local buffer = open_window()

  set_lines(buffer, 'Loading LLM usage...')

  local command = { 'llm-usage' }
  vim.list_extend(command, state.args)
  table.insert(command, '--no-color')

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

      set_lines(buffer, output)
      if state.window and vim.api.nvim_win_is_valid(state.window) then
        vim.api.nvim_win_set_cursor(state.window, { 1, 0 })
      end
    end)
  end)
  state.process = process
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
end

return M
