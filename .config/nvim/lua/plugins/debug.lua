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
})

local dap = require('dap')
local view = require('dap-view')

view.setup({
  -- Debugging is infrequent, so keep the editor layout unchanged until asked.
  auto_toggle = false,
  virtual_text = { enabled = false },
})
require('dap-go').setup({
  -- Additional dap configurations can be added.
  -- dap_configurations accepts a list of tables where each entry
  -- represents a dap configuration. For more details do:
  -- :help dap-configuration
  dap_configurations = {
    {
      -- Must be "go" or it will be ignored by the plugin
      type = 'go',
      name = 'Panomics Webserver',
      outputMode = 'remote',
      request = 'launch',
      program = '${workspaceFolder}',
      -- program = '${file}',
      buildFlags = { '-tags=dev' },
    },
    {
      -- Must be "go" or it will be ignored by the plugin
      type = 'go',
      name = 'Nexus',
      outputMode = 'remote',
      request = 'launch',
      program = '${workspaceFolder}/cmd/nexus',
      -- program = '${file}',
      -- buildFlags = { '-tags=dev' },
    },
  },
  -- delve configurations
  -- delve = {
  --   -- the path to the executable dlv which will be used for debugging.
  --   -- by default, this is the "dlv" executable on your PATH.
  --   path = 'dlv',
  --   -- time to wait for delve to initialize the debug session.
  --   -- default to 20 seconds
  --   initialize_timeout_sec = 20,
  --   -- a string that defines the port to start delve debugger.
  --   -- default to string "${port}" which instructs nvim-dap
  --   -- to start the process in a random available port.
  --   -- if you set a port in your debug configuration, its value will be
  --   -- assigned dynamically.
  --   port = '${port}',
  --   -- additional args to pass to dlv
  --   args = {},
  --   -- the build flags that are passed to delve.
  --   -- defaults to empty string, but can be used to provide flags
  --   -- such as "-tags=unit" to make sure the test suite is
  --   -- compiled during debugging, for example.
  --   -- passing build flags using args is ineffective, as those are
  --   -- ignored by delve in dap mode.
  --   -- available ui interactive function to prompt for arguments get_arguments
  --   build_flags = { '-tags=dev' },
  --   -- whether the dlv process to be created detached or not. there is
  --   -- an issue on Windows where this needs to be set to false
  --   -- otherwise the dlv server creation will fail.
  --   -- available ui interactive function to prompt for build flags: get_build_flags
  --   detached = vim.fn.has('win32') == 0,
  --   -- the current working directory to run dlv from, if other than
  --   -- the current working directory.
  --   cwd = nil,
  -- },
  -- -- options related to running closest test
  -- tests = {
  --   -- enables verbosity when running the test.
  --   verbose = false,
  -- },
})

-- Handled by nvim-dap-go
-- dap.adapters.go = {
--   type = "server",
--   port = "${port}",
--   executable = {
--     command = "dlv",
--     args = { "dap", "-l", "127.0.0.1:${port}" },
--   },
-- }

-- Use this if uv not working:
--   require('dap-python').setup('~/.local/share/nvim/mason/packages/debugpy/venv/bin/python3')
require('dap-python').setup('uv')

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

-- Debugging the Odin compiler (github.com/odin-lang/Odin, a C++ codebase).
--
-- build_odin.sh is a unity build: only src/main.cpp and src/libtommath.cpp
-- are translation units, every other .cpp is #included into them. DWARF
-- still records the included files, so file:line breakpoints in
-- checker.cpp, check_expr.cpp etc. bind normally despite that.
local function odin_repo_root()
  return vim.fs.root(vim.fn.getcwd(), { 'build_odin.sh' })
end

-- Rebuild only when a source file is newer than the binary. The unity
-- build is a single ~6s compile with no object-file caching, which is too
-- slow to pay on every F5 when only a breakpoint moved.
local function odin_build()
  local root = odin_repo_root()
  if not root then
    vim.notify('Not inside the Odin compiler repo (no build_odin.sh found)', vim.log.levels.ERROR)
    return nil
  end

  local binary = root .. '/odin'
  local bin_time = vim.fn.getftime(binary)
  local newest_src = -1
  for _, pattern in ipairs({ '**/*.cpp', '**/*.hpp' }) do
    for _, src in ipairs(vim.fn.globpath(root .. '/src', pattern, false, true)) do
      newest_src = math.max(newest_src, vim.fn.getftime(src))
    end
  end

  if bin_time > 0 and bin_time >= newest_src then
    return binary
  end

  vim.notify('Building Odin compiler (debug)...', vim.log.levels.INFO)
  local output = vim.fn.system({ 'sh', '-c', 'cd ' .. vim.fn.shellescape(root) .. ' && ./build_odin.sh debug' })

  -- build_odin.sh runs examples/demo after a successful debug build, so a
  -- non-zero exit can just mean the demo tripped over a work-in-progress
  -- compiler change. A refreshed binary is the real success signal.
  if vim.fn.getftime(binary) <= bin_time then
    vim.notify('Odin build failed:\n' .. output, vim.log.levels.ERROR)
    return nil
  end
  return binary
