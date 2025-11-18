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

    vim.keymap.set('n', 'go', function()
      vim.lsp.buf.type_definition()
    end, { desc = 'goto type', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gr', function()
      vim.lsp.buf.references()
    end, { desc = 'list references', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gs', function()
      vim.lsp.buf.signature_help()
    end, { desc = 'display signature', buffer = bufnr, remap = false })

    vim.keymap.set('n', '<F2>', function()
      vim.lsp.buf.rename()
    end, { desc = 'rename', buffer = bufnr, remap = false })

    vim.keymap.set('n', '<F3>', function()
      if hasConform then
        conform.format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
        return
      end

      vim.lsp.buf.format()
    end, { desc = 'format', buffer = bufnr, remap = false })

    vim.keymap.set('n', '<F4>', function()
      vim.lsp.buf.code_action()
    end, { desc = 'code action', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gl', function()
      vim.diagnostic.open_float()
    end, { desc = 'list diagnostics', buffer = bufnr, remap = false })

    vim.keymap.set('n', '[d', function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, { desc = 'previous diagnostic', buffer = bufnr, remap = false })

    vim.keymap.set('n', ']d', function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, { desc = 'next diagnostic', buffer = bufnr, remap = false })
  end,
})

return {
  -- Linter
  {
    'mfussenegger/nvim-lint',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
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
        python = { 'ruff', 'bandit' },
        go = { 'golangcilint' },
        sql = { 'sqruff' },
        php = { 'psalm', 'phpstan' },
      }

      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
        callback = function()
          lint.try_lint()
        end,
      })

      vim.keymap.set('n', '<leader><F3>', function()
        lint.try_lint()
      end, { desc = 'lint' })
    end,
  },

  -- Formatter
  {
    'stevearc/conform.nvim',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
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
          python = { 'ruff' },
          sql = { 'sqruff' },
          php = { 'pint' },
        },
        default_format_opts = {
          lsp_format = 'fallback',
        },
      })
    end,
  },

  {
    'mason-org/mason-lspconfig.nvim',
    opts = {
      ensure_installed = {
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
        'golangci_lint_ls',
        'templ',

        -- Python
        'pyright',
        'ruff',

        -- PHP
        'phpactor',
        'laravel_ls',
      },
    },
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'neovim/nvim-lspconfig',
    },
  },

  -- installer for non-LSP tools
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = {
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

        -- Golang
        'golangci-lint',
        'golines',
        'gomodifytags',
        'gotests',

        -- Python
        'bandit',

        -- PHP
        'psalm',
        'pint',
        'phpstan',
      },
      run_on_start = true,
      auto_update = false,
    },
    config = function(_, opts)
      require('mason-tool-installer').setup(opts)
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      { 'windwp/nvim-ts-autotag' },
    },
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    opts = {
      auto_install = true,
      ensure_installed = {
        'bash',
        'c',
        'comment',
        'cpp',
        'css',
        'csv',
        'diff',
        'dockerfile',
        'git_config',
        'git_rebase',
        'gitattributes',
        'gitcommit',
        'gitignore',
        'html',
        'ini',
        'javascript',
        'jsdoc',
        'json',
        'json5',
        'jsonc',
        'lua',
        'luadoc',
        'luap',
        'markdown',
        'markdown_inline',
        'php',
        'phpdoc',
        'blade',
        'python',
        'regex',
        'scss',
        'sql',
        'svelte',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'xml',
        'yaml',
        'go',
        'gomod',
        'gosum',
        'gotmpl',
      },
      highlight = { enable = true },
      indent = { enable = true },
      autotag = { enable = true },
      rainbow = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>', -- set to `false` to disable one of the mappings
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
    },
    config = function(_, opts)
      -- require('nvim-ts-autotag').setup()
      require('nvim-treesitter.configs').setup(opts)
    end,
  },

  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {},
    keys = {
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
    },
  },

  {
    'nvim-mini/mini.pairs',
    version = '*',
    opts = {
      -- In which modes mappings from this `config` should be created
      modes = { insert = true, command = false, terminal = false },

      -- Global mappings. Each right hand side should be a pair information, a
      -- table with at least these fields (see more in |MiniPairs.map|):
      -- - <action> - one of 'open', 'close', 'closeopen'.
      -- - <pair> - two character string for pair to be used.
      -- By default pair is not inserted after `\`, quotes are not recognized by
      -- <CR>, `'` does not insert pair after a letter.
      -- Only parts of tables can be tweaked (others will use these defaults).
      mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },

        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
      },
    },
  },
}
