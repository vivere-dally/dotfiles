return {
  'linux-cultist/venv-selector.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'mfussenegger/nvim-dap',
    { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } },
  },
  lazy = false,
  branch = 'regexp', -- This is the regexp branch, use this for the new version
  config = function()
    local prevVenv = nil
    local function on_venv_activate()
      local venv = require('venv-selector').venv()
      if venv == prevVenv then
        return
      end

      local ok, lint = pcall(require, 'lint')
      if not ok then
        print('lint not installed')
        return
      end

      local pylint = lint.linters.pylint
      pylint.args = {
        '-f',
        'json',
        '--init-hook',
        venv,
      }

      prevVenv = venv
    end

    require('venv-selector').setup({
      settings = {
        options = {
          on_venv_activate_callback = on_venv_activate,
        },
      },
    })
  end,
}
