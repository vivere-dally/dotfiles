local bind = vim.keymap.set

-- ============================================================================
-- ESCAPE & CLEAR
-- ============================================================================
-- Quick escape from insert mode
bind('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
bind('i', 'jj', '<Esc>', { desc = 'Exit insert mode (alt)' })

-- Escape clears search highlighting AND closes floating windows
bind('n', '<Esc>', function()
  vim.cmd('nohlsearch')
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= '' then pcall(vim.api.nvim_win_close, win, false) end
  end
end, { desc = 'Clear search and close floats' })

-- ============================================================================
-- LINE NAVIGATION (faster than ^/$)
-- ============================================================================
bind({ 'n', 'x', 'o' }, 'H', '^', { desc = 'Start of line (first char)' })
bind({ 'n', 'x', 'o' }, 'L', '$', { desc = 'End of line' })

-- ============================================================================
-- FILE OPERATIONS
-- ============================================================================
-- Quick save
bind('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save file' })
bind('i', '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save file' })
bind('x', '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save file' })
bind('n', '<leader>W', '<cmd>w<CR>', { desc = 'Save file' })

-- Quick close
bind('n', '<leader>q', '<cmd>bdelete<CR>', { desc = 'Close buffer' })
bind('n', '<leader>Q', '<cmd>qa<CR>', { desc = 'Quit all' })

-- Make file executable
bind('n', '<leader>X', '<cmd>!chmod +x %<CR>', { desc = 'Make file executable', silent = true })

-- ============================================================================
-- WINDOWS
-- ============================================================================
-- Splits
bind('n', '<leader>we', '<C-w>v', { desc = 'Split window vertically' })
bind('n', '<leader>wq', '<C-w>s', { desc = 'Split window horizontally' })
bind('n', '<leader>wr', '<C-w>=', { desc = 'Make windows equal' })
bind('n', '<leader>ww', '<cmd>close<CR>', { desc = 'Close current window' })

-- Window navigation
bind('n', '<leader>wj', '<C-w>j', { desc = 'Move to down window' })
bind('n', '<leader>wk', '<C-w>k', { desc = 'Move to up window' })
bind('n', '<leader>wh', '<C-w>h', { desc = 'Move to left window' })
bind('n', '<leader>wl', '<C-w>l', { desc = 'Move to right window' })

-- ============================================================================
-- TABS
-- ============================================================================
bind('n', '<leader>to', '<cmd>tabnew<CR>', { desc = 'New tab' })
bind('n', '<leader>tc', '<cmd>tabclose<CR>', { desc = 'Close tab' })
bind('n', '<leader>tj', '<cmd>tabn<CR>', { desc = 'Tab next' })
bind('n', '<leader>tk', '<cmd>tabp<CR>', { desc = 'Tab prev' })

-- ============================================================================
-- SELECTION & CURSOR MOVEMENT
-- ============================================================================
-- Move selection up/down
bind('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
bind('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Cursor behavior - keep centered
bind('n', 'J', 'mzJ`z', { desc = 'Append to current line' })
bind('n', '<C-d>', '<C-d>zz', { desc = 'Half-page jump down (centered)' })
bind('n', '<C-u>', '<C-u>zz', { desc = 'Half-page jump up (centered)' })
bind('n', 'n', 'nzzzv', { desc = 'Next match (centered)' })
bind('n', 'N', 'Nzzzv', { desc = 'Prev match (centered)' })

-- ============================================================================
-- REGISTERS & CLIPBOARD
-- ============================================================================
-- Paste without losing selection
bind('x', '<leader>p', '"_dP', { desc = 'Paste without losing selection' })

-- Delete to void register (don't copy)
bind('n', '<leader>d', '"_d', { desc = 'Delete to void register' })
bind('v', '<leader>d', '"_d', { desc = 'Delete to void register' })

-- Delete char to void (use leader prefix to preserve default x behavior)
bind({ 'n', 'x' }, '<leader>x', '"_x', { desc = 'Delete char to void' })

-- ============================================================================
-- QUICKFIX & LOCATION LIST
-- ============================================================================
bind('n', '<C-j>', '<cmd>cnext<CR>zz', { desc = 'Quickfix next' })
bind('n', '<C-k>', '<cmd>cprev<CR>zz', { desc = 'Quickfix prev' })
bind('n', '<leader>j', '<cmd>lnext<CR>zz', { desc = 'Location list next' })
bind('n', '<leader>k', '<cmd>lprev<CR>zz', { desc = 'Location list prev' })

-- ============================================================================
-- TOGGLES
-- ============================================================================
-- Toggle word wrapping (off for coding, on for reading long markdown lines)
bind('n', '<leader>tw', function()
  local wrap = not vim.wo.wrap
  vim.wo.wrap = wrap
  vim.wo.linebreak = wrap -- break at word boundaries, not mid-word
  vim.notify('Wrap ' .. (wrap and 'on' or 'off'))
end, { desc = 'Toggle word wrap' })

-- ============================================================================
-- SEARCH & REPLACE
-- ============================================================================
bind('n', '<leader>rw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word under cursor' })
bind('n', '<leader>rr', [[:%s///gI<Left><Left><Left><Left>]], { desc = 'Replace text in buffer' })
bind('n', '<leader>rc', [[:%s/\r//g<CR>]], { desc = 'Remove carriage returns' })
