local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ============================================================================
-- YANK HIGHLIGHTING
-- ============================================================================
augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
  group = 'YankHighlight',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
  desc = 'Highlight yanked text',
})

-- ============================================================================
-- AUTO-RESIZE SPLITS
-- ============================================================================
augroup('AutoResize', { clear = true })
autocmd('VimResized', {
  group = 'AutoResize',
  callback = function()
    vim.cmd('tabdo wincmd =')
  end,
  desc = 'Auto-resize splits when window is resized',
})

-- ============================================================================
-- TRIM TRAILING WHITESPACE
-- ============================================================================
augroup('TrimWhitespace', { clear = true })
autocmd('BufWritePre', {
  group = 'TrimWhitespace',
  pattern = '*',
  command = [[%s/\s\+$//e]],
  desc = 'Remove trailing whitespace on save',
})

-- ============================================================================
-- RESTORE CURSOR POSITION
-- ============================================================================
augroup('RestoreCursor', { clear = true })
autocmd('BufReadPost', {
  group = 'RestoreCursor',
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
  desc = 'Return to last edit position when opening files',
})

-- ============================================================================
-- CLOSE SPECIAL BUFFERS WITH 'q'
-- ============================================================================
augroup('CloseWithQ', { clear = true })
autocmd('FileType', {
  group = 'CloseWithQ',
  pattern = { 'help', 'qf', 'man', 'notify', 'checkhealth' },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = event.buf, silent = true })
  end,
  desc = 'Close help/quickfix/man with q',
})
