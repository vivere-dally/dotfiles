return {
  'ThePrimeagen/harpoon',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('harpoon').setup({
      menu = {
        width = vim.api.nvim_win_get_width(0) - 4,
      },
    })

    local mark = require('harpoon.mark')
    local ui = require('harpoon.ui')

    vim.keymap.set('n', '<leader>ha', mark.add_file)
    vim.keymap.set('n', '<leader>hh', ui.toggle_quick_menu)

    vim.keymap.set('n', '<leader>h1', function()
      ui.nav_file(1)
    end)
    vim.keymap.set('n', '<leader>h2', function()
      ui.nav_file(2)
    end)
    vim.keymap.set('n', '<leader>h3', function()
      ui.nav_file(3)
    end)
    vim.keymap.set('n', '<leader>h4', function()
      ui.nav_file(4)
    end)

    vim.keymap.set('n', '<leader>hj', ui.nav_next)
    vim.keymap.set('n', '<leader>hk', ui.nav_prev)
  end,
}
