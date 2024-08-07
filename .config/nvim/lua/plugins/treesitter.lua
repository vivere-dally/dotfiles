return {
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      { 'nvim-treesitter/playground', cmd = 'TSPlaygroundToggle' },
      {
        'JoosepAlviste/nvim-ts-context-commentstring',
        opts = {
          custom_calculation = function(_, language_tree)
            if vim.bo.filetype == 'blade' and language_tree._lang ~= 'javascript' then
              return '{{-- %s --}}'
            end
          end,
        },
        config = function(_, opts)
          require('ts_context_commentstring').setup(opts)
          vim.g.skip_ts_context_commentstring_module = true
        end,
      },
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      { 'windwp/nvim-ts-autotag' },
    },
    event = { 'BufReadPre', 'BufNewFile' },
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      auto_install = true,
      ensure_installed = {
        'bash',
        'c',
        'c_sharp',
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
        'http',
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
      },
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
        disable = { 'yaml' },
      },
      rainbow = {
        enable = true,
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['if'] = '@function.inner',
            ['af'] = '@function.outer',
            ['ia'] = '@parameter.inner',
            ['aa'] = '@parameter.outer',
          },
        },
      },
      -- autotag = {
      --   enable = true,
      -- },
    },
    config = function(_, opts)
      require('nvim-ts-autotag').setup()
      require('nvim-treesitter.configs').setup(opts)

      local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
      parser_config.blade = {
        install_info = {
          url = 'https://github.com/EmranMR/tree-sitter-blade',
          files = { 'src/parser.c' },
          branch = 'main',
        },
        filetype = 'blade',
      }
      vim.filetype.add({
        pattern = {
          ['.*%.blade%.php'] = 'blade',
        },
      })
    end,
  },
}
