# Neovim 0.11.5 to 0.12.5: upgrade research

This document examines the change from Neovim 0.11.5 to Neovim 0.12.5 for the configuration in `.config/nvim` on the branch `unified`.
It lists the incompatible changes (`news-breaking`), the deprecations, the new built-in features, the results of a runtime test, and the changed option defaults.
Other documents cover `vim.pack`, the plugin audit, and the nvim-treesitter `main` branch.

## Summary

| # | Topic | Finding | Config location | Action | Evidence |
| --- | --- | --- | --- | --- | --- |
| 1 | Breaking change | `vim.treesitter.get_parser()` returns `nil` and does not raise an error. Comment.nvim does not expect this. `gcc` fails with `[Comment.nvim] nil` in a buffer that has no parser. | `lua/plugins/snacks.lua:369-385` | Replace Comment.nvim with the built-in `gc` (Neovim 0.10), or patch Comment.nvim. | `doc/news.txt:500-501`, Comment.nvim `lua/Comment/ft.lua:294-300`, runtime test 3.5 |
| 2 | Behavior change | nvim-lspconfig does not define `:LspInfo`, `:LspStart`, `:LspStop`, `:LspRestart`, and `:LspLog` when the built-in `:lsp` command exists. | none (user habit) | Use `:lsp restart`, `:lsp stop`, and `:checkhealth vim.lsp`. | nvim-lspconfig `plugin/lspconfig.lua:6-8`, `doc/lsp.txt:149-165`, runtime test 3.5 |
| 3 | Deprecation (0.12) | `float = true` in `vim.diagnostic.jump()`. Removal in 0.14. | `lua/plugins/lsp.lua:67`, `lua/plugins/lsp.lua:71` | Use `on_jump`, or delete the `[d` and `]d` maps and set `vim.diagnostic.config({ jump = { on_jump = ... } })`. | `doc/deprecated.txt:30`, `lua/vim/diagnostic.lua:1235-1248`, `:checkhealth vim.deprecated` |
| 4 | Deprecation (0.11) | `vim.highlight` is an alias of `vim.hl`. Removal in 2.0. | `lua/core/autocmds.lua:11` | Write `vim.hl.on_yank(...)`. | `doc/deprecated.txt:117`, `lua/vim/_core/editor.lua:1313`, `:checkhealth vim.deprecated` |
| 5 | Deprecation (0.10) | `vim.loop` is an alias of `vim.uv`. Removal in 1.0. | `init.lua:2` | Write `vim.uv.fs_stat`. The `vim.pack` migration removes this block. | `doc/deprecated.txt:165`, `lua/vim/_core/editor.lua:1308-1310` |
| 6 | Deprecation (0.12) | The `buffer` key of `vim.keymap.set()` has the new name `buf`. 0.12.5 gives no warning. | 21 calls, see 1.2 | Optional: rename to `buf`. Neovim 0.11 does not know `buf`. | `doc/deprecated.txt:60`, `lua/vim/keymap.lua:88-93` |
| 7 | New default maps | `grt` and `grx` join `grn`, `gra`, `grr`, and `gri`. The buffer-local `gr` map waits for `'timeoutlen'`. which-key reports the overlap. | `lua/plugins/lsp.lua:27` | Delete the `gr` map and use `grr`, or add `nowait = true`. | `doc/news.txt:150-152`, `doc/map.txt:198-204`, `:checkhealth which-key` |
| 8 | Replacement (full) | Built-in `van`, `an`, and `in` select tree-sitter nodes and keep a history. | `lua/plugins/lsp.lua:316-365` | Delete the custom code, or map `<C-Space>` and `<BS>` to the built-in functions. | `doc/news.txt:409-412`, `doc/treesitter.txt:613-635`, runtime test 3.5 |
| 9 | Replacement (partial) | `'autocomplete'`, `'pumborder'`, and LSP completion. | blink.cmp, `lua/plugins/intellisense.lua` | Keep blink.cmp. Built-in completion has no Rust fuzzy matcher and no lazydev source. | `doc/news.txt:225-231`, `doc/news.txt:325-346` |
| 10 | Replacement (partial) | LSP inline completion. | supermaven-nvim, `lua/plugins/ml.lua:3-8` | The built-in feature works only with an LSP server, for example Copilot. Supermaven has no LSP server. | `doc/lsp.txt:2388-2428` |
| 11 | Runtime test | The locked plugins (pass A) and the latest plugins (pass B) start without an error under 0.12.5. The results of the two passes are the same. | all | No action for startup. | section 3 |
| 12 | Health | nvim-treesitter must have tree-sitter-cli 0.26.1 or later. The machine has 0.25.10 from npm. The parsers compiled correctly in the test. | `lua/plugins/lsp.lua:245-367` | See the nvim-treesitter research. | nvim-treesitter `README.md:19-21`, `lua/nvim-treesitter/health.lua:10` |
| 13 | Health | 29 (pass A) or 30 (pass B) `Unknown filetype` warnings. This check is new in 0.12.2. It comes from the filetype lists of nvim-lspconfig. | none | No action. | `lua/vim/lsp/health.lua:253`, section 3.6 |
| 14 | Option default | `'shada'` adds `r/tmp/,r/private/`. Neovim keeps no marks and no `:oldfiles` entries for these paths. | `lua/core/autocmds.lua:42-53` | No action. Know that the cursor restore does not work for these paths. | `doc/options.txt:5396`, `doc/news.txt:153` |
| 15 | Default statusline | The new default statusline shows diagnostics and progress. lualine replaces it. | `lua/plugins/snacks.lua:387-614` | Keep lualine, or write a statusline expression. | `doc/news.txt:142-147` |

