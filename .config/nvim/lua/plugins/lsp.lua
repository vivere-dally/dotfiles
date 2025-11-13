vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local bufnr = ev.buf

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
      -- if hasConform then
      --   conform.format({
      --     lsp_fallback = true,
      --     async = false,
      --     timeout_ms = 1000,
      --   })
      --
      --   return
      -- end

      vim.lsp.buf.format()
    end, { desc = 'format', buffer = bufnr, remap = false })

    vim.keymap.set('n', '<F4>', function()
      vim.lsp.buf.code_action()
    end, { desc = 'code action', buffer = bufnr, remap = false })

    vim.keymap.set('n', 'gl', function()
      vim.diagnostic.open_float()
    end, { desc = 'list diagnostics', buffer = bufnr, remap = false })

    vim.keymap.set('n', '[d', function()
      vim.diagnostic.goto_next()
    end, { desc = 'previous diagnostic', buffer = bufnr, remap = false })

    vim.keymap.set('n', ']d', function()
      vim.diagnostic.goto_prev()
    end, { desc = 'next diagnostic', buffer = bufnr, remap = false })
  end,
})

return {

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
        'biome',
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
        'ruff',
        -- "pyright", -- maybe?
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

        -- C/C++
        'cpplint',

        -- Golang
        'golangci-lint',
        'golines',
        'gomodifytags',
        'gotests',

        -- Python
        'bandit',
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
      'windwp/nvim-ts-autotag',
    },
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    event = { 'BufReadPre', 'BufNewFile' },
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
}
