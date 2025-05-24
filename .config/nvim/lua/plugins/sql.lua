return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    { 'tpope/vim-dadbod', lazy = false },
    { 'tpope/vim-dotenv', lazy = false },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    -- Your DBUI configuration
    vim.g.db_ui_use_nerd_fonts = 1

    -- vim.schedule(function()
    --   if vim.fn['DotenvGet'] then
    --     local dbUsr = vim.fn['DotenvGet']('db_user')
    --     local dbPwd = vim.fn['DotenvGet']('db_password')
    --     local dbUrl = vim.fn['DotenvGet']('db_host')
    --     local dbName = vim.fn['DotenvGet']('db_database')
    --     vim.g.db = 'postgres://' .. dbUsr .. ':' .. dbPwd .. '@' .. dbUrl .. ':5432/' .. dbName
    --   end
    -- end)
  end,
}
