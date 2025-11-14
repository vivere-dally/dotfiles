local bind = vim.keymap.set

bind('n', '<leader>\\', ':nohl<CR>', { desc = 'clear search' })
bind('n', 'x', '"_x', { desc = 'x without copy' })

bind('n', '<leader>+', '<C-a>', { desc = 'increment' })
bind('n', '<leader>-', '<C-x>', { desc = 'decrement' })

-- windows
bind('n', '<leader>we', '<C-w>v', { desc = 'split window veritcally' })
bind('n', '<leader>wq', '<C-w>s', { desc = 'split window horizontally' })
bind('n', '<leader>wr', '<C-w>=', { desc = 'make windows equal' })
bind('n', '<leader>ww', ':close<CR>', { desc = 'close current window' })
bind('n', '<leader>wj', '<C-w>j', { desc = 'move to down window' })
bind('n', '<leader>wk', '<C-w>k', { desc = 'move to up window' })
bind('n', '<leader>wh', '<C-w>h', { desc = 'move to left window' })
bind('n', '<leader>wl', '<C-w>l', { desc = 'move to right window' })

-- tabs
bind('n', '<leader>to', ':tabnew<CR>', { desc = 'new tab' })
bind('n', '<leader>tc', ':tabclose<CR>', { desc = 'close tab' })
bind('n', '<leader>tj', ':tabn<CR>', { desc = 'tab next' })
bind('n', '<leader>tk', ':tabp<CR>', { desc = 'tab prev' })

-- move selection
bind('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'move selection down' })
bind('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'move selection up' })

-- cursor behavior
bind('n', 'J', 'mzJ`z', { desc = 'append to current line' })
bind('n', '<C-d>', '<C-d>zz', { desc = 'hpage jump down cursor middle' })
bind('n', '<C-u>', '<C-u>zz', { desc = 'hpage jump up cursor middle' })
bind('n', 'n', 'nzzzv', { desc = 'next match cursor middle' })
bind('n', 'N', 'Nzzzv', { desc = 'prev match cursor middle' })

bind('x', '<leader>p', '"_dP', { desc = 'paste without losing selection' })

-- yanking
-- still prefer to use the system clipboard always
-- TODO: check options
-- bind("n", "<leader>y", "\"+y", { desc = "yank into system clipboard" })
-- bind("v", "<leader>y", "\"+y", { desc = "yank into system clipboard" })
-- bind("n", "<leader>Y", "\"+Y", { desc = "yank into system clipboard" })

bind('n', '<leader>d', '"_d', { desc = 'delete to void register' })
bind('v', '<leader>d', '"_d', { desc = 'delete to void register' })

bind('n', '<C-j>', '<cmd>cnext<CR>zz', { desc = 'quickfix next' })
bind('n', '<C-k>', '<cmd>cprev<CR>zz', { desc = 'quickfix prev' })
bind('n', '<leader>j', '<cmd>lnext<CR>zz', { desc = 'quickfix next' })
bind('n', '<leader>k', '<cmd>lprev<CR>zz', { desc = 'quickfix prev' })

bind('n', '<leader>x', '<cmd>!chmod +x %<CR>', { desc = 'make file executable', silent = true })

bind('n', '<leader><F2>', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'replace current word' })
bind('n', '<leader><F9>', [[:%s/\r//g]], { desc = 'remove carriage return' })
