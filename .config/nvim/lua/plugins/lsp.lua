return {
  'VonHeikemen/lsp-zero.nvim',
  branch = 'v3.x',
  dependencies = {
    -- LSP & Support
    { 'neovim/nvim-lspconfig' },
    { 'williamboman/mason.nvim' },
    { 'williamboman/mason-lspconfig.nvim' },
    { 'WhoIsSethDaniel/mason-tool-installer.nvim' },
    { 'folke/neodev.nvim' },

    -- Autocompletion
    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-cmdline' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-nvim-lua' },
    { 'windwp/nvim-autopairs' },
    { 'jsongerber/nvim-px-to-rem', config = true },

    -- Snippets
    { 'L3MON4D3/LuaSnip' },
    { 'rafamadriz/friendly-snippets' },

    -- Linter
    {
      'mfussenegger/nvim-lint',
      lazy = true,
      event = { 'BufReadPre', 'BufNewFile' },
    },

    -- Formatter
    {
      'stevearc/conform.nvim',
      lazy = true,
      event = { 'BufReadPre', 'BufNewFile' },
    },
  },
  config = function()
    require('plugins.setup.lsp')

    require('mason-tool-installer').setup({
      ensure_installed = {
        -- linters
        'codespell',
        'phpstan',
        'eslint_d',
        'pylint',

        -- formatters
        'php-cs-fixer',
        'prettier',
        'stylua',
        'black',
      },
    })

    require('plugins.setup.formatter')
    require('plugins.setup.linter')
  end,
}
