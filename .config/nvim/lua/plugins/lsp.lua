local pack = require('pack')
local gh = pack.gh

pack.add({
  gh('mfussenegger/nvim-lint'),
  gh('stevearc/conform.nvim'),
  gh('neovim/nvim-lspconfig'),
  gh('mason-org/mason.nvim'),
  gh('mason-org/mason-lspconfig.nvim'),
  gh('WhoIsSethDaniel/mason-tool-installer.nvim'),
  -- nvim-treesitter `main` branch (the rewrite). The old `master` branch is
  -- archived and incompatible with Neovim 0.12, which ships its own markdown
  -- parsers/queries; the two disagree and crash the highlighter on injections
  -- (treesitter.lua:197 "attempt to call method 'range' (a nil value)"). Not a
  -- version range: the only semver tag, v0.10.0, is on `master`.
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'main' },
  gh('windwp/nvim-ts-autotag'),
  gh('nvim-tree/nvim-web-devicons'),
  gh('folke/trouble.nvim'),
  { src = gh('nvim-mini/mini.pairs'), version = vim.version.range('*') },
})

-- References and type definition are the Neovim defaults grr and grt, next to
-- grn, gra, gri and grx. A buffer-local `gr` would make each of them wait for
-- 'timeoutlen'.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf
    local hasConform, conform = pcall(require, 'conform')

    vim.keymap.set('n', 'K', function()
      vim.lsp.buf.hover()
    end, { desc = 'display hover', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gd', function()
      vim.lsp.buf.definition()
    end, { desc = 'goto definition', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gD', function()
      vim.lsp.buf.declaration()
    end, { desc = 'goto declaration', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gi', function()
      vim.lsp.buf.implementation()
    end, { desc = 'list implementations', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gs', function()
      vim.lsp.buf.signature_help()
    end, { desc = 'display signature', buffer = bufnr, remap = false })

    -- Rename: F2 and leader alternative
    vim.keymap.set('n', '<F2>', function()
      vim.lsp.buf.rename()
    end, { desc = 'Rename symbol', buffer = bufnr, remap = false })
    vim.keymap.set('n', '<leader>cr', function()
      vim.lsp.buf.rename()
    end, { desc = 'Code rename', buffer = bufnr, remap = false })

    -- Format: F3 and leader alternative
    local format_fn = function()
      if hasConform then
        conform.format({ lsp_format = 'fallback', async = false, timeout_ms = 1000 })
        return
      end
      vim.lsp.buf.format()
    end
    vim.keymap.set('n', '<F3>', format_fn, { desc = 'Format', buffer = bufnr, remap = false })
    vim.keymap.set({ 'n', 'x' }, '<leader>cf', format_fn, { desc = 'Code format', buffer = bufnr, remap = false })

    -- Code action: F4 and leader alternative
    vim.keymap.set({ 'n', 'x' }, '<F4>', function()
      vim.lsp.buf.code_action()
    end, { desc = 'Code action', buffer = bufnr, remap = false })
    vim.keymap.set({ 'n', 'x' }, '<leader>ca', function()
      vim.lsp.buf.code_action()
    end, { desc = 'Code action', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gl', function()
      vim.diagnostic.open_float()
    end, { desc = 'list diagnostics', buffer = bufnr, remap = false })
  end,
})

-- The default [d and ]d jump through this; the float shows what they landed on.
vim.diagnostic.config({
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false })
    end,
  },
})

vim.lsp.enable('zls')

-- Linter
local lint = require('lint')

lint.linters_by_ft = {
  -- javascript = { 'biome' },
  -- typescript = { 'biome' },
  -- javascriptreact = { 'biome' },
  -- typescriptreact = { 'biome' },
  javascript = { 'eslint_d' },
  typescript = { 'eslint_d' },
  javascriptreact = { 'eslint_d' },
  typescriptreact = { 'eslint_d' },
  python = { 'bandit' },
  go = { 'golangcilint' },
  sql = { 'sqruff' },
  -- php = { 'psalm', 'phpstan' },
}

vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufWritePost' }, {
  callback = function()
    lint.try_lint()
  end,
})

vim.keymap.set('n', '<leader>cl', function()
  lint.try_lint()
end, { desc = 'Code lint' })

