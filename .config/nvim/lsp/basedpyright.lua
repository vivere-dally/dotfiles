-- Find the nearest virtualenv interpreter, searching upward from `start`.
-- Honours an already-active venv ($VIRTUAL_ENV) first, then looks for a
-- project-local `.venv` / `venv` directory. Returns nil if none is found,
-- in which case pyright falls back to its own auto-detection.
local function find_python(start)
  local active = vim.env.VIRTUAL_ENV
  if active and vim.uv.fs_stat(active .. '/bin/python') then
    return active .. '/bin/python'
  end

  local found = vim.fs.find({ '.venv', 'venv' }, { path = start, upward = true, type = 'directory' })[1]
  if found then
    local py = found .. '/bin/python'
    if vim.uv.fs_stat(py) then
      return py
    end
  end
end

return {
  -- Prefer the Python project root (pyproject.toml etc.) over `.git`. Inner
  -- markers share top priority and are checked first; `.git` is the fallback.
  -- This matters when a repo nests the project below the git root.
  root_markers = {
    { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', 'pyrightconfig.json' },
    '.git',
  },
  before_init = function(_, config)
    local python = find_python(config.root_dir)
    if python then
      config.settings = config.settings or {}
      config.settings.python = config.settings.python or {}
      config.settings.python.pythonPath = python
    end
  end,
}
