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
  local gruvbox_options
  stub('gruvbox', {
    palette = { bright_orange = '#fe8019' },
    setup = function(options)
      gruvbox_options = options
    end,
  })
  stub('conform', { format = function() end, setup = function() end })
  stub('lint', lint)
  local mason_options, mason_lsp_options, mason_tool_options
  stub('mason', {
    setup = function(options)
      mason_options = options
    end,
  })
  stub('mason-lspconfig', {
    setup = function(options)
      mason_lsp_options = options
    end,
  })
  stub('mason-tool-installer', {
    setup = function(options)
      mason_tool_options = options
    end,
  })
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

  local colors_dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'site', 'colors')
  vim.fn.mkdir(colors_dir, 'p')
  vim.fn.writefile({}, vim.fs.joinpath(colors_dir, 'gruvbox.vim'))
  vim.opt.runtimepath:append(vim.fs.dirname(colors_dir))
  dofile(root .. '/.config/nvim/lua/plugins/colors.lua')
  for name, enabled in pairs(gruvbox_options.italic) do
    assert(not enabled, ('Gruvbox italic option %s must be disabled'):format(name))
  end
  assert(gruvbox_options.overrides.Comment.fg == '#fe8019', 'comments must use bright orange')
  for name, highlight in pairs(gruvbox_options.overrides) do
    assert(not highlight.italic, ('highlight %s must not use italics'):format(name))
  end

  local lsp_enable = vim.lsp.enable
  local enabled_lsp_servers
  vim.lsp.enable = function(servers)
    enabled_lsp_servers = servers
  end
  dofile(root .. '/.config/nvim/lua/plugins/lsp.lua')
  vim.lsp.enable = lsp_enable

  assert(mason_options.PATH == 'append', 'Mason must not override Homebrew tools')
  assert(not vim.list_contains(mason_lsp_options.ensure_installed, 'gopls'), 'Mason must not install gopls')
  assert(not vim.list_contains(mason_lsp_options.ensure_installed, 'templ'), 'Mason must not install templ')
  assert(vim.list_contains(enabled_lsp_servers, 'gopls'), 'gopls must be enabled')
  assert(vim.list_contains(enabled_lsp_servers, 'templ'), 'templ must be enabled')
  assert(not vim.list_contains(mason_tool_options.ensure_installed, 'goimports'), 'Mason must not install goimports')

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
