return {
  'nvim-tree/nvim-tree.lua',
  version = '*',
  lazy = false,
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    -- disable netrw at the very start of your init.lua
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require('nvim-tree').setup({
      view = {
        width = 35,
        relativenumber = true,
      },
      -- disable window_picker for explorer to work well with window splits
      actions = {
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
      filters = {
        custom = { '.DS_Store' },
      },
      git = {
        ignore = false,
      },
    })

    vim.keymap.set('n', '<leader>ee', '<cmd>NvimTreeToggle<CR>', { desc = 'toggle explorer' })
    vim.keymap.set('n', '<leader>ef', '<cmd>NvimTreeFindFileToggle<CR>', { desc = 'toggle explorer on current file' })
    vim.keymap.set('n', '<leader>ec', '<cmd>NvimTreeCollapse<CR>', { desc = 'collapse explorer' })
    vim.keymap.set('n', '<leader>er', '<cmd>NvimTreeRefresh<CR>', { desc = 'refresh file explorer' })
  end,
}
