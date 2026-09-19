-- What the config needs on top of the built-in vim.pack (Neovim 0.12): build
-- steps, lazy.nvim-style key specs, and the commands that 0.12 does not ship
-- (0.13 adds :packupdate and :packdel). Plugins install into
-- stdpath('data')/site/pack/core/opt, and nvim-pack-lock.json next to init.lua
-- pins each revision; commit it so the other machine installs the same code.
local M = {}

function M.gh(repo)
  return 'https://github.com/' .. repo
end

-- The bootstrap script installs every locked plugin without an interactive
-- prompt. Normal starts still ask before they download a missing plugin.
function M.add(specs)
  return vim.pack.add(specs, { confirm = vim.env.NVIM_BOOTSTRAP ~= '1' })
end

-- Groups whose file raised an error at startup. Their plugins may never have
-- reached vim.pack.add(), so :PackClean would see them as inactive and delete them.
M.failed = {}

-- Build steps: vim.pack has no `build` field. This must exist before the first
-- vim.pack.add(), or it misses the installs that the lockfile triggers. Select by
-- name, not spec.data: a plugin installed from the lockfile has no spec.data.
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('user.pack', { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    -- New parsers are compiled by the install() call in lua/plugins/lsp.lua; an
    -- update must also rebuild the installed ones to match the new queries.
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end,
})

-- Maps lazy.nvim-style key specs: { lhs, rhs, mode = ..., <vim.keymap.set opts> },
-- so that long key lists stay as data next to their plugin.
function M.keys(specs)
  for _, spec in ipairs(specs) do
    local opts = {}
    for k, v in pairs(spec) do
      if type(k) ~= 'number' and k ~= 'mode' then opts[k] = v end
    end
    vim.keymap.set(spec.mode or 'n', spec[1], spec[2], opts)
  end
end

vim.api.nvim_create_user_command('PackUpdate', function(o)
  vim.pack.update(#o.fargs > 0 and o.fargs or nil)
end, { nargs = '*', desc = 'Update plugins; review, then :write to apply' })

-- After a pull that changed nvim-pack-lock.json: vim.pack.add() installs missing
-- plugins at the locked revision, but leaves plugins already on disk where they are.
vim.api.nvim_create_user_command('PackRestore', function()
  vim.pack.update(nil, { target = 'lockfile' })
end, { desc = 'Move plugins to the revisions in nvim-pack-lock.json' })

vim.api.nvim_create_user_command('PackClean', function()
  if #M.failed > 0 then
    vim.notify(
      'Not cleaning: these plugin groups failed at startup: ' .. table.concat(M.failed, ', '),
      vim.log.levels.ERROR
    )
    return
  end
  local names = vim
    .iter(vim.pack.get(nil, { info = false }))
    :filter(function(p)
      return not p.active
    end)
    :map(function(p)
      return p.spec.name
    end)
    :totable()
  if #names == 0 then
    vim.notify('No inactive plugins')
    return
  end
  if vim.fn.confirm('Delete ' .. table.concat(names, ', ') .. '?', '&Yes\n&No', 2) == 1 then vim.pack.del(names) end
end, { desc = 'Delete plugins that no vim.pack.add() names' })

return M