## Method and sources

The citations use these short forms:

- `doc/...`, `ftplugin/...`, and `lua/vim/...` refer to the runtime directory of Neovim 0.12.5, for example `doc/news.txt:500`. The files are the same as https://github.com/neovim/neovim/tree/v0.12.5/runtime. A byte comparison of 18 cited files found no difference.
- `init.lua`, `lua/core/...`, `lua/plugins/...`, and `lsp/...` refer to `.config/nvim` on the branch `unified` at commit `edeb72b`.
- A plugin file has the plugin name and the commit, for example Comment.nvim `e30b7f2`. The URL form is `https://github.com/<owner>/<repo>/blob/<commit>/<path>#L<line>`.
- `sandbox/` refers to `/private/tmp/claude-504/-Users-s-ved-repos-me-dotfiles/ab6923e3-134a-4336-a1e2-0d2bd3791268/scratchpad/nvim-research/upgrade/`. This directory keeps the logs and the test scripts.

The notes of the patch releases come from the GitHub releases of Neovim. Each release page links to one changelog commit:

- 0.12.0: https://github.com/neovim/neovim/commit/fc7e5cf6c93fef08effc183087a2c8cc9bf0d75a
- 0.12.1: https://github.com/neovim/neovim/commit/7ac5a26d5633a41d7e291141488ca635242973a5
- 0.12.2: https://github.com/neovim/neovim/commit/4b35336f6f850ce68a230716401cdaa21bdb6a25
- 0.12.3: https://github.com/neovim/neovim/commit/35b57441b0bac035dcfc591830e82abc560720b1
- 0.12.4: https://github.com/neovim/neovim/commit/68ea43cd0c28af25cd47731308c94fedfcfd1b0b
- 0.12.5: https://github.com/neovim/neovim/commit/5885a30e1e1225349079e7a1c4a3848aa8e43e42

## 1. Breaking changes, removals, and deprecations

### 1.1 How 0.12.5 reports a deprecated call

`vim.deprecate()` records each call of a deprecated Neovim function for `:checkhealth vim.deprecated` (`lua/vim/_core/editor.lua:1259-1262`).
It shows a message only from one minor version before the removal version (`lua/vim/_core/editor.lua:1264-1288`).
Thus, under 0.12, a function with removal version 0.13 shows a message.
A function with removal version 0.14 or 2.0 shows no message, and only the health report lists it.
The runtime test confirmed this behavior: the two deprecations of this config appear only in `:checkhealth vim.deprecated`.

### 1.2 Items that touch this config

