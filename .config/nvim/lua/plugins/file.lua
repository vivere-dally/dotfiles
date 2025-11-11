vim.keymap.set('n', '<leader>-', '<cmd>Oil<CR>', { desc = 'Open Oil.nvim' })

return {
  {
    'stevearc/oil.nvim',
    dependencies = {
      { 'nvim-tree/nvim-web-devicons' },
    },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      columns = { 'icon', 'permissions', 'size', 'mtime' },
      view_options = {
        show_hidden = true,
      },
    },
  },
}
