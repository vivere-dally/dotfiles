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
        conform.format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
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

    vim.keymap.set('n', '[d', function()
      vim.diagnostic.jump({ count = -1, float = true })
    end, { desc = 'previous diagnostic', buffer = bufnr, remap = false })

    vim.keymap.set('n', ']d', function()
      vim.diagnostic.jump({ count = 1, float = true })
    end, { desc = 'next diagnostic', buffer = bufnr, remap = false })
  end,
})

vim.lsp.enable('zls')

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
        'copilot',

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
      },
      run_on_start = true,
      auto_update = false,
    },
    config = function(_, opts)
      require('mason-tool-installer').setup(opts)
    end,
  },

  {
    -- nvim-treesitter `main` branch (the rewrite). The old `master` branch is
    -- archived and incompatible with Neovim 0.12, which ships its own markdown
    -- parsers/queries; the two disagree and crash the highlighter on injections
    -- (treesitter.lua:197 "attempt to call method 'range' (a nil value)").
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
      { 'windwp/nvim-ts-autotag' },
    },
    config = function()
      require('nvim-ts-autotag').setup()

      local nts = require('nvim-treesitter')
      nts.setup()
      -- textobjects is loaded and available; add select/move/swap keymaps here
      -- if you want them (none were configured on the old branch).
      require('nvim-treesitter-textobjects').setup({})

      -- Parsers to keep installed (replaces the old `ensure_installed`).
      -- `install()` only compiles parsers that are missing, so this is a cheap
      -- no-op on subsequent startups. ('blade' was dropped: not in the registry.)
      local ensure = {
        'bash', 'c', 'comment', 'cpp', 'css', 'csv', 'diff', 'dockerfile',
        'git_config', 'git_rebase', 'gitattributes', 'gitcommit', 'gitignore',
        'html', 'ini', 'javascript', 'jsdoc', 'json', 'json5', 'lua',
        'luadoc', 'luap', 'markdown', 'markdown_inline', 'php', 'phpdoc',
        'python', 'regex', 'scss', 'sql', 'svelte', 'toml', 'tsx', 'typescript',
        'vim', 'vimdoc', 'xml', 'yaml', 'go', 'gomod', 'gosum', 'gotmpl', 'zig',
      }
      pcall(function() nts.install(ensure) end)

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

          local function start()
            if pcall(vim.treesitter.start, buf, lang) then
              vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
          end

          local ok, added = pcall(vim.treesitter.language.add, lang)
          if ok and added then
            start()
          elseif not pending[lang] then
            -- auto-install a missing parser, then start (replaces `auto_install`)
            pending[lang] = true
            pcall(function() nts.install({ lang }):await(vim.schedule_wrap(start)) end)
          end
        end,
      })

      -- Incremental selection: the `main` branch dropped this module, so we
      -- reimplement the old <C-space> (expand) / <BS> (shrink) behaviour with a
      -- node stack over the tree-sitter node under the cursor.
      do
        local stack = {}

        local function select_node(node)
          local srow, scol, erow, ecol = node:range()
          if ecol == 0 then
            erow = erow - 1
            ecol = #(vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1] or '')
          end
          vim.fn.setpos("'<", { 0, srow + 1, scol + 1, 0 })
          vim.fn.setpos("'>", { 0, erow + 1, ecol, 0 })
          vim.cmd('normal! gv')
        end

        local function init_selection()
          local node = vim.treesitter.get_node()
          if not node then return end
          stack = { node }
          select_node(node)
        end

        local function node_incremental()
          local node = stack[#stack]
          if not node then return init_selection() end
          local s1, c1, e1, x1 = node:range()
          local parent = node:parent()
          -- climb past parents that span the same range as the current node
          while parent do
            local s2, c2, e2, x2 = parent:range()
            if s2 ~= s1 or c2 ~= c1 or e2 ~= e1 or x2 ~= x1 then break end
            parent = parent:parent()
          end
          if not parent then return end
          stack[#stack + 1] = parent
          select_node(parent)
        end

        local function node_decremental()
          if #stack > 1 then stack[#stack] = nil end
          local node = stack[#stack]
          if node then select_node(node) end
        end

        vim.keymap.set('n', '<C-space>', init_selection, { desc = 'TS: init selection' })
        vim.keymap.set('x', '<C-space>', node_incremental, { desc = 'TS: expand selection' })
        vim.keymap.set('x', '<BS>', node_decremental, { desc = 'TS: shrink selection' })
      end
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
