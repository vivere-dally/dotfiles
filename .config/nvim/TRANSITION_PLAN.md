# Neovim Configuration Transition Plan

> Generated: 2024-12-24
> Goal: Optimize ergonomics, resolve conflicts, improve performance

## Executive Summary

This plan addresses:
- **15 keymap conflicts** that need resolution
- **12 ergonomic improvements** for faster editing
- **4 package optimizations** to reduce redundancy
- **Structure improvements** for maintainability

---

## Phase 1: Critical Keymap Conflict Resolution

These conflicts cause unpredictable behavior and must be fixed first.

### 1.1 mini.surround Prefix Change

**Problem**: Current `ca`, `cd`, `cf`, `cr` mappings conflict with Vim's change operator (`c` + motion).

**Current** → **New**:
| Operation | Current | New | Mnemonic |
|-----------|---------|-----|----------|
| Add surrounding | `ca` | `sa` | **s**urround **a**dd |
| Delete surrounding | `cd` | `sd` | **s**urround **d**elete |
| Find right | `cf` | `sf` | **s**urround **f**ind |
| Find left | `cF` | `sF` | **s**urround **F**ind (left) |
| Highlight | `ch` | `sh` | **s**urround **h**ighlight |
| Replace | `cr` | `sr` | **s**urround **r**eplace |
| Update n_lines | `cn` | `sn` | **s**urround **n** lines |

**File**: `lua/plugins/file.lua` (mini.surround config)

```lua
-- CHANGE FROM:
mappings = {
  add = 'ca',
  delete = 'cd',
  find = 'cf',
  find_left = 'cF',
  highlight = 'ch',
  replace = 'cr',
  update_n_lines = 'cn',
  suffix_last = 'l',
  suffix_next = 'n',
}

-- CHANGE TO:
mappings = {
  add = 'sa',
  delete = 'sd',
  find = 'sf',
  find_left = 'sF',
  highlight = 'sh',
  replace = 'sr',
  update_n_lines = 'sn',
  suffix_last = 'l',
  suffix_next = 'n',
}
```

### 1.2 Multicursor `<leader>s` Conflict

**Problem**: `<leader>s` (skip match) conflicts with `<leader>s*` search prefix from Snacks.

**Solution**: Change multicursor skip to `<leader>S` (uppercase for skip, lowercase for select/next).

**File**: `lua/plugins/file.lua` (multicursor config)

```lua
-- CHANGE FROM:
{ '<leader>s', mc.skipCursor, mode = { 'n', 'x' }, desc = 'Skip cursor' },

-- CHANGE TO:
{ '<leader>S', mc.skipCursor, mode = { 'n', 'x' }, desc = 'Skip cursor' },

-- Also update the reverse version for consistency:
-- CHANGE FROM:
{ '<leader>S', function() mc.matchCursors({ motion = 'N' }) end, mode = { 'n', 'x' }, desc = 'Match (backwards)' },

-- CHANGE TO:
{ '<leader>P', function() mc.matchCursors({ motion = 'N' }) end, mode = { 'n', 'x' }, desc = 'Match (backwards)' },
```

### 1.3 `<leader>x` Conflict

**Problem**: `<leader>x` is used for both:
- Make file executable (`core/keymaps.lua`)
- Delete main cursor in multicursor mode (`plugins/file.lua`)

**Solution**: Change executable to `<leader>X` (less common operation).

**File**: `lua/core/keymaps.lua`

```lua
-- CHANGE FROM:
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { desc = 'Make file executable' })

-- CHANGE TO:
vim.keymap.set('n', '<leader>X', '<cmd>!chmod +x %<CR>', { desc = 'Make file executable' })
```

---

## Phase 2: Ergonomic Overhaul

These changes optimize for speed and reduce finger travel.

### 2.1 Insert Mode Escape

**Add to**: `lua/core/keymaps.lua`

```lua
-- Quick escape from insert mode (faster than reaching for Esc)
vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exit insert mode' })
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit insert mode (alt)' })
```

### 2.2 Line Navigation Optimization

**Add to**: `lua/core/keymaps.lua`

```lua
-- H/L for line start/end (faster than ^/$)
vim.keymap.set({ 'n', 'x', 'o' }, 'H', '^', { desc = 'Start of line (first char)' })
vim.keymap.set({ 'n', 'x', 'o' }, 'L', '$', { desc = 'End of line' })
```

**Note**: This remaps `H` (high) and `L` (low) screen jumps, but `M` (middle) remains. If you want screen jumps, use `zt`/`zz`/`zb` instead.

### 2.3 Quick Save

