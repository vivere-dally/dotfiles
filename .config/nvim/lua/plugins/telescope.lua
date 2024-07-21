return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { 'nvim-tree/nvim-web-devicons' },
    { 'nvim-telescope/telescope-live-grep-args.nvim' },
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    local t = require('telescope')
    local ta = require('telescope.actions')
    local tb = require('telescope.builtin')

    t.setup({
      defaults = {
        path_display = { 'truncate' },
        layout_strategy = 'flex',
        layout_config = {
          anchor = 'N',
          prompt_position = 'top',
        },
        preview = { timeout = 200 },
        mappings = {
          i = {
            ['<C-k>'] = ta.preview_scrolling_up,
            ['<C-j>'] = ta.preview_scrolling_down,
            ["<C-q>"] = ta.smart_send_to_qflist + ta.open_qflist,
          },
          n = {
            ['<C-k>'] = ta.preview_scrolling_up,
            ['<C-j>'] = ta.preview_scrolling_down,
            ["<C-q>"] = ta.smart_send_to_qflist + ta.open_qflist,
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true, -- false will only do exact matching
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        },
      },
      pickers = {
        find_files = { hidden = true },
        buffers = {
          ignore_current_buffer = true,
          sort_mru = true,
          previewer = false,
        },
      },
    })
    t.load_extension('fzf')

    vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = 'find files' })
    vim.keymap.set('n', '<leader>F', function()
      tb.find_files({ no_ignore = true, prompt_title = 'All files' })
    end, { desc = 'find all files' })
    vim.keymap.set('n', '<leader>ft', tb.git_files, { desc = 'find tracked (git)' })
    vim.keymap.set('n', '<leader>fg', t.extensions.live_grep_args.live_grep_args, { desc = 'find grep' })
    vim.keymap.set('n', '<leader>fw', tb.grep_string, { desc = 'find word' })
    vim.keymap.set('n', '<leader>fb', tb.buffers, { desc = 'find buffers' })
    vim.keymap.set('n', '<leader>fh', tb.help_tags, { desc = 'find help' })
  end,
}
