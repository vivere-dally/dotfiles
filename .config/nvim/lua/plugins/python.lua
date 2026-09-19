local pack = require('pack')

pack.add({ pack.gh('linux-cultist/venv-selector.nvim') })

require('venv-selector').setup({
  search = {}, -- if you add your own searches, they go here.
  options = {
    -- Explicit, so that a picker some other plugin pulls in never takes over:
    -- `auto` prefers telescope and fzf-lua to snacks.
    picker = 'snacks',
  },
})

vim.keymap.set('n', ',v', '<cmd>VenvSelect<cr>', { desc = 'Select Python venv' })
