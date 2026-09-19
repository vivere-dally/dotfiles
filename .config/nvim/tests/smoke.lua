local root = assert(vim.env.NVIM_TEST_ROOT, 'NVIM_TEST_ROOT is not set')
vim.g.mapleader = ' '

local function stub(name, value)
  package.loaded[name] = nil
  package.preload[name] = function()
    return value
  end
end

local function assert_buffer_map(lhs)
  local mapping = vim.fn.maparg(lhs, 'n', false, true)
  assert(mapping.buffer == 1, ('expected %s to be buffer-local'):format(lhs))
end

local function run()
  assert(vim.version.ge(vim.version(), { 0, 12, 0 }), 'Neovim 0.12 or newer is required')

  dofile(root .. '/.config/nvim/lua/core/autocmds.lua')

  local buffer = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buffer)
  vim.bo[buffer].filetype = 'help'
  assert_buffer_map('q')

  local lint = { try_lint = function() end }
  local task = {
    await = function(_, callback)
      callback(nil)
    end,
    wait = function()
      return true
    end,
  }
  stub('pack', {
    add = function() end,
    gh = function(repo)
      return repo
    end,
    keys = function() end,
  })
  stub('conform', { format = function() end, setup = function() end })
  stub('lint', lint)
  stub('mason', { setup = function() end })
  stub('mason-lspconfig', { setup = function() end })
  stub('mason-tool-installer', { setup = function() end })
  stub('mini.pairs', { setup = function() end })
  stub('nvim-ts-autotag', { setup = function() end })
  stub('nvim-treesitter', {
    get_available = function()
      return {}
    end,
    install = function()
      return task
    end,
    setup = function() end,
  })
  stub('nvim-treesitter-textobjects', { setup = function() end })
  stub('trouble', { setup = function() end })

  local lsp_enable = vim.lsp.enable
  vim.lsp.enable = function() end
  dofile(root .. '/.config/nvim/lua/plugins/lsp.lua')
  vim.lsp.enable = lsp_enable

  vim.api.nvim_exec_autocmds('LspAttach', {
    buffer = buffer,
    data = { client_id = 0 },
    group = 'UserLspConfig',
    modeline = false,
  })
  for _, lhs in ipairs({ 'K', 'gd', 'gD', 'gi', 'gs', '<F2>', '<F3>', '<F4>', 'gl' }) do
    assert_buffer_map(lhs)
  end
  assert(vim.deep_equal(lint.linters_by_ft.python, { 'bandit' }), 'Python linting must use Bandit without Ruff')

  dofile(root .. '/.config/nvim/lua/plugins/git.lua')
  vim.bo[buffer].filetype = 'fugitive'
  vim.api.nvim_exec_autocmds('BufWinEnter', {
    buffer = buffer,
    group = 'vivere-dally_fugitive',
    modeline = false,
  })
  assert_buffer_map('cc')

  local dap = {
    adapters = {},
    configurations = {},
    continue = function() end,
    restart = function() end,
    run_to_cursor = function() end,
    step_back = function() end,
    step_into = function() end,
    step_out = function() end,
    step_over = function() end,
    toggle_breakpoint = function() end,
  }
  stub('dap', dap)
  stub('dap.utils', { pick_process = function() end })
  stub('dap-go', { setup = function() end })
  stub('dap-python', { setup = function() end })
  stub('dap-view', {
    hover = function() end,
    setup = function() end,
    toggle = function() end,
  })
  dofile(root .. '/.config/nvim/lua/plugins/debug.lua')

  assert(vim.fn.maparg('<leader>U', 'n') ~= '', 'DAP View mapping is missing')
  assert(vim.fn.maparg('<leader>u', 'n') == '', 'old DAP View mapping still exists')

  local system = vim.system
  local processes = {}
  vim.system = function(_, options)
    local process = { options = options }
    function process:kill(signal)
      self.signal = signal
    end
    table.insert(processes, process)
    return process
  end

  local usage = dofile(root .. '/.config/nvim/lua/core/llm_usage.lua')
  usage.open({ 'daily' })
  assert(processes[1].options.timeout == 60000, 'LLM usage command timeout is missing')
  usage.open({ 'weekly' })
  assert(processes[1].signal == 15, 'refresh did not stop the previous LLM usage command')
  vim.api.nvim_buf_delete(vim.api.nvim_get_current_buf(), { force = true })
  assert(processes[2].signal == 15, 'closing the report did not stop the LLM usage command')
  vim.system = system
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end

print('Neovim smoke tests passed')
vim.cmd('qa!')
