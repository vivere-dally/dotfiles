vim.pack.add({ require('pack').gh('tpope/vim-fugitive') })

-- Fugitive re-applies its own buffer-local `cc` (plain `:Git commit`) every
-- time the status buffer reloads (stage/unstage/etc.), which would silently
-- replace the `commit -s` mapping below. An empty g:nremap entry tells
-- fugitive's s:Map() to skip defining that key, so ours survives reloads.
vim.g.nremap = { cc = '' }

vim.keymap.set('n', '<leader>gg', vim.cmd.Git, { desc = 'git show' })

vim.api.nvim_create_autocmd('BufWinEnter', {
  group = vim.api.nvim_create_augroup('vivere-dally_fugitive', {}),
  pattern = '*',
  callback = function()
    if vim.bo.ft ~= 'fugitive' then return end

    local bufnr = vim.api.nvim_get_current_buf()

    vim.keymap.set('n', 'cc', function()
      vim.cmd.Git('commit -s')
    end, { buf = bufnr, remap = false, desc = 'git commit -s' })

    vim.keymap.set('n', '<leader>gp', function()
      vim.cmd.Git('push')
    end, { buf = bufnr, remap = false, desc = 'git push' })

    -- Not sure I need these yet
    -- vim.keymap.set('n', '<leader>gt', function()
    --   vim.cmd.Git('push -u origin')
    -- end, { buf = bufnr, remap = false, desc = 'git push ' })

    vim.keymap.set('n', '<leader>gP', function()
      vim.cmd.Git('pull --rebase')
    end, { buf = bufnr, remap = false, desc = 'git pull w/ rebase' })
  end,
})
