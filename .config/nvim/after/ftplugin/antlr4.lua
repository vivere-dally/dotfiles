local antlr4 = require('core.antlr4')

vim.api.nvim_buf_create_user_command(0, 'GrammarParse', antlr4.parse, {
  nargs = '+',
  complete = antlr4.complete,
  desc = 'Parse a file (default: the alternate file) from a start rule and show the tree',
})