end

-- -no-threaded-checker makes check_procedure_bodies run each body inline on
-- the calling thread instead of farming them out to the thread pool, and
-- -thread-count:1 does the same for parsing. Without both, breakpoints in
-- check_expr/check_stmt fire on arbitrary worker threads mid-step.
local odin_debug_flags = '-file -no-threaded-checker -thread-count:1'

local function odin_default_args()
  local root = odin_repo_root() or vim.fn.getcwd()
  return 'check ' .. root .. '/scratch/hello.odin ' .. odin_debug_flags
end

local odin_configurations = {
  {
    name = 'Odin compiler: check scratch/hello.odin',
    type = 'codelldb',
    request = 'launch',
    program = odin_build,
    args = function()
      return vim.split(odin_default_args(), '%s+', { trimempty = true })
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = 'Odin compiler: run with args...',
    type = 'codelldb',
    request = 'launch',
    program = odin_build,
    args = function()
      return prompt_args(odin_default_args())()
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}

dap.configurations.c = c_configurations
-- Odin entries lead the cpp list so they're the obvious pick in that repo;
-- .cpp/.hpp are cpp filetype, so plain C projects never see them.
dap.configurations.cpp = {}
vim.list_extend(dap.configurations.cpp, odin_configurations)
vim.list_extend(dap.configurations.cpp, c_configurations)

local function zig_build_and_pick()
  vim.notify('Running zig build...', vim.log.levels.INFO)
  local output = vim.fn.system('zig build 2>&1')
  if vim.v.shell_error ~= 0 then
    vim.notify('zig build failed:\n' .. output, vim.log.levels.ERROR)
    return nil
  end
  local bin_dir = vim.fn.getcwd() .. '/zig-out/bin'
  local bins = vim.fn.globpath(bin_dir, '*', false, true)
  bins = vim.tbl_filter(function(f)
    return vim.fn.executable(f) == 1
  end, bins)
  if #bins == 0 then
    vim.notify('No executables found in zig-out/bin/', vim.log.levels.ERROR)
    return nil
  end
  if #bins == 1 then
    return bins[1]
  end
  return coroutine.create(function(co)
    vim.ui.select(bins, { prompt = 'Select executable:' }, function(choice)
      coroutine.resume(co, choice)
    end)
  end)
end

local function zig_build_test()
  local file = vim.fn.expand('%:p')
  if not file:match('%.zig$') then
    vim.notify('Current file is not a .zig file', vim.log.levels.ERROR)
    return nil
  end

  -- Zig forbids @import("../..") from escaping the module's root
  -- directory. Compiling a leaf file directly (e.g. src/heap/heap.zig)
  -- makes that file's directory the module root, so sibling imports like
  -- @import("../array/array.zig") fail with "import of file outside
  -- module path". Instead we always compile the package's real root
  -- module and use --test-filter to scope the emitted binary to just the
  -- current file's tests.
  local project_root = vim.fs.root(file, { 'build.zig', 'build.zig.zon' })
  if not project_root then
    vim.notify('No build.zig found; not inside a Zig package', vim.log.levels.ERROR)
    return nil
  end

  -- Find the package's root source file (what `zig build test` compiles).
  local root_src
  for _, c in ipairs({ '/src/root.zig', '/src/main.zig', '/root.zig', '/main.zig' }) do
    if vim.fn.filereadable(project_root .. c) == 1 then
      root_src = project_root .. c
      break
    end
  end
  if not root_src then
    vim.notify('Could not locate a Zig root source file (src/root.zig)', vim.log.levels.ERROR)
    return nil
  end

  -- Derive the test-name namespace from the current file's path relative
  -- to the root module's directory: src/heap/heap.zig -> "heap.heap".
  local root_dir = vim.fn.fnamemodify(root_src, ':h')
  local filter = nil
  if file ~= root_src and file:sub(1, #root_dir + 1) == root_dir .. '/' then
    filter = file:sub(#root_dir + 2):gsub('%.zig$', ''):gsub('/', '.')
  end

  local bin_path = vim.fn.getcwd() .. '/zig-test-debug'
  vim.notify('Building test binary' .. (filter and (' (filter: ' .. filter .. ')') or '') .. '...', vim.log.levels.INFO)
  local cmd = 'zig test --test-no-exec '
    .. (filter and ('--test-filter ' .. vim.fn.shellescape(filter) .. ' ') or '')
    .. '-femit-bin=' .. vim.fn.shellescape(bin_path) .. ' ' .. vim.fn.shellescape(root_src) .. ' 2>&1'
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify('Test build failed:\n' .. output, vim.log.levels.ERROR)
    return nil
  end
  return bin_path
end

dap.configurations.zig = {
  {
    name = 'Build & debug project',
    type = 'codelldb',
    request = 'launch',
    program = zig_build_and_pick,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = 'Debug test (current file)',
    type = 'codelldb',
    request = 'launch',
    program = zig_build_test,
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

vim.keymap.set('n', '<leader>u', function()
  view.toggle(true)
end, { desc = 'toggle debugger ui' })
