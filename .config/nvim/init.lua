-- Byte-compiled module cache. Off by default, and vim.pack does not turn it on.
vim.loader.enable()

-- Before any plugin, so their <leader> mappings use it
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Enables 24-bit RGB color in the |TUI|
vim.opt.termguicolors = true

require('core')

-- The PackChanged hook in lua/pack.lua must exist before the first vim.pack.add().
local pack = require('pack')

-- Order matters: colors first, and snacks before the groups that call Snacks.
-- Each group adds its plugins with vim.pack.add(), then sets them up.
for _, group in ipairs({ 'colors', 'snacks', 'file', 'git', 'intellisense', 'lsp', 'ml', 'python', 'debug' }) do
  -- One broken group must not stop the others from loading.
  local ok, err = xpcall(require, debug.traceback, 'plugins.' .. group)
  if not ok then
    table.insert(pack.failed, group)
    vim.schedule(function()
      vim.notify(('plugins.%s: %s'):format(group, err), vim.log.levels.ERROR)
    end)
  end
end
