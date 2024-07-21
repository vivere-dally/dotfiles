return {
  'Wansmer/treesj',
  dependencies = { 'nvim-treesitter/nvim-treesitter' },
  keys = {
    {
      '<leader>cj',
      function()
        require('treesj').join()
      end,
      { desc = 'code block join' },
    },
    {
      '<leader>cs',
      function()
        require('treesj').split()
      end,
      { desc = 'code block split' },
    },
  },
  opts = {
    use_default_keymaps = false,
  },
}
