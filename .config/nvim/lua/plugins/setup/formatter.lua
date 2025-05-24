local ok, conform = pcall(require, 'conform')
if not ok then
  print('conform not installed')
  return
end

conform.setup({
  formatters_by_ft = {
    javascript = { 'prettier' },
    typescript = { 'prettier' },
    javascriptreact = { 'prettier' },
    typescriptreact = { 'prettier' },
    svelte = { 'prettier' },
    css = { 'prettier' },
    html = { 'prettier' },
    json = { 'prettier' },
    yaml = { 'prettier' },
    markdown = { 'prettier' },
    graphql = { 'prettier' },
    lua = { 'stylua' },
    python = { 'black' },
    php = { 'php_cs_fixer' },
    sql = { 'sqlfluff' },
  },
})