**Add to**: `lua/core/keymaps.lua`

```lua
-- Quick save (universal muscle memory)
vim.keymap.set('n', '<C-s>', '<cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('i', '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save file' })
vim.keymap.set('x', '<C-s>', '<Esc><cmd>w<CR>', { desc = 'Save file' })

-- Leader-w as quick save (leader alone with 'w')
vim.keymap.set('n', '<leader>W', '<cmd>w<CR>', { desc = 'Save file' })
```

**Note**: We use `<leader>W` (uppercase) because `<leader>w` is the window prefix.

### 2.4 Quick Close/Quit

**Add to**: `lua/core/keymaps.lua`

```lua
-- Quick buffer close
vim.keymap.set('n', '<leader>q', '<cmd>bdelete<CR>', { desc = 'Close buffer' })
vim.keymap.set('n', '<leader>Q', '<cmd>qa<CR>', { desc = 'Quit all' })
```

### 2.5 Escape Clears Everything

**Replace** in `lua/core/keymaps.lua`:

```lua
-- CHANGE FROM:
vim.keymap.set('n', '<leader>\\', ':nohl<CR>', { desc = 'Clear search highlighting' })

-- CHANGE TO (clears search AND closes floating windows):
vim.keymap.set('n', '<Esc>', function()
  vim.cmd('nohlsearch')
  -- Close floating windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= '' then
      vim.api.nvim_win_close(win, false)
    end
  end
end, { desc = 'Clear search and close floats' })
```

### 2.6 Window Split Mnemonics

**Change** in `lua/core/keymaps.lua`:

```lua
-- CHANGE FROM (unintuitive):
vim.keymap.set('n', '<leader>we', '<C-w>v', { desc = 'Split window vertically' })
vim.keymap.set('n', '<leader>wq', '<C-w>s', { desc = 'Split window horizontally' })

-- CHANGE TO (visual mnemonics):
vim.keymap.set('n', '<leader>w|', '<C-w>v', { desc = 'Split window vertically' })   -- | looks like vertical split
vim.keymap.set('n', '<leader>w-', '<C-w>s', { desc = 'Split window horizontally' }) -- - looks like horizontal split
vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Split window vertically' })   -- v for vertical (alternative)
vim.keymap.set('n', '<leader>ws', '<C-w>s', { desc = 'Split window horizontally' }) -- s for split (alternative)
```

### 2.7 Remove Unnecessary Remaps

**Remove from** `lua/core/keymaps.lua`:

```lua
-- REMOVE THESE (already ergonomic with native Vim):
vim.keymap.set('n', '<leader>+', '<C-a>', { desc = 'Increment number' })  -- C-a is already easy
vim.keymap.set('n', '<leader>-', '<C-x>', { desc = 'Decrement number' })  -- C-x is already easy

-- REMOVE OR CHANGE (breaking expected vim behavior):
vim.keymap.set('n', 'x', '"_x', { desc = 'Delete single character' })
-- If you want void delete, use leader prefix:
vim.keymap.set({ 'n', 'x' }, '<leader>x', '"_x', { desc = 'Delete to void' })
```

### 2.8 Replace Awkward F-key Combos

**Change** in `lua/core/keymaps.lua`:

```lua
-- CHANGE FROM:
vim.keymap.set('n', '<leader><F2>', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word' })
vim.keymap.set('n', '<leader><F9>', [[:%s/\r//g<CR>]], { desc = 'Remove carriage returns' })

-- CHANGE TO (memorable leader combos):
vim.keymap.set('n', '<leader>rw', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = 'Replace word under cursor' })
vim.keymap.set('n', '<leader>rr', [[:%s/\r//g<CR>]], { desc = 'Remove carriage returns' })
```

### 2.9 TreeSJ Block Operations

**Change** in `lua/plugins/file.lua`:

```lua
-- CHANGE FROM (b=buffer confusion):
{ '<leader>bj', ':TSJJoin<CR>', desc = 'Join code block' },
{ '<leader>bs', ':TSJSplit<CR>', desc = 'Split code block' },

-- CHANGE TO (j=join, clearer naming):
{ '<leader>cj', ':TSJJoin<CR>', desc = 'Code join (collapse block)' },
{ '<leader>cs', ':TSJSplit<CR>', desc = 'Code split (expand block)' },
```

---

## Phase 3: LSP Keymap Optimization

### 3.1 Move F-keys to Leader Combos

**Change** in `lua/plugins/lsp.lua`:

