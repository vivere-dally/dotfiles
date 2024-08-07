return {
  {
    'tpope/vim-fugitive',
    lazy = false,
    config = function()
      vim.keymap.set('n', '<leader>gg', vim.cmd.Git, { desc = 'git show' })

      vim.api.nvim_create_autocmd('BufWinEnter', {
        group = vim.api.nvim_create_augroup('vivere-dally_fugitive', {}),
        pattern = '*',
        callback = function()
          if vim.bo.ft ~= 'fugitive' then
            return
          end

          local bufnr = vim.api.nvim_get_current_buf()
          vim.keymap.set('n', '<leader>gp', function()
            vim.cmd.Git('push')
          end, { buffer = bufnr, remap = false, desc = 'git push' })

          -- Not sure I need these yet
          -- vim.keymap.set('n', '<leader>gt', function()
          --   vim.cmd.Git({ 'push', '-u', 'origin' })
          -- end, { buffer = bufnr, remap = false, desc = 'git push ' })
          --
          -- vim.keymap.set('n', '<leader>gP', function()
          --   vim.cmd.Git({ 'pull', '--rebase' })
          -- end, { buffer = bufnr, remap = false, desc = 'git pull w/ rebase' })
        end,
      })
    end,
  },
  {
    'lewis6991/gitsigns.nvim',
    lazy = false,
    keys = {
      { '<leader>gj', ':Gitsigns next_hunk<CR>', { desc = 'next hunk' } },
      { '<leader>gh', ':Gitsigns prev_hunk<CR>', { desc = 'prev hunk' } },
      { '<leader>gs', ':Gitsigns stage_hunk<CR>', { desc = 'stage hunk' } },
      { '<leader>gu', ':Gitsigns undo_stage_hunk<CR>', { desc = 'undo stage hunk' } },
      { '<leader>gp', ':Gitsigns preview_hunk<CR>', { desc = 'preview hunk' } },
      { '<leader>gb', ':Gitsigns blame_line<CR>', { desc = 'blame line' } },
    },
    opts = {
      preview_config = {
        border = { '', '', '', ' ' },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '┄' },
        untracked = { text = '┊' },
      },
    },
  },
}
