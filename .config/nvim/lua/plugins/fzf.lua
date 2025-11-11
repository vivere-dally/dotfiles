return {
  {
    'nvim-mini/mini.pick',
    version = '*',
    config = function()
      require('mini.pick').setup()
    end,

    -- TODO: use folke's picker
  },
}
