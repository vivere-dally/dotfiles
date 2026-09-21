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
      return { 'python' }
    end,
    install = function()
      return task
    end,
    setup = function() end,
  })
  local textobject_options
  stub('nvim-treesitter-textobjects', {
    setup = function(options)
      textobject_options = options
    end,
  })
  stub('nvim-treesitter-textobjects.select', { select_textobject = function() end })
  stub('nvim-treesitter-textobjects.move', {
    goto_next_start = function() end,
    goto_previous_start = function() end,
    goto_next_end = function() end,
    goto_previous_end = function() end,
  })
  stub('nvim-treesitter-textobjects.swap', {
    swap_next = function() end,
    swap_previous = function() end,
  })
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
  local treesitter_start = vim.treesitter.start
  local treesitter_language_add = vim.treesitter.language.add
  local treesitter_query_get = vim.treesitter.query.get
  vim.lsp.enable = function(servers)
    enabled_lsp_servers = servers
  end
  vim.treesitter.start = function()
    return true
  end
  vim.treesitter.language.add = function()
    return true
  end
  vim.treesitter.query.get = function(_, query_name)
    if query_name == 'textobjects' then return { captures = { 'function.outer', 'class.outer' } } end
  end
  dofile(root .. '/.config/nvim/lua/plugins/lsp.lua')
  vim.lsp.enable = lsp_enable

  assert(mason_options.PATH == 'append', 'Mason must not override Homebrew tools')
  assert(not vim.list_contains(mason_lsp_options.ensure_installed, 'gopls'), 'Mason must not install gopls')
  assert(not vim.list_contains(mason_lsp_options.ensure_installed, 'templ'), 'Mason must not install templ')
  assert(vim.list_contains(enabled_lsp_servers, 'gopls'), 'gopls must be enabled')
  assert(vim.list_contains(enabled_lsp_servers, 'templ'), 'templ must be enabled')
  assert(not vim.list_contains(mason_tool_options.ensure_installed, 'goimports'), 'Mason must not install goimports')
  assert(textobject_options.select.lookahead, 'Tree-sitter text objects must search forward')
  assert(textobject_options.move.set_jumps, 'Tree-sitter motions must update the jump list')
  for _, lhs in ipairs({ 'af', 'if', 'ac', 'ic' }) do
    assert(vim.fn.maparg(lhs, 'o') ~= '', ('Tree-sitter text object %s is missing'):format(lhs))
  end
  for _, lhs in ipairs({ ']m', '[m', ']M', '[M', ']]', '[[', '][', '[]' }) do
    vim.keymap.set('n', lhs, '<nop>', { buffer = buffer, desc = 'Filetype motion' })
  end
  vim.bo[buffer].filetype = 'python'
  for _, lhs in ipairs({ ']m', '[m', ']M', '[M', ']]', '[[', '][', '[]' }) do
    local mapping = vim.fn.maparg(lhs, 'n', false, true)
    assert(mapping.buffer == 1, ('Tree-sitter motion %s must be buffer-local'):format(lhs))
    assert(mapping.desc ~= 'Filetype motion', ('Tree-sitter motion %s did not replace the filetype map'):format(lhs))
  end
  vim.treesitter.start = treesitter_start
  vim.treesitter.language.add = treesitter_language_add
  vim.treesitter.query.get = treesitter_query_get
  for _, lhs in ipairs({ '<leader>cn', '<leader>cp' }) do
    assert(vim.fn.maparg(lhs, 'n') ~= '', ('Tree-sitter parameter swap %s is missing'):format(lhs))
  end

  local grug_far_options
  stub('grug-far', {
    setup = function(options)
      grug_far_options = options
    end,
    open = function() end,
    with_visual_selection = function() end,
  })
  dofile(root .. '/.config/nvim/lua/plugins/search.lua')
  assert(type(grug_far_options) == 'table', 'Grug Far setup did not run')
  assert(vim.fn.maparg('<leader>rp', 'n') ~= '', 'project replace mapping is missing')
  assert(vim.fn.maparg('<leader>rp', 'x') ~= '', 'visual project replace mapping is missing')

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
  local overseer_options
  stub('overseer', {
    setup = function(options)
      overseer_options = options
    end,
  })
  dofile(root .. '/.config/nvim/lua/plugins/debug.lua')

  assert(overseer_options.dap, 'Overseer must connect project build tasks to nvim-dap')
  assert(vim.fn.maparg('<leader>U', 'n') ~= '', 'DAP View mapping is missing')
  assert(vim.fn.maparg('<leader>u', 'n') == '', 'old DAP View mapping still exists')

  local system = vim.system
  local processes = {}
  vim.system = function(command, options, callback)
    local process = { callback = callback, command = command, options = options }
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
  usage.dashboard('claude', 5)
  assert(vim.deep_equal(
    processes[3].command,
    { 'llm-usage', 'dashboard', 'claude', '5' }
  ), 'Claude usage dashboard command is incorrect')
  processes[3].callback({
    code = 0,
    stderr = '',
    stdout = vim.json.encode({
      generatedAt = '2026-09-21T16:00:00.000Z',
      generatedAtEpoch = 0,
      harness = 'claude',
      hours = 5,
      limits = {
        items = {
          { kind = 'session', label = 'Current 5-hour', resetsInSeconds = 3600, utilization = 42 },
        },
      },
      projects = {
        {
          models = {
            {
              model = 'claude-opus-5',
              percent = 100,
              reasoning = 'high',
              tokens = { cacheCreation = 10, cacheRead = 80, input = 1, output = 9, total = 100 },
            },
          },
          path = '/work/alpha',
          percent = 100,
          tokens = { cacheCreation = 10, cacheRead = 80, input = 1, output = 9, total = 100 },
        },
      },
      since = '2026-09-21T11:00:00.000Z',
      sinceEpoch = 0,
      totals = { cacheCreation = 10, cacheRead = 80, input = 1, output = 9, total = 100 },
    }),
  })
  vim.wait(1000, function()
    return vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, 1, false)[1] ~= 'Loading usage dashboard...'
  end)
  assert(
    vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, 1, false)[1] == 'Claude usage · last 5h',
    'Claude usage dashboard did not render'
  )
  vim.api.nvim_buf_delete(vim.api.nvim_get_current_buf(), { force = true })
  vim.system = system
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd('cquit 1')
end

print('Neovim smoke tests passed')
vim.cmd('qa!')
