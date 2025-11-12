return {
  {
    'tpope/vim-fugitive',
    lazy = false,
    event = { 'BufReadPre', 'BufNewFile' },
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

          vim.keymap.set('n', '<leader>gP', function()
            vim.cmd.Git({ 'pull', '--rebase' })
          end, { buffer = bufnr, remap = false, desc = 'git pull w/ rebase' })
        end,
      })
    end,
  },
}
