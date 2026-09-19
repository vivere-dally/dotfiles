local pack = require('pack')
local gh = pack.gh

pack.add({
  gh('nvim-tree/nvim-web-devicons'),
  gh('stevearc/oil.nvim'),
})

require('oil').setup({
  columns = { 'icon', 'permissions', 'size', 'mtime' },
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set('n', '<leader>-', '<cmd>Oil<CR>', { desc = 'Open Oil.nvim' })
