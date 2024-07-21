local opt = vim.opt

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- line wrapping
opt.wrap = false

-- backup
opt.swapfile = false
opt.backup = false

-- search settings
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true

-- scroll
opt.scrolloff = 8
opt.signcolumn = 'yes'
opt.isfname:append('@-@')

-- cursor line
opt.cursorline = true

-- appearence
opt.background = 'dark'
opt.signcolumn = 'yes'

-- backspace
opt.backspace = 'indent,eol,start'

-- split windows
opt.splitright = true
opt.splitbelow = true

-- use system clipboard as default register
-- opt.clipboard:append('unnamedplus')
