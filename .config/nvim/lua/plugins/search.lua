local pack = require('pack')

pack.add({ pack.gh('MagicDuck/grug-far.nvim') })

local grug_far = require('grug-far')

grug_far.setup({})

vim.keymap.set('n', '<leader>rp', function()
  grug_far.open()
end, { desc = 'Replace across project' })

vim.keymap.set('x', '<leader>rp', function()
  grug_far.with_visual_selection()
end, { desc = 'Replace selection across project' })
