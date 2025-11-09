require('nvim-autopairs').setup()
require('neodev').setup()

local hasConform, conform = pcall(require, 'conform')
local lsp_zero = require('lsp-zero')
local lsp_zero_action = require('lsp-zero').cmp_action()
lsp_zero.on_attach(function(_, bufnr)
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
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })

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
    vim.diagnostic.goto_next()
  end, { desc = 'previous diagnostic', buffer = bufnr, remap = false })

  vim.keymap.set('n', ']d', function()
    vim.diagnostic.goto_prev()
  end, { desc = 'next diagnostic', buffer = bufnr, remap = false })
end)

require('mason').setup()
require('mason-lspconfig').setup({
  ensure_installed = {
    -- Install only LSPs
    'angularls',
    'bashls',
    'clangd',
    'cssls',
    'dockerls',
    'docker_compose_language_service',
    'html',
    'jsonls',
    'lua_ls',
    'tsserver',
    'marksman',
    -- "intelephense",
    'phpactor',
    'pyright',
    'svelte',
    'taplo',
    'tailwindcss',
    'lemminx',
    'yamlls',
    'vimls',
    'diagnosticls',
    'rust_analyzer',
    'gopls',
  },
  handlers = {
    lsp_zero.default_setup,
    lua_ls = function()
      require('lspconfig').lua_ls.setup(lsp_zero.nvim_lua_ls())
    end,
    gopls = function()
      require('lspconfig').gopls.setup({
        settings = {
          gopls = {
            buildFlags = { '-tags=dev' },
          },
        },
      })
    end,
    -- clangd = function()
    --   require('lspconfig').clangd.setup({
    --     cmd = { 'clangd', '--completion-style=detailed' },
    --   })
    -- end,
    -- TODO: not sure if this helps at all
    -- intelephense = function()
    --     return require("lspconfig").intelephense.setup({
    --         settings = {
    --             intelephense = {
    --                 files = {
    --                     maxSize = 10000000, -- 10MB
    --                 },
    --             },
    --         },
    --         capabilities = lsp_zero.get_capabilities(),
    --     })
    -- end,
  },
})

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
cmp.setup({
  sources = {
    { name = 'nvim_lsp' }, -- lsp provided
    { name = 'nvim_lua' }, -- lua api
    { name = 'buffer' }, -- text in buffer
    { name = 'luasnip' }, -- snippets
    { name = 'path' }, -- file system path
    { name = 'vim-dadbod-completion' }, -- sql completion
  },
  formatting = lsp_zero.cmp_format({}),
  mapping = cmp.mapping.preset.insert({
    -- Move between suggested completion
    ['<C-k>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<C-j>'] = cmp.mapping.select_next_item(cmp_select),

    -- Move completion docs
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-n>'] = cmp.mapping.scroll_docs(4),

    -- Confirm completion
    ['<CR>'] = cmp.mapping.confirm({ select = true }),

    -- Trigger completion
    ['<C-Space>'] = cmp.mapping.complete(),

    ['<Tab>'] = lsp_zero_action.luasnip_supertab(),
    ['<S-Tab>'] = lsp_zero_action.luasnip_shift_supertab(),
  }),
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
})

cmp.event:on('confirm_done', require('nvim-autopairs.completion.cmp').on_confirm_done())