| Item | 0.12.5 source | Config lines | Result under 0.12.5 | Action |
| --- | --- | --- | --- | --- |
| `vim.treesitter.get_parser()` returns `nil` on failure | `doc/news.txt:500-501` | No direct call. Comment.nvim runs it for `gc`, `gcc`, `gb`, and `gbc` (`lua/plugins/snacks.lua:369-385`). | `gcc` in a `conf` buffer leaves the line unchanged and shows `[Comment.nvim] nil`. Neovim 0.11.5 toggles the comment. | Replace Comment.nvim, see 2.2. |
| `float` in `vim.diagnostic.JumpOpts` | `doc/deprecated.txt:30`, `lua/vim/diagnostic.lua:1235-1248` | `lua/plugins/lsp.lua:67`, `lua/plugins/lsp.lua:71` | Works. The health report shows `opts.float is deprecated`. Removal in 0.14. | See the code block below. |
| `vim.highlight` | `doc/deprecated.txt:117`, `lua/vim/_core/editor.lua:1313`, `lua/vim/_core/shared.lua:1481-1497` | `lua/core/autocmds.lua:11` | Works. The health report shows `vim.highlight is deprecated`. Removal in 2.0.0. | `vim.hl.on_yank({ higroup = 'IncSearch', timeout = 150 })` |
| `vim.loop` | `doc/deprecated.txt:165`, `lua/vim/_core/editor.lua:1308-1310` | `init.lua:2` | Works. Plain alias, no message, no health entry. Removal in 1.0. | `vim.uv.fs_stat(lazypath)` |
| `buffer` in `vim.keymap.set.Opts` | `doc/deprecated.txt:60`, `lua/vim/keymap.lua:88-93` | `lua/plugins/lsp.lua:9`, `13`, `17`, `21`, `25`, `29`, `33`, `38`, `41`, `51`, `52`, `57`, `60`, `64`, `68`, `72`, `lua/plugins/git.lua:25`, `29`, `38`, `lua/core/autocmds.lua:64`, `lua/plugins/snacks.lua:725` | Works. The source has a TODO to deprecate the key in 0.13 and remove it in 0.15. No message and no health entry. | Optional rename to `buf`. The `buf` key exists in 0.12.0 and later (neovim commit `4d3a67cd6201`, #38360). Neovim 0.11.5 does not know it. |
| New default maps `grt` and `grx` | `doc/news.txt:150-152`, `lua/vim/_core/defaults.lua:204-229` | `lua/plugins/lsp.lua:27` (`gr`), `lua/plugins/lsp.lua:23` (`go`, same function as `grt`) | `gr` waits for more keys. which-key reports `<gr> overlaps with <grr>, <gra>, <gri>, <grn>, <grt>, <grx>`. | Delete `gr` and `go`, and use `grr` and `grt`. |
| `'shelltemp'` default is off | `doc/news.txt:77`, `doc/options.txt:5681-5692` | `init.lua:3`, `lua/plugins/debug.lua:212`, `269`, `339` (`vim.fn.system()`), `lua/core/keymaps.lua:38` (`:!chmod`) | No effect. `system()` always uses pipes. `:!cmd` without a range is not a filter command. | No action. |
| `vim.diff` has the new name `vim.text.diff` | `doc/news.txt:72`, `lua/vim/text.lua:75-78` | none | No effect on the config. `vim.text.diff()` calls `vim.diff()`, and `vim.diff()` gives no message. | No action. |

Replacement for the `float` option, with the same result as the compatibility code in `lua/vim/diagnostic.lua:1240-1246`:

```lua
vim.diagnostic.config({
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({ bufnr = bufnr, scope = 'cursor', focus = false })
    end,
  },
})
```

With this config, the default `[d` and `]d` maps (`lua/vim/_core/defaults.lua:263-269`) also open the float.
Thus you can delete the maps at `lua/plugins/lsp.lua:66-72`.
The `on_jump` field of `vim.diagnostic.Opts.Jump` is in `lua/vim/diagnostic.lua:329-332` and `doc/diagnostic.txt:191-209`.

### 1.3 Items with no hit in this config

A search of `.config/nvim` found no use of these items:

| Item | 0.12.5 source | Note |
| --- | --- | --- |
| `nvim_get_commands()` returns `complete` as a Lua function | `doc/news.txt:20-21` | none |
| `ui-messages` events changed | `doc/news.txt:22-23`, `doc/news.txt:49-54` | No external message UI in the config. |
| `:sign-define` for diagnostic signs removed | `doc/news.txt:27-28` | none |
| `vim.diagnostic.disable()` and `vim.diagnostic.is_disabled()` removed | `doc/news.txt:29-30` | snacks.nvim `lua/snacks/toggle.lua:226-230` tries `is_enabled` first. |
| Legacy `vim.diagnostic.enable()` signature | `doc/news.txt:31-32` | none |
| `vim.diagnostic.Opts.Status.format` table form (0.12.3) | `doc/news.txt:33-34` | none |
| `i_CTRL-R` inserts text literally | `doc/news.txt:38-40` | `lua/core/keymaps.lua:112-113` use `CTRL-R` in the command line, not in Insert mode. |
| RFC3986 buffer names | `doc/news.txt:41-42` | none |
| LSP `vim.NIL` for JSON `null` | `doc/news.txt:58-59` | none |
| `vim.lsp.semantic_tokens.start()` and `stop()` renamed | `doc/news.txt:62`, `doc/deprecated.txt:44-45` | `lsp/zls.lua:7` is a zls server option, not this function. |
| `client.attached_buffers[buf]` holds a string | `doc/news.txt:68` | none |
| `offset!` directive and `Query:iter_matches()` option `all` removed | `doc/news.txt:88-94` | none. mini.surround `v0.18.0` `lua/mini/surround.lua:1615` and nvim-dap-go `b442115` `lua/dap-go-ts.lua:92` still give `{ all = true }`. `Query:iter_matches()` ignores the key (`lua/vim/treesitter/query.lua:1045-1062`). |
| Autocommand key `buffer` renamed to `buf` | `doc/deprecated.txt:20-25` | The `nvim_create_autocmd()` calls of the config give no `buffer` key. |
| Decoration provider `on_line` | `doc/deprecated.txt:26` | none |
| LSP functions deprecated in 0.12 | `doc/deprecated.txt:39-55` | none |
| `shellmenu` removed and `tohtml` is opt-in | `doc/news.txt:81-83` | none |
| 0.12.2: `is_pull` argument restored, `vim.pos` must get `buf` | 0.12.2 changelog, section BREAKING | none |
| 0.12.5: `:restart` and `ZR` restore the session | 0.12.5 changelog, section BREAKING | none |

### 1.4 Deprecated calls inside the plugins

The runtime test shows no deprecation message from a plugin.
A static search of the plugin clones found these calls.
They are for the plugin audit, and this list is not complete:

- Comment.nvim `e30b7f2` `lua/Comment/ft.lua:294-300` expects an error from `get_parser()`. Under 0.12 the call gives `true, nil`, and `ft.contains(nil, ...)` fails at `lua/Comment/ft.lua:280`. The latest Comment.nvim commit is still `e30b7f2`, from 2024-06-09.
- nvim-dap-virtual-text `fbdb48c` `lua/nvim-dap-virtual-text/virtual_text.lua:106-109` has the same pattern. Only a debug session runs this code. Not verified at runtime.
- nvim-dap-go `b442115` `lua/dap-go-ts.lua:165` calls `vim.lsp.buf_get_clients()`. The removal version is 0.12 (`lua/vim/lsp.lua:1542`), thus the call shows a message. Only `get_root_dir()` runs this code. Not verified at runtime.
- nvim-lspconfig `3371bf2` `plugin/lspconfig.lua:225-236` calls `client.stop()` and `lsp.get_buffers_by_client_id()`. Under 0.12 this code does not run, because the file stops at lines 6-8.

### 1.5 Patch releases 0.12.1 to 0.12.5

The patch releases add no removal that touches this config.
These fixes and changes are relevant:

- 0.12.2 renames `buffer` to `buf` in the API (`ed47b27ad4c0`) and adds a check of the filetype registry to `:checkhealth vim.lsp` (`df726644b8e4`). This check makes the `Unknown filetype` warnings of section 3.6.
- 0.12.2 changes the default `'titlestring'` to show the current directory (`4d4e19644748`).
- 0.12.3 adds `vim.treesitter.select()` (`a0dcdcd8a0e9`) and restricts `vim.pack` to strict semver tags (`dd95e434e398`).
- 0.12.4 changes the LSP semantic tokens (`fec4045601c7`, `fded370b3ec4`, `822d96969b6c`). `lsp/gopls.lua:33` sets `semanticTokens = true`.
- 0.12.5 makes `TSHighlighter.new()` idempotent for an active buffer (`ebcb61b0f9d4`). This matters because the markdown ftplugin starts tree-sitter (`ftplugin/markdown.lua:1`), and `lua/plugins/lsp.lua:291-314` starts it again.
- 0.12.5 bumps the bundled tree-sitter library to v0.26.13 (`06546b403904`).

## 2. New built-in features that can replace a plugin or a part of the config

### 2.1 Features from the 0.12 release notes

| 0.12 feature | Source | Plugin or config part | Replacement | Note |
| --- | --- | --- | --- | --- |
| `vim.pack` plugin manager | `doc/news.txt:374`, `doc/pack.txt:208-234` | lazy.nvim, `init.lua:1-23` | Partial | `doc/pack.txt:210-211` calls it experimental. See the `nvim-vim-pack` research. |
| Incremental selection: `v_an`, `v_in`, `v_]n`, `v_[n`, `v_]N`, `v_[N`, `vim.treesitter.select()` | `doc/news.txt:409-412`, `doc/treesitter.txt:613-635`, `doc/treesitter.txt:1158-1166` | `lua/plugins/lsp.lua:316-365` (`<C-Space>`, `<BS>`) | Full | The test gave the same range for `<C-Space>` and `van` (line 7, columns 3 to 45). `in` goes back through a history (`lua/vim/treesitter/_select.lua:9`, `lua/vim/treesitter/_select.lua:468-480`). The keys are different. |
| LSP `textDocument/selectionRange` | `doc/news.txt:249-250` | Same as the row above | Full | `an` and `in` use LSP when the buffer has no parser (`lua/vim/_core/defaults.lua:470-484`). |
| `:Undotree` | `doc/news.txt:376`, `doc/plugins.txt:273-283` | `Snacks.picker.undo()`, `lua/plugins/snacks.lua:338-343` | Partial | `:packadd nvim.undotree` is necessary. It shows a split window, not a picker with a diff preview. |
| Default statusline with `vim.diagnostic.status()`, progress, and `'busy'` | `doc/news.txt:142-147`, `doc/news.txt:441` | lualine.nvim, `lua/plugins/snacks.lua:387-614` | Partial | The default has no git branch, no diff counts, and no LSP client names. `vim.diagnostic.status()` (`doc/diagnostic.txt:1062-1073`) can replace the lualine diagnostics part. |
| `'autocomplete'`, new `'complete'` flags, `'completeopt'` `nearest`, `'pumborder'`, `'pummaxwidth'`, LSP completion `cmp` option | `doc/news.txt:225-231`, `doc/news.txt:325-346`, `doc/insert.txt:1120-1150` | blink.cmp, friendly-snippets, the lazydev source, `lua/plugins/intellisense.lua` | Partial | No Rust fuzzy matcher, no loader for friendly-snippets, and no lazydev source for blink. |
| LSP inline completion | `doc/news.txt:229-231`, `doc/lsp.txt:2388-2428` | supermaven-nvim, `lua/plugins/ml.lua:3-8`. sidekick.nvim NES is off (`lua/plugins/ml.lua:36`). | Partial | It works only with an LSP server that supports `textDocument/inlineCompletion`, for example `copilot` (`lua/plugins/lsp.lua:162`). The provider changes from Supermaven to Copilot. |
| `:lsp` command | `doc/news.txt:232`, `doc/lsp.txt:149-165` | nvim-lspconfig user commands | Full for restart and stop | nvim-lspconfig removes its commands when `:lsp` exists. `:checkhealth vim.lsp` replaces `:LspInfo`. |
| LSP linked editing range | `doc/news.txt:245-246`, `doc/lsp.txt:2509-2531` | nvim-ts-autotag, `lua/plugins/lsp.lua:256`, `lua/plugins/lsp.lua:259` | Partial | It renames the paired tag only when the server supports the request. It does not close a tag. Server support not verified. |
| LSP code lens as virtual lines, `grx`, `vim.lsp.codelens.enable()` | `doc/news.txt:152`, `doc/news.txt:236-237`, `doc/news.txt:292`, `doc/lsp.txt:2071-2088` | `lsp/gopls.lua:26-32` sets gopls code lenses, but the config never shows them. | Not a replacement | Call `vim.lsp.codelens.enable(true)` to show the lenses. |
| `vim.lsp.buf.workspace_diagnostics()` and `format` for `vim.diagnostic.setqflist()` | `doc/news.txt:158-160`, `doc/news.txt:256` | trouble.nvim, `lua/plugins/lsp.lua:369-395` | Partial | The quickfix list can show the same data. It has no tree view. |
| Customize `:checkhealth` with `FileType checkhealth` | `doc/news.txt:377-378` | `lua/core/autocmds.lua:58-67` | Full for `q` | `lua/vim/health.lua:498-509` maps `q` itself. The config map replaces it with `<cmd>close<CR>`, which has no `:bdelete` fallback. |

### 2.2 Earlier built-in features that are relevant now

These features are older than 0.12, but the upgrade makes them relevant:

- The built-in comment operator `gc` (Neovim 0.10, `doc/news-0.10.txt:332`, `doc/various.txt:601-626`) can replace Comment.nvim. It finds the `'commentstring'` of an injected language with tree-sitter. Thus it can also replace the Comment.nvim use of nvim-ts-context-commentstring. It does not give the `gb` block maps. This research did not compare the JSX support.
- The default LSP maps of 0.11 (`grn`, `gra`, `grr`, `gri`, `gO`, `i_CTRL-S`) and `[d`, `]d`, `<C-W>d` duplicate the maps at `lua/plugins/lsp.lua:7-72`.

### 2.3 New 0.12 features with no counterpart in this config

`ui2` (`doc/news.txt:426-432`), `:DiffTool` (`doc/news.txt:375`), `:restart` (`doc/news.txt:194`), `vim.net.request()` (`doc/news.txt:298`), and LSP document color have no plugin in the lock file.
LSP document colors are on by default (`doc/lsp.txt:2276-2277`).
The health report showed it active for `lua_ls` and `tailwindcss`.

## 3. Runtime test

### 3.1 Setup

The test used the Neovim 0.12.5 binary of the sandbox and a copy of `.config/nvim` for each pass.
Each pass had its own `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, `XDG_CACHE_HOME`, and `HOME` under `sandbox/a/` and `sandbox/b/`.
The test copied the mason directory of the user into each pass with `cp -c` (a copy on write).
The test did not touch the live configuration or the live data directories.

The steps for each pass:

1. Start `nvim --headless "+Lazy! restore" +qa` (pass A) or `nvim --headless "+Lazy! update" +qa` (pass B). The first start clones lazy.nvim and installs the plugins.
2. Install the 43 parsers of `lua/plugins/lsp.lua:270-277` and wait for the end (`sandbox/ts-warmup.lua`).
3. Install `basedpyright` with `:MasonInstall`. The copied mason directory did not have it, and `lua/plugins/lsp.lua:184` asks for it.
4. Open each sample file in a new headless process with `sandbox/driver.lua`. The driver waits for the LSP clients, yanks a line, and runs the `]d` map of the config. It forces a redraw and runs the highlight query over each language tree. Then it writes `:messages` and each `vim.notify()` call to `sandbox/results/<pass>/<file>.txt`.
5. Open all sample files in one process, load all plugins with `:Lazy! load all`, and write `:checkhealth` to `sandbox/results/<pass>/checkhealth.txt`.
6. Run commands and keys of the config with `sandbox/extra.lua` and `sandbox/extra2.lua`: `gcc`, `:LspRestart`, `van`, `<C-Space>`, `<F3>`, `<F4>`, `K`, Oil, fugitive, the Snacks pickers, nvim-dap-ui, harpoon, multicursor, treesj, trouble, vim-maximizer, gitsigns, and blink.cmp completion in Insert mode.

The sample project is `sandbox/samples/proj/`.
It has `main.lua`, `app.py`, `index.ts`, `main.go`, `README.md` with fenced `lua`, `python`, `typescript`, and `bash` blocks, and `.git/COMMIT_EDITMSG`.

The driver makes these changes to get a correct headless test:

- Headless Neovim has no UI, thus lazy.nvim never gets `UIEnter` and never sends `VeryLazy` (lazy.nvim `lua/lazy/core/util.lua:166-194`). The driver sends `UIEnter` once.
- The sandbox `HOME` has no Supermaven activation, thus supermaven-nvim opens an activation popup that takes the focus (supermaven-nvim `07d20fc` `lua/supermaven-nvim/binary/binary_handler.lua:174-180`). The driver closes it. In the key tests of step 6, the driver also stops Supermaven.

### 3.2 Plugin versions

In pass A, each plugin was at the commit of `lazy-lock.json`.
One exception: the bootstrap clone of lazy.nvim wrote its `stable` commit `85c7ff3` (v11.17.5) into the copied lock file before the restore.
The test then set lazy.nvim to the locked commit `306a055` by hand.

In pass B, `Lazy! update` changed 14 of 42 plugins:

| Plugin | Locked | Latest (pass B) |
| --- | --- | --- |
| conform.nvim | `619363c` | `016802d` (2026-08-11) |
| friendly-snippets | `6cd7280` | `b4d01b0` (2026-09-10) |
| gitsigns.nvim | `2038c66` | `8d79f24` (2026-09-16) |
| mason-lspconfig.nvim | `50bf387` | `49b16d6` (2026-09-18) |
| minuet-ai.nvim | `d29dec4` | `3b0a4c5` (2026-08-14) |
| nvim-dap | `9e848e0` | `cfa2d58` (2026-09-11) |
| nvim-dap-ui | `1a66cab` | `cc9dd33` (2026-07-14) |
| nvim-lint | `a219b2c` | `3d55c8f` (2026-08-25) |
| nvim-lspconfig | `3371bf2` | `ffd261c0` (2026-09-18) |
| nvim-nio | `21f5324` | `edcc181` (2026-07-15) |
| nvim-treesitter (`main`) | `4916d65` | `f603a2f4` (2026-09-19) |
| nvim-treesitter-textobjects (`main`) | `851e865` | `5c7b026` (2026-09-03) |
| nvim-web-devicons | `dfbfaa9` | `914decf` (2026-09-18) |
| sidekick.nvim | `208e1c5` | `3d80a47` (2026-09-08) |

A comparison with `git ls-remote` confirmed that each other plugin was at the head of its branch.
Three plugins stay at a release tag because of a `version` field in the spec: blink.cmp at `v1.10.2`, mini.pairs at `v0.18.0`, and mini.surround at `v0.18.0`.
The branch heads of these three plugins have newer commits.
The spec also fixes the branches of telescope.nvim (`0.1.x`), multicursor.nvim (`1.0`), and harpoon (`harpoon2`).

### 3.3 Results for each file

The results were the same in pass A and pass B. The diagnostic sources of `app.py` changed between runs, because pyright starts slowly.
Each file got an active tree-sitter highlighter and the `indentexpr` of nvim-treesitter.

| File | Filetype | LSP clients | Diagnostics | Messages |
| --- | --- | --- | --- | --- |
| `main.lua` | `lua` | copilot, lua_ls, stylua, typos_lsp | lua_ls: 2 | none |
| `app.py` | `python` | basedpyright, copilot, pyright, ruff, typos_lsp | basedpyright, Pyright, Ruff, ruff, bandit | none |
| `index.ts` | `typescript` | copilot, tailwindcss, ts_ls, typos_lsp | typescript: 2, typos: 1 | none |
| `main.go` | `go` | copilot, golangci_lint_ls, gopls, typos_lsp | compiler: 1, typecheck: 1 | `Linter command golangci-lint exited with code: 7` (sandbox only, see 3.4) |
| `README.md` | `markdown` | copilot, tailwindcss, typos_lsp | none | `No more valid diagnostics to move to` (test only) |
| `.git/COMMIT_EDITMSG` | `gitcommit` | copilot, typos_lsp | none | `No more valid diagnostics to move to` (test only) |

The fenced blocks of `README.md` parsed as `lua`, `python`, `typescript`, and `bash` injections.
The highlight queries ran over each injected tree with no error.
Thus the crash that the comment at `lua/plugins/lsp.lua:246-249` describes does not occur with the nvim-treesitter `main` branch under 0.12.5.

### 3.4 Each error and warning, with its cause

| Message | Pass | Cause | Class |
| --- | --- | --- | --- |
| `[Comment.nvim] nil` after `gcc` in a `conf` buffer | A and B | `get_parser()` returns `true, nil` in a `pcall` (`doc/news.txt:500-501`). Comment.nvim `lua/Comment/ft.lua:294-300` then calls `ft.contains(nil, ...)`, which fails at `lua/Comment/ft.lua:280`: `attempt to index local 'tree' (a nil value)`. `lua/Comment/utils.lua:372` prints `err.msg` of a string error, thus the text is `nil`. With the same data, Neovim 0.11.5 toggles the comment. | 0.12 change |
| `E492: Not an editor command: LspRestart lua_ls` | A and B | nvim-lspconfig `plugin/lspconfig.lua:6-8` stops before it defines the commands, because `:lsp` exists. Neovim 0.11.5 runs `:LspRestart` with no error. | 0.12 change |
| `opts.float is deprecated` (health) | A and B | `lua/plugins/lsp.lua:71` (and `lua/plugins/lsp.lua:67`) | 0.12 deprecation |
| `vim.highlight is deprecated` (health) | A and B | `lua/core/autocmds.lua:11` | 0.11 deprecation |
| `Linter command golangci-lint exited with code: 7` | A and B | golangci-lint wrote `typechecking error: directory ... outside main module`. The current directory used the `/tmp` symlink, and the file path used `/private/tmp`. The message did not occur when the test started from `/private/tmp`. | Sandbox only |
| `No more valid diagnostics to move to` | A and B | The driver runs `]d` in a buffer with no diagnostics. | Test only |
| `ENAMETOOLONG` in `vim/loader`, `Failed to run config for Comment.nvim` | first try only | `vim.loader` makes a cache file name from the full path of the module (`lua/vim/loader.lua:119-128`). The long sandbox path made names longer than 255 bytes. Shorter sandbox paths fixed it. | Sandbox only |
| Supermaven activation popup | A and B | No activation under the sandbox `HOME`. | Sandbox only |
| `E492` for `:Trouble` and `:MaximizerToggle` before the first key | A and B | The specs load these plugins on keys only. The keys `<leader>xx` and `<leader>wm` worked. | lazy.nvim design |
| Two Python type checkers | A and B | mason-lspconfig starts each installed server. The mason directory of the user has `pyright`, and `lua/plugins/lsp.lua:184` asks for `basedpyright`. | Config, not 0.12 |

The other commands and keys of step 6 gave no message in either pass.
Hover, code actions, the Snacks pickers, blink.cmp completion with its documentation window, Oil, fugitive, gitsigns, and nvim-dap-ui worked.

### 3.5 Checks of the replacements

- `gcc` on `# sample conf file` in `sample.conf`: Neovim 0.11.5 removed the comment marker. Neovim 0.12.5 left the line unchanged.
- `van` and the config map `<C-Space>` on line 7 of `main.lua` both selected line 7, columns 3 to 45.
- `:checkhealth vim.deprecated` after `yy` and `]d` listed two items in 0.12.5 and one item (`vim.highlight`) in 0.11.5.