-- Formatter
require('conform').setup({
  formatters_by_ft = {
    -- javascript = { 'biome' },
    -- typescript = { 'biome' },
    -- javascriptreact = { 'biome' },
    -- typescriptreact = { 'biome' },
    -- svelte = { 'biome' },
    -- css = { 'biome' },
    -- html = { 'biome' },
    -- json = { 'biome' },
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescriptreact = { 'prettier' },
    svelte = { 'prettier' },
    css = { 'prettier' },
    html = { 'prettier' },
    json = { 'prettier' },
    yaml = { 'yamlfmt' },
    lua = { 'stylua' },
    go = { 'goimports' },
    zig = { 'zigfmt' },
    python = { 'ruff' },
    sql = { 'sqruff' },
    -- php = { 'pint' },
  },
  default_format_opts = {
    lsp_format = 'fallback',
  },
})

local lsp_servers = {
  'bashls',
  'lua_ls',
  'typos_lsp',
  'docker_language_server',
  'sqlls', -- https://github.com/joe-re/sql-language-server?tab=readme-ov-file#configuration

  -- C/C++
  'clangd',

  -- Javascript ecosystem
  'ts_ls',
  -- 'biome', -- Does not currently work for me since I am working on projects with eslint/prettier. Maybe in the future
  'tailwindcss',
  'eslint',

  -- Structured file formats
  'superhtml',
  'taplo',
  'yamlls',
  'lemminx',

  -- Golang
  'gopls',
  'templ',

  -- Python
  'basedpyright',
  'ruff',

  -- PHP
  'phpactor',
  'laravel_ls',

  -- Kotlin
  'kotlin_language_server',
}

local mason_tools = {
  'shfmt',
  'stylua',
  'sqruff',

  -- Structured file formats
  'yamlfmt',

  -- JS/TS
  'prettier',
  'eslint_d',

  -- C/C++
  'cpplint',
  'codelldb',

  -- Golang (golangci-lint installed via brew — Mason build may lag behind Go versions)
  'goimports',
  'golines',
  'gomodifytags',
  'gotests',
  'iferr',

  -- Python
  'bandit',

  -- PHP
  -- 'psalm',
  -- 'pint',
  -- 'phpstan',
}

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = lsp_servers,
  -- automatic_enable starts every installed Mason package that maps to a server.
  -- stylua and sqruff are installed as a formatter and a linter (conform and
  -- nvim-lint run them); pyright is superseded by basedpyright; copilot is unused
  -- (supermaven completes) and would attach to every buffer.
  automatic_enable = {
    exclude = { 'stylua', 'sqruff', 'pyright', 'copilot' },
  },
})

-- installer for non-LSP tools
require('mason-tool-installer').setup({
  ensure_installed = mason_tools,
  -- The bootstrap invokes the synchronous installer after startup. Starting
  -- the asynchronous VimEnter job too would make both jobs manage one package.
  run_on_start = vim.env.NVIM_BOOTSTRAP ~= '1',
  auto_update = false,
})

-- mason-lspconfig skips ensure_installed in headless Neovim. The bootstrap
-- command starts those installations explicitly, waits for all configured
-- Mason packages, and reports any package that did not install.
vim.api.nvim_create_user_command('MasonBootstrap', function()
  require('mason-tool-installer').check_install(false, true)

  local registry = require('mason-registry')
  local mapping = require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package
  local expected = vim.deepcopy(mason_tools)

  for _, server in ipairs(lsp_servers) do
    local package = mapping[server]
    if not package then error(('No Mason package maps to LSP server %q'):format(server)) end
    table.insert(expected, package)
  end

  require('mason-lspconfig.features.ensure_installed')()
  local completed = vim.wait(600000, function()
    for _, name in ipairs(expected) do
      local ok, package = pcall(registry.get_package, name)
      if ok and package:is_installing() then return false end
    end
    return true
  end, 100)
  if not completed then error('Timed out while installing Mason packages') end

  local missing = {}
  for _, name in ipairs(expected) do
    local ok, package = pcall(registry.get_package, name)
    if not ok or not package:is_installed() then table.insert(missing, name) end
  end
  if #missing > 0 then error('Mason packages failed to install: ' .. table.concat(missing, ', ')) end
end, { desc = 'Install and verify all configured Mason packages' })

require('nvim-ts-autotag').setup()

local nts = require('nvim-treesitter')
nts.setup()
-- No select/move/swap keymaps yet. sidekick reads the textobjects queries for
-- its {function} and {class} prompt context.
require('nvim-treesitter-textobjects').setup({})

