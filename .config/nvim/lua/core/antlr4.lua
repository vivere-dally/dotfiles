local M = {}

-- A split parser grammar reads the .tokens file of its lexer through tokenVocab,
-- so ANTLR must process the lexer in the same run, before the parser.
local function grammars(path)
  local lexer = (path:gsub('Parser%.g4$', 'Lexer.g4'))
  if lexer ~= path and vim.uv.fs_stat(lexer) then return { lexer, path } end
  return { path }
end

function M.linter()
  local path = vim.api.nvim_buf_get_name(0)
  local dir = vim.fs.dirname(path)
  -- ANTLR generates a recognizer on each run. Keep it out of the project.
  local args = { '-o', vim.fn.stdpath('cache') .. '/antlr4' .. dir, '-Xexact-output-dir' }
  vim.list_extend(args, grammars(path))
  return {
    cmd = 'antlr4',
    args = args,
    stdin = false,
    append_fname = false,
    stream = 'both',
    ignore_exitcode = true,
    parser = function(output, bufnr)
      -- ANTLR names the file without its directory and counts columns from 0.
      local parse = require('lint.parser').from_pattern(
        '^(%a+)%((%d+)%): ([^:]+):(%d+):(%d+): (.+)$',
        { 'severity', 'code', 'file', 'lnum', 'col', 'message' },
        { error = vim.diagnostic.severity.ERROR, warning = vim.diagnostic.severity.WARN },
        { source = 'antlr4' },
        { col_offset = 0 }
      )
      return parse(output, bufnr, dir)
    end,
  }
end

local result_buffer

local function show(lines)
  if not (result_buffer and vim.api.nvim_buf_is_valid(result_buffer)) then
    result_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(result_buffer, 'antlr4-parse://result')
  end
  vim.api.nvim_buf_set_lines(result_buffer, 0, -1, false, lines)
  if vim.fn.bufwinid(result_buffer) == -1 then
    local window = vim.api.nvim_open_win(result_buffer, false, { split = 'below', height = 10 })
    vim.wo[window].wrap = true
  end
end

function M.parse(opts)
  local input = opts.fargs[2] or vim.fn.expand('#:p')
  if input == '' then
    vim.notify('GrammarParse: give an input file, or open one as the alternate file', vim.log.levels.ERROR)
    return
  end
  local cmd = vim.list_extend({ 'antlr4-parse' }, grammars(vim.api.nvim_buf_get_name(0)))
  vim.list_extend(cmd, { opts.fargs[1], '-tree', vim.fn.fnamemodify(input, ':p') })
  vim.system(cmd, { text = true }, vim.schedule_wrap(function(result)
    show(vim.split(result.stdout .. result.stderr, '\n', { trimempty = true }))
  end))
end

function M.complete(lead, cmdline)
  if #vim.split(cmdline, '%s+', { trimempty = true }) > (lead == '' and 1 or 2) then
    return vim.fn.getcompletion(lead, 'file')
  end
  local rules = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local rule = line:match('^(%l[%w_]*)%s*:') or line:match('^(%l[%w_]*)%s*$')
    if rule and vim.startswith(rule, lead) then table.insert(rules, rule) end
  end
  return rules
end

return M