```lua
-- CHANGE FROM:
vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, { buffer = bufnr, desc = 'Rename symbol' })
vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })

-- KEEP F-keys but ADD leader alternatives (more accessible):
vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, { buffer = bufnr, desc = 'Rename symbol' })
vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { buffer = bufnr, desc = 'Code rename' })

vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action' })
vim.keymap.set('x', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = 'Code action (visual)' })

-- Format with leader combo too:
vim.keymap.set('n', '<leader>cf', function()
  -- your format function
end, { buffer = bufnr, desc = 'Code format' })
```

### 3.2 Add Commonly Used LSP Maps

**Add to** `lua/plugins/lsp.lua` (in LspAttach):

```lua
-- Quick hover (double-tap K for persistent)
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = 'Hover documentation' })

-- Workspace operations
vim.keymap.set('n', '<leader>cw', vim.lsp.buf.workspace_symbol, { buffer = bufnr, desc = 'Workspace symbols' })

-- Incoming/outgoing calls (useful for understanding code flow)
vim.keymap.set('n', '<leader>ci', vim.lsp.buf.incoming_calls, { buffer = bufnr, desc = 'Incoming calls' })
vim.keymap.set('n', '<leader>co', vim.lsp.buf.outgoing_calls, { buffer = bufnr, desc = 'Outgoing calls' })
```

---

## Phase 4: Package Optimizations

### 4.1 Consider Replacing venv-selector

**Current issue**: Uses Telescope as dependency, but you use Snacks.

**Option A**: Switch to Snacks picker for venv selection

**File**: `lua/plugins/python.lua`

```lua
-- Replace telescope-based picker with Snacks
-- Add custom picker using Snacks API:
vim.keymap.set('n', '<leader>cv', function()
  local venvs = vim.fn.glob('~/.virtualenvs/*/bin/python', false, true)
  -- Add project venvs
  local project_venv = vim.fn.glob(vim.fn.getcwd() .. '/.venv/bin/python', false, true)
  vim.list_extend(venvs, project_venv)

  Snacks.picker.select(venvs, {
    prompt = 'Select Python venv',
  }, function(choice)
    if choice then
      vim.g.python3_host_prog = choice
      vim.notify('Set python to: ' .. choice)
    end
  end)
end, { desc = 'Select Python venv' })
```

**Option B**: Keep venv-selector but accept Telescope dependency (simpler).

### 4.2 Enable nvim-ts-autotag

**File**: `lua/plugins/lsp.lua`

```lua
-- UNCOMMENT (around line 298):
require('nvim-ts-autotag').setup({})
```

This auto-closes HTML/JSX tags and is very useful for web development.

### 4.3 Consolidate Window Management

**Consider removing** `vim-maximizer` and using Snacks or built-in:

```lua
-- Native alternative to vim-maximizer:
vim.keymap.set('n', '<leader>wm', function()
  if vim.t.maximized then
    vim.cmd('wincmd =')
    vim.t.maximized = false
  else
    vim.cmd('wincmd _')
    vim.cmd('wincmd |')
    vim.t.maximized = true
  end
end, { desc = 'Toggle maximize window' })
```

---

## Phase 5: Structure Improvements

### 5.1 Create Autocmds Module

**Create file**: `lua/core/autocmds.lua`

```lua
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Highlight on yank
augroup('YankHighlight', { clear = true })
autocmd('TextYankPost', {
  group = 'YankHighlight',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 150 })
  end,
})

-- Auto-resize splits on window resize
augroup('AutoResize', { clear = true })
autocmd('VimResized', {
  group = 'AutoResize',
  callback = function()
    vim.cmd('tabdo wincmd =')
  end,
})

-- Remove trailing whitespace on save
augroup('TrimWhitespace', { clear = true })
autocmd('BufWritePre', {
  group = 'TrimWhitespace',
  pattern = '*',
  command = [[%s/\s\+$//e]],
})

-- Return to last edit position
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
})
```

**Update** `lua/core/init.lua`:

```lua
require('core.options')
require('core.keymaps')
require('core.autocmds')  -- Add this line
```

---

## Complete Keymap Reference (After Changes)

### Core Navigation & Editing

| Mode | Key | Action |
|------|-----|--------|
| i | `jk` / `jj` | Exit insert mode |
| n,x,o | `H` | Start of line (first char) |
| n,x,o | `L` | End of line |
| n | `<C-d>` | Page down (centered) |
| n | `<C-u>` | Page up (centered) |
| n | `n` / `N` | Next/prev search (centered) |
| n | `<Esc>` | Clear search + close floats |

### File Operations

| Mode | Key | Action |
|------|-----|--------|
| n,i,x | `<C-s>` | Save file |
| n | `<leader>W` | Save file (leader) |
| n | `<leader>q` | Close buffer |
| n | `<leader>Q` | Quit all |
| n | `<leader>X` | Make file executable |