-- Parsers to keep installed (replaces the old `ensure_installed`).
-- `install()` only compiles parsers that are missing, so this is a cheap
-- no-op on subsequent startups.
local ensure = {
  'bash', 'blade', 'c', 'comment', 'cpp', 'css', 'csv', 'diff', 'dockerfile',
  'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
  'html', 'ini', 'javascript', 'jsdoc', 'json', 'json5', 'lua',
  'luadoc', 'luap', 'markdown', 'markdown_inline', 'php', 'phpdoc',
  'python', 'regex', 'scss', 'sql', 'svelte', 'toml', 'tsx', 'typescript',
  'vim', 'vimdoc', 'xml', 'yaml', 'go', 'gomod', 'gosum', 'gotmpl', 'zig',
}
-- Asynchronous: a failed download or build is logged, not raised here.
local parser_install = nts.install(ensure)
if vim.env.NVIM_BOOTSTRAP == '1' then
  if not parser_install:wait(600000) then error('One or more Tree-sitter parsers failed to install') end
  local installed = {}
  for _, parser in ipairs(nts.get_installed()) do
    installed[parser] = true
  end
  local missing = {}
  for _, parser in ipairs(ensure) do
    if not installed[parser] then table.insert(missing, parser) end
  end
  if #missing > 0 then error('Tree-sitter parsers failed to install: ' .. table.concat(missing, ', ')) end
end

-- Enable highlighting + (experimental) indentation per buffer. The `main`
-- branch replaces the `highlight`/`indent` modules with vim.treesitter.start()
-- and indentexpr, wired up on FileType. Also replaces `auto_install`.
-- Set of parsers nvim-treesitter actually knows how to install. We gate on
-- this so we never try to fetch a parser for pseudo-filetypes like `oil` or
-- `fugitive` (get_lang() echoes the filetype back, which would otherwise log
-- "[nvim-treesitter] warning: skipping unsupported language: oil").
local available = {}
for _, l in ipairs(nts.get_available()) do available[l] = true end

local pending = {}
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user.treesitter', { clear = true }),
  callback = function(args)
    local buf = args.buf
    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    -- skip filetypes without a real tree-sitter parser (oil, fugitive, ...)
    if not lang or not available[lang] then return end

    local function start(target_buf)
      if not vim.api.nvim_buf_is_valid(target_buf) then return end
      local target_lang = vim.treesitter.language.get_lang(vim.bo[target_buf].filetype)
      if target_lang ~= lang then return end
      if not pcall(vim.treesitter.start, target_buf, lang) then return end
      -- Without an indents query the treesitter indentexpr puts each new line at
      -- column 0 (vim, gitconfig, dockerfile, ...); keep the runtime indent there.
      local has_indents, indents = pcall(vim.treesitter.query.get, lang, 'indents')
      if has_indents and indents then
        vim.bo[target_buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    local ok, added = pcall(vim.treesitter.language.add, lang)
    if ok and added then
      start(buf)
      return
    end

    -- Keep every buffer that opens while this language is installing. One task
    -- serves the whole language, then starts each buffer that still has that type.
    if pending[lang] then
      pending[lang][buf] = true
      return
    end
    pending[lang] = { [buf] = true }
    nts.install({ lang }):await(vim.schedule_wrap(function(err)
      local buffers = pending[lang] or {}
      pending[lang] = nil
      if err then return end
      for target_buf in pairs(buffers) do start(target_buf) end
    end))
  end,
})

-- Incremental selection on the old keys. The built-in Visual `an` and `in` (0.12)
-- select the parent and the child node, and fall back to LSP selectionRange
-- when the buffer has no parser. `remap`, because those are default mappings.
vim.keymap.set('n', '<C-space>', 'van', { remap = true, desc = 'TS: init selection' })
vim.keymap.set('x', '<C-space>', 'an', { remap = true, desc = 'TS: expand selection' })
vim.keymap.set('x', '<BS>', 'in', { remap = true, desc = 'TS: shrink selection' })

require('trouble').setup({})
pack.keys({
  {
    '<leader>xx',
    '<cmd>Trouble diagnostics toggle<cr>',
    desc = 'Diagnostics (Trouble)',
  },
  {
    '<leader>xX',
    '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
    desc = 'Buffer Diagnostics (Trouble)',
  },
  {
    '<leader>xL',
    '<cmd>Trouble loclist toggle<cr>',
    desc = 'Location List (Trouble)',
  },
  {
    '<leader>xQ',
    '<cmd>Trouble qflist toggle<cr>',
    desc = 'Quickfix List (Trouble)',
  },
})

require('mini.pairs').setup({
  -- In which modes mappings from this `config` should be created
  modes = { insert = true, command = false, terminal = false },
})
