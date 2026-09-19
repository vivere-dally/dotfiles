local M = {}

local function verify_lockfile()
  local path = vim.fs.joinpath(vim.fn.stdpath('config'), 'nvim-pack-lock.json')
  local lines = vim.fn.readfile(path)
  local lock = vim.json.decode(table.concat(lines, '\n')).plugins
  local installed = {}

  for _, plugin in ipairs(vim.pack.get(nil, { info = false })) do
    installed[plugin.spec.name] = plugin.rev
  end

  local mismatched = {}
  for name, entry in pairs(lock) do
    if installed[name] ~= entry.rev then
      table.insert(mismatched, ('%s (wanted %s, found %s)'):format(name, entry.rev, installed[name] or 'missing'))
    end
  end
  table.sort(mismatched)
  if #mismatched > 0 then error('Plugins do not match the lock file: ' .. table.concat(mismatched, ', ')) end
end

function M.run()
  local failed = require('pack').failed
  if #failed > 0 then error('Plugin groups failed: ' .. table.concat(failed, ', ')) end

  -- vim.pack.add() uses the lock for a missing plugin, but an existing checkout
  -- stays at its current revision. A forced lock-file update applies without a
  -- confirmation buffer, which is suitable for the headless bootstrap.
  vim.pack.update(nil, { target = 'lockfile', force = true })
  verify_lockfile()
  vim.cmd('MasonBootstrap')
end

return M