### Window Management

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>w\|` | Split vertical |
| n | `<leader>w-` | Split horizontal |
| n | `<leader>wv` | Split vertical (alt) |
| n | `<leader>ws` | Split horizontal (alt) |
| n | `<leader>wm` | Toggle maximize |
| n | `<leader>ww` | Close window |
| n | `<leader>wr` | Equal size windows |
| n | `<leader>wh/j/k/l` | Navigate windows |

### Surround (NEW PREFIX)

| Mode | Key | Action |
|------|-----|--------|
| n | `sa{motion}{char}` | Add surrounding |
| n | `sd{char}` | Delete surrounding |
| n | `sr{old}{new}` | Replace surrounding |
| n | `sf{char}` | Find surrounding (right) |
| n | `sF{char}` | Find surrounding (left) |
| n | `sh{char}` | Highlight surrounding |

### LSP & Code

| Mode | Key | Action |
|------|-----|--------|
| n | `gd` | Go to definition |
| n | `gr` | List references |
| n | `gi` | List implementations |
| n | `K` | Hover documentation |
| n | `<leader>cr` | Rename symbol |
| n | `<leader>ca` | Code action |
| n | `<leader>cf` | Format code |
| n | `<leader>cj` | Join code block |
| n | `<leader>cs` | Split code block |
| n | `<leader>ci` | Incoming calls |
| n | `<leader>co` | Outgoing calls |

### Search & Replace

| Mode | Key | Action |
|------|-----|--------|
| n | `<leader>rw` | Replace word under cursor |
| n | `<leader>rr` | Remove carriage returns |

### Multicursor (UPDATED)

| Mode | Key | Action |
|------|-----|--------|
| n,x | `<leader>n` | Match & add cursor |
| n,x | `<leader>S` | Skip cursor (was `<leader>s`) |
| n,x | `<leader>N` | Match backwards |
| n,x | `<leader>P` | Skip backwards (was `<leader>S`) |

---

## Implementation Checklist

- [x] **Phase 1**: Conflict Resolution
  - [x] Update mini.surround to `s` prefix
  - [x] Fix multicursor `<leader>s` → `<leader>S`
  - [x] Fix `<leader>x` → `<leader>X` for executable

- [x] **Phase 2**: Ergonomic Overhaul
  - [x] Add `jk`/`jj` insert escape
  - [x] Add `H`/`L` line navigation
  - [x] Add `<C-s>` save mapping
  - [x] Add `<leader>q` quick close
  - [x] Update `<Esc>` to clear search/floats
  - [x] Keep `<leader>we`/`<leader>wq` for splits (user preference)
  - [x] Remove unnecessary `<leader>+/-`
  - [x] Restore `x` default behavior
  - [x] Replace `<leader><F2>/<F9>` with `<leader>rw/rr`
  - [x] Update TreeSJ to `<leader>cj/cs`

- [x] **Phase 3**: LSP Optimization
  - [x] Add `<leader>cr` for rename
  - [x] Add `<leader>ca` for code action
  - [x] Add `<leader>cf` for format
  - [x] Add `<leader>cl` for lint

- [x] **Phase 4**: Package Optimization
  - [ ] Decide on venv-selector approach (optional)
  - [x] Enable nvim-ts-autotag
  - [ ] Optional: Remove vim-maximizer

- [x] **Phase 5**: Structure
  - [x] Create `lua/core/autocmds.lua`
  - [x] Update `lua/core/init.lua`

---

## Muscle Memory Transition Tips

1. **Week 1**: Focus on Phase 1 (conflicts) + `jk` escape + `<C-s>` save
2. **Week 2**: Add `H`/`L` navigation + new surround prefix
3. **Week 3**: Adopt `<leader>c*` LSP commands + `<Esc>` clear
4. **Ongoing**: Reference this document until muscle memory forms

---

## Rollback Plan

If any change causes issues:

1. Git: All changes are tracked, revert specific commits
2. Keep backup: `cp -r ~/.config/nvim ~/.config/nvim.bak`
3. Lazy.nvim: Use `lazy-lock.json` to restore exact plugin versions

---

## Questions / Decisions Pending

1. **venv-selector**: Keep with Telescope dependency or build Snacks-based alternative?
2. **Harpoon slots**: Keep 4 or expand to 5-6 quick slots?
3. **Completion accept**: Keep `<Enter>` or switch to `<Tab>` for accept?

---

*This plan can be implemented incrementally. Each phase is independent and can be done separately.*
