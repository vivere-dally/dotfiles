local pack = require('pack')

pack.add({ pack.gh('ellisonleao/gruvbox.nvim') })

local gruvbox = require('gruvbox')

-- Bright comments expose stale explanations and give useful rationale the
-- prominence that it has when a person reads the code.
gruvbox.setup({
  italic = {
    strings = false,
    emphasis = false,
    comments = false,
    operators = false,
    folds = false,
  },
  overrides = {
    Comment = { fg = gruvbox.palette.bright_orange, italic = false, bold = true },
    htmlBoldItalic = { italic = false },
    htmlBoldUnderlineItalic = { italic = false },
    htmlUnderlineItalic = { italic = false },
    htmlItalic = { italic = false },
    markdownItalic = { italic = false },
    markdownBoldItalic = { italic = false },
    DashboardFooter = { italic = false },
  },
})

vim.cmd.colorscheme('gruvbox')