### 3.6 `:checkhealth` results

| Section | Result | Cause | Class |
| --- | --- | --- | --- |
| `nvim-treesitter` | ERROR `tree-sitter-cli v0.26.1 is required` | The machine has `tree-sitter` 0.25.10 from npm. nvim-treesitter `4916d65` and `f603a2f4` ask for 0.26.1 or later and for a package manager install (`README.md:19-21`, `lua/nvim-treesitter/health.lua:10`). The parsers compiled correctly in both passes. | Environment, see the nvim-treesitter research |
| `vim.lsp` | 29 (A) or 30 (B) `Unknown filetype` warnings | New check (`lua/vim/lsp/health.lua:253`, 0.12.2 `df726644b8e4`). The filetypes come from nvim-lspconfig: clangd (`c.doxygen`, `cpp.doxygen`), docker_language_server (`yaml.docker-compose`, and `hcl.docker-bake` in pass B), gopls (`gotmpl`), lemminx (`xsl`), superhtml (`superhtml`), tailwindcss (19 filetypes), and yamlls (3 filetypes). | Harmless |
| `vim.lsp` | Different position encodings in `app.py` | ruff uses UTF-8 and the other clients use UTF-16. The check exists in 0.11.5 too. | Not 0.12 |
| `which-key` | 15 overlap warnings | `gr` against the default `gr*` maps, see item 7 of the summary. The other overlaps (`gc`, `gb`, `<leader>x`, `<leader>u`, and the mini.surround keys) are older. | 0.12 adds `grt` and `grx` |
| `vim.deprecated` | OK in the health run, two items after `yy` and `]d` | See 3.4. | 0.12 and 0.11 deprecations |
| `vim.health` | `infocmp -L` failed for `alacritty`, `$TERM` differs from the tmux `default-terminal`, true color not detected | The test shell runs in tmux with `TERM=alacritty`, and the sandbox `HOME` has no `~/.terminfo`. Not verified in a real terminal. | Sandbox or environment |
| `lazy` | Lua 5.1 not found for luarocks | The health report itself says that no plugin uses luarocks. | Environment |
| `mason` | `wget`, `cargo`, and `julia` not found | Tools on the machine | Environment |
| `snacks` | Errors for image tools and for the notifier | The modules are not in use, and the tools are not installed. | Environment |
| `sidekick` | Eight CLI tools not installed | Tools on the machine | Environment |
| `vim.provider` | Python `neovim` package out of date, no Perl and no Ruby host | Tools on the machine | Environment |
| `blink.cmp` | One informational warning about dynamic sources | none | Harmless |

