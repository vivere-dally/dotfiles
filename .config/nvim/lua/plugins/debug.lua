local pack = require('pack')
local gh = pack.gh

pack.add({
  gh('mfussenegger/nvim-dap'),
  {
    src = gh('igorlfs/nvim-dap-view'),
    version = vim.version.range('1.*'),
  },
  gh('leoluz/nvim-dap-go'),
  gh('mfussenegger/nvim-dap-python'),
  gh('stevearc/overseer.nvim'),
})

local dap = require('dap')
local view = require('dap-view')

view.setup({
  -- Debugging is infrequent, so keep the editor layout unchanged until asked.
  auto_toggle = false,
  virtual_text = { enabled = false },
})
require('dap-go').setup()
require('dap-python').setup('uv')

-- Project launch files use preLaunchTask, which nvim-dap does not run itself.
require('overseer').setup({ dap = true })

-- C/C++ debugging via codelldb (installed by Mason)
local codelldb_path = vim.fn.stdpath('data') .. '/mason/packages/codelldb/extension/adapter/codelldb'

dap.adapters.codelldb = {
  type = 'server',
  port = '${port}',
  executable = {
    command = codelldb_path,
    args = { '--port', '${port}' },
  },
}

local function prompt_executable()
  return coroutine.create(function(dap_run_co)
    vim.ui.input({ prompt = 'Path to executable: ', default = vim.fn.getcwd() .. '/' }, function(input)
      coroutine.resume(dap_run_co, input)
    end)
  end)
end

-- DAP wants argv as a list, so split the single input line on whitespace.
local function prompt_args(default)
  return function()
    return coroutine.create(function(dap_run_co)
      vim.ui.input({ prompt = 'Args: ', default = default or '' }, function(input)
        coroutine.resume(dap_run_co, vim.split(input or '', '%s+', { trimempty = true }))
      end)
    end)
  end
end

local c_configurations = {
  {
    name = 'Launch',
    type = 'codelldb',
    request = 'launch',
    program = prompt_executable,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = 'Launch (with args)',
    type = 'codelldb',
    request = 'launch',
    program = prompt_executable,
    args = prompt_args(),
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = 'Attach to process',
    type = 'codelldb',
    request = 'attach',
    pid = require('dap.utils').pick_process,
    cwd = '${workspaceFolder}',
  },
}

dap.configurations.c = c_configurations
dap.configurations.cpp = c_configurations
dap.configurations.zig = c_configurations

vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'dap breakpoint' })
-- F6 sits with the other F-key debug maps; <leader>gb is the git branch picker.
vim.keymap.set('n', '<F6>', dap.run_to_cursor, { desc = 'dap run to cursor' })

vim.keymap.set('n', '<leader>?', function()
  view.hover(nil, true)
end, { desc = 'dap value under cursor' })

vim.keymap.set('n', '<F5>', dap.continue, { desc = 'dap continue' })
vim.keymap.set('n', '<F7>', dap.step_into, { desc = 'dap step into' })
vim.keymap.set('n', '<F8>', dap.step_over, { desc = 'dap step over' })
vim.keymap.set('n', '<F9>', dap.step_out, { desc = 'dap step out' })
vim.keymap.set('n', '<F10>', dap.step_back, { desc = 'dap step back' })
vim.keymap.set('n', '<F11>', dap.restart, { desc = 'dap restart' })

vim.keymap.set('n', '<leader>U', function()
  view.toggle(true)
end, { desc = 'toggle debugger ui' })
