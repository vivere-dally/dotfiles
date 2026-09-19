local pack = require('pack')

pack.add({
  pack.gh('supermaven-inc/supermaven-nvim'),
  pack.gh('folke/sidekick.nvim'),
})

-- https://github.com/supermaven-inc/supermaven-nvim/blob/main/README.md#configuration
require('supermaven-nvim').setup({})

require('sidekick').setup({
  nes = { enabled = false },
  -- add any options here
  cli = {
    mux = {
      backend = 'tmux',
      enabled = true,
    },
    tools = {
      -- Recent Claude Code defaults to "fullscreen rendering": it draws on the
      -- terminal's *alternate screen* (like vim/htop) and captures the mouse.
      -- That breaks scrolling inside sidekick's tmux pane two ways:
      --   1. alt-screen output never lands in tmux's pane history, so sidekick's
      --      `tmux capture-pane -S -` scrollback dump has nothing to show; and
      --   2. mouse capture eats the wheel before Neovim's scrollback handler.
      -- Forcing Claude's classic renderer restores native tmux scrollback (which
      -- sidekick can dump and page through), and disabling mouse capture keeps the
      -- wheel flowing to Neovim. Trade-off: lose in-app click/select inside Claude.
      claude = {
        cmd = { 'claude' },
        env = {
          CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN = '1',
          CLAUDE_CODE_DISABLE_MOUSE = '1',
        },
      },
    },
  },
})

pack.keys({
  {
    '<tab>',
    function()
      -- if there is a next edit, jump to it, otherwise apply it if any
      if not require('sidekick').nes_jump_or_apply() then
        return '<Tab>' -- fallback to normal tab
      end
    end,
    expr = true,
    desc = 'Goto/Apply Next Edit Suggestion',
  },
  {
    '<c-.>',
    function()
      require('sidekick.cli').toggle()
    end,
    desc = 'Sidekick Toggle',
    mode = { 'n', 't', 'i', 'x' },
  },
  {
    '<leader>al',
    function()
      require('sidekick.cli').toggle()
    end,
    desc = 'Sidekick Toggle CLI',
  },
  {
    '<leader>as',
    function()
      require('sidekick.cli').select()
    end,
    -- Or to select only installed tools:
    -- require("sidekick.cli").select({ filter = { installed = true } })
    desc = 'Select CLI',
  },
  {
    '<leader>ad',
    function()
      require('sidekick.cli').close()
    end,
    desc = 'Detach a CLI Session',
  },
  {
    '<leader>at',
    function()
      require('sidekick.cli').send({ msg = '{this}' })
    end,
    mode = { 'x', 'n' },
    desc = 'Send This',
  },
  {
    '<leader>af',
    function()
      require('sidekick.cli').send({ msg = '{file}' })
    end,
    desc = 'Send File',
  },
  {
    '<leader>av',
    function()
      require('sidekick.cli').send({ msg = '{selection}' })
    end,
    mode = { 'x' },
    desc = 'Send Visual Selection',
  },
  {
    '<leader>ap',
    function()
      require('sidekick.cli').prompt()
    end,
    mode = { 'n', 'x' },
    desc = 'Sidekick Select Prompt',
  },
  -- Example of a keybinding to open Claude directly
  {
    '<leader>ac',
    function()
      require('sidekick.cli').toggle({ name = 'claude', focus = true })
    end,
    desc = 'Sidekick Toggle Claude',
  },
  {
    '<leader>aa',
    function()
      require('sidekick.cli').toggle({ name = 'opencode', focus = true })
    end,
    desc = 'Sidekick Toggle OpenCode',
  },
})