## 4. Options and defaults that changed in 0.12

A dump of the default of each option in 0.11.5 and in 0.12.5 with `--clean` gave the list of changed defaults.
This table shows the changes that interact with `lua/core/options.lua`, `lua/core/keymaps.lua`, or `lua/core/autocmds.lua`:

| Option or default | Change in 0.12 | Config line | Effect | Action |
| --- | --- | --- | --- | --- |
| `'shada'` | Adds `r/tmp/,r/private/` (`doc/options.txt:5396`, `doc/news.txt:153`). Neovim keeps no marks for these paths (`doc/options.txt:5471-5476`). | `lua/core/autocmds.lua:42-53` | The cursor restore does not work for a file under `/tmp/` or `/private/`. `Snacks.picker.recent()` (`lua/plugins/snacks.lua:113-119`) reads `:oldfiles` and does not show these files. | No action, or set `'shada'` to the 0.11 value. |
| `'smartcase'` | Also filters the completion menu (`doc/news.txt:470`, `doc/options.txt:5939-5949`). | `lua/core/options.lua:21-22` | Native completion becomes case sensitive when the typed text has an uppercase letter. blink.cmp does its own filter. | No action. |
| `'maxsearchcount'` | New option, default 999 (`doc/news.txt:342`, `doc/options.txt:4357-4365`). | `lua/core/options.lua:21-23`, `lua/core/keymaps.lua:74-75` | The search count shows exact numbers up to 999. | No action. |
| Default LSP maps `grt`, `grx` | New (`doc/news.txt:150-152`) | `lua/plugins/lsp.lua:23`, `lua/plugins/lsp.lua:27` | See item 7 of the summary. | Delete `gr` and `go`. |
| Default Visual and Operator-pending maps `an`, `in`, `]n`, `[n`, `]N`, `[N` | New (`lua/vim/_core/defaults.lua:454-484`) | `lua/core/keymaps.lua` has no map on these keys | No conflict. | Use them in place of `lua/plugins/lsp.lua:316-365`. |
| `q` in the checkhealth buffer | New built-in map (`lua/vim/health.lua:498-509`) | `lua/core/autocmds.lua:59-66` | The config map replaces the built-in map. `<cmd>close<CR>` fails in the last window, but the built-in map calls `:bdelete` in that case. | Remove `checkhealth` from the pattern at `lua/core/autocmds.lua:61`. |
| `'background'` re-query after a resume | The TUI asks the terminal again and can change `'background'` (`doc/news.txt:421-422`) | `lua/core/options.lua:35` | No effect. The explicit value deletes the autocommand that updates `'background'` (`lua/vim/_core/defaults.lua:947-963`). The test showed `last_set_sid=3` (the options file), not the Lua default. | No action. |
| Clipboard tool order | tmux only inside tmux, and `g:clipboard` accepts a name (`doc/news.txt:347-348`) | `lua/core/options.lua:46` | No effect on macOS. `pbcopy` comes first (`doc/provider.txt:183-197`). | No action. |
| `'shelltemp'` off | `doc/news.txt:77` | `lua/core/keymaps.lua:38` | No effect, see 1.2. | No action. |
| `'winborder'` | Adds `bold` and a custom style (`doc/news.txt:344`, `doc/options.txt:7513-7528`) | `lua/core/options.lua:48` | No effect on `single`. | No action. If you use native completion, set `'pumborder'` to `single` too. |
| `vim.highlight.on_yank()` | See 1.2 | `lua/core/autocmds.lua:11` | Works with a health entry. | Write `vim.hl.on_yank()`. |
| `buffer` key in `vim.keymap.set()` | See 1.2 | `lua/core/autocmds.lua:64` | Works with no message. | Optional rename to `buf`. |
| `<Esc>` map that closes all floats | `ui2` shows messages in floating windows (`doc/news.txt:426-432`). `ui2` is off by default. | `lua/core/keymaps.lua:11-16` | No effect now. With `ui2` on, `<Esc>` closes the message windows too. | Examine this map before you turn on `ui2`. |

These changed defaults have no interaction with the three core files:

- `'diffopt'` adds `indent-heuristic` and `inline:char` (`doc/options.txt:2190`).
- `'statusline'` has a default expression (`doc/news.txt:142-147`), and lualine replaces it.
- `'messagesopt'` adds `progress:c` (`doc/options.txt:4375`).
- `'exrc'` also reads parent directories (`doc/news.txt:148-149`), but the config does not set `'exrc'`.
- `'cdhome'` is on for Unix, and Neovim 0.11.5 already acted like this on Unix (`doc/options.txt:1289-1295`).

## 5. Not verified

- This research did not examine which LSP servers of this config support `textDocument/linkedEditingRange`.
- This research did not compare the built-in `gc` with nvim-ts-context-commentstring for JSX and TSX.
- This research did not examine the `vim.health` terminal errors in a real terminal outside the sandbox.
- The deprecated calls in nvim-dap-virtual-text and nvim-dap-go (1.4) were not run, because the test started no debug session.
