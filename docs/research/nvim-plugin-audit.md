# Neovim plugin audit at the latest versions

This document audits the 42 plugins in `.config/nvim/lazy-lock.json` against the latest version of each plugin on 2026-09-19. The target is Neovim 0.12.5 with `vim.pack`. The summary table comes first. The answers, the details for each plugin, and the new developments come after it.

In the table, `HEAD = lock` means that the locked commit is also the newest commit of the branch in the spec. A date without a label is the commit date.

## Summary table

| Plugin | Locked commit | Latest version | Used by this config | On Neovim 0.12.5 | lazy.nvim features in the spec | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| `Comment.nvim` | `e30b7f2` 2024-06-09 | HEAD = lock (last release `v0.8.0`, 2023) | Yes, default `gc` maps | Partly: error `[Comment.nvim] nil` in a buffer with no parser | `opts`, `config`, `dependencies` | Drop. Use the built-in `gc` |
| `blink.cmp` | `78336bc` 2026-04-04 = `v1.10.2` | `v1.10.2` 2026-04-04 (`main` is the unreleased v2) | Yes | Yes | `version = '1.*'`, `opts`, `opts_extend` | Keep on `1.*` |
| `conform.nvim` | `619363c` 2026-05-24 | HEAD `016802d` 2026-08-11 (`v9.1.0` is older than the lock) | Yes | Yes | `lazy`, `event` | Keep |
| `friendly-snippets` | `6cd7280` 2026-01-23 | HEAD `b4d01b0` 2026-09-10 (no release) | Yes, for the blink snippets source | Yes | dependency | Keep |
| `gitsigns.nvim` | `2038c66` 2026-06-18 | HEAD `8d79f24` 2026-09-16 (`v2.1.0` is older than the lock) | Yes | Yes | `event`, `opts`, a second spec fragment | Keep. Replace `undo_stage_hunk` |
| `gruvbox.nvim` | `154eb5f` 2026-04-15 | HEAD = lock | Yes | Yes | `priority` | Keep |
| `harpoon` | `87b1a35` 2025-10-31 (`harpoon2`) | `harpoon2` HEAD = lock (no release) | Yes | Yes | `branch`, `dependencies` | Keep. Watch `plenary.nvim` |
| `lazy.nvim` | `306a055` 2025-12-17 | HEAD = lock (`v11.17.5` 2025-11-06) | Yes, plugin manager | Yes | not applicable | Drop. Use `vim.pack` |
| `lazydev.nvim` | `ff2cbcb` 2026-03-14 | HEAD = lock (`v1.10.0` 2025-10-23) | Yes | Yes | `ft`, `opts` | Keep. Edit `library` |
| `lualine.nvim` | `221ce6b` 2026-05-31 | HEAD = lock (no release) | Yes | Yes | `dependencies` | Keep |
| `mason-lspconfig.nvim` | `50bf387` 2026-06-26 | HEAD `49b16d6` 2026-09-18 (`v2.3.0` is older than the lock) | Yes | Yes | `opts` (automatic setup) | Keep. Exclude `stylua` and `sqruff` |
| `mason-tool-installer.nvim` | `443f1ef` 2026-01-22 | HEAD = lock (no release) | Yes | Yes | `opts`, `config` | Keep |
| `mason.nvim` | `2a6940a` 2026-06-11 = `v2.3.1` | `v2.3.1` = lock | Yes | Yes | `opts = {}`, two URLs | Keep. Use one URL |
| `mini.pairs` | `4a01414` 2026-06-19 = `v0.18.0` | `v0.18.0` = lock (HEAD `b1c5a72` 2026-07-23) | Yes | Yes | `version = '*'`, `opts` | Keep. Delete the old `neigh_pattern` values |
| `mini.surround` | `580e4cb` 2026-06-19 = `v0.18.0` | `v0.18.0` = lock (HEAD `8d5d0c5` 2026-07-16) | Yes | Yes | `version = '*'`, `opts` | Keep |
| `minuet-ai.nvim` | `d29dec4` 2026-05-27 | `v0.10.0` 2026-07-31 | No, the spec is a comment | Loads | dependency of `blink.cmp` | Drop, or adopt it as the completion provider |
| `multicursor.nvim` | `704b99f` 2026-03-24 (`1.0`) | `1.0` = `main` = lock (no tag) | Yes | Yes | `branch` | Keep on `1.0` |
| `nvim-dap` | `9e848e0` 2026-06-19 | HEAD `cfa2d58` 2026-09-11 (`0.10.0` 2025-03 is older) | Yes | Yes | `dependencies` | Keep |
| `nvim-dap-go` | `b442115` 2025-07-11 | HEAD = lock (no release) | Yes | Loads | dependency | Keep |
| `nvim-dap-python` | `1808458` 2025-12-20 | HEAD = lock (no release) | Yes | Loads | `ft` | Keep |
| `nvim-dap-ui` | `1a66cab` 2026-04-05 | HEAD `cc9dd33` 2026-07-14 (`v4.0.0` 2024 is older) | Yes | Yes | dependency | Keep, or replace with `nvim-dap-view` |
| `nvim-dap-virtual-text` | `fbdb48c` 2025-05-25 | HEAD = lock (no release) | No, `setup()` is a comment | Loads | dependency | Drop, or call `setup()` |
| `nvim-lint` | `a219b2c` 2026-06-25 | HEAD `3d55c8f` 2026-08-25 (no release) | Yes | Yes | `lazy`, `event` | Keep |
| `nvim-lspconfig` | `3371bf2` 2026-06-25 | `v2.11.0` 2026-07-21 (HEAD `ffd261c` 2026-09-18) | Yes, server configs | Yes, but no `:Lsp*` commands | dependency | Keep |
| `nvim-nio` | `21f5324` 2025-01-20 = `v1.10.1` | HEAD `edcc181` 2026-07-15 | Yes, for `nvim-dap-ui` | Yes | dependency | Keep while `nvim-dap-ui` stays |
| `nvim-treesitter` | `4916d65` 2026-04-03 (`main`) | `main` HEAD `f603a2f` 2026-09-19 (no release on `main`) | Yes | Yes. Health wants `tree-sitter-cli` 0.26.1 | `branch`, `build`, `lazy` | Keep. See `nvim-treesitter-main` research |
| `nvim-treesitter-textobjects` | `851e865` 2026-04-07 (`main`) | `main` HEAD `5c7b026` 2026-09-03 | Only `setup({})`, no maps | Yes | `branch`, dependency | Keep only with maps or sidekick context |
| `nvim-ts-autotag` | `88c1453` 2026-04-15 | HEAD = lock (no release) | Yes | Loads | dependency | Keep |
| `nvim-ts-context-commentstring` | `6141a40` 2026-04-04 | HEAD = lock (no release) | Yes, `Comment.nvim` hook | Yes | dependency with `config` | Drop with `Comment.nvim` |
| `nvim-web-devicons` | `dfbfaa9` 2026-05-27 | HEAD `914decf` 2026-09-18 (no release) | Yes, icons | Yes | dependency | Keep |
| `oil.nvim` | `b73018b` 2026-06-02 | HEAD = lock (`v2.16.0` 2026-05-24) | Yes | Yes | `lazy`, `opts` | Keep |
| `plenary.nvim` | `74b06c6` 2026-04-10 | HEAD = lock | Yes, for `harpoon` and `telescope.nvim` | Yes | dependency | Keep only for `harpoon` |
| `sidekick.nvim` | `208e1c5` 2026-04-22 | HEAD `3d80a47` 2026-09-08 (`v2.3.0` is older) | Yes, AI CLI only | Yes | `opts`, `keys` | Keep |
| `snacks.nvim` | `882c996` 2026-05-25 | HEAD = lock (`v2.31.0` 2026-03-20) | Yes | Yes | `opts`, `keys`, `priority`, `Snacks.picker.lazy()` | Keep. Delete `<leader>sp` |
| `supermaven-nvim` | `07d20fc` 2024-10-07 | HEAD = lock (no release) | Yes | Yes, the agent starts | `config` | Replace |
| `telescope.nvim` | `a0bbec2` 2024-05-24 (`0.1.x`) | tag `v0.2.2` 2026-02-16, `master` `40aedd8` 2026-08-17 | Only as a picker for `venv-selector.nvim` | Yes | `branch`, dependency | Drop |
| `treesj` | `79aedb4` 2026-05-28 | HEAD = lock (no release) | Yes | Yes | `keys`, `opts` | Keep |
| `trouble.nvim` | `bd67efe` 2025-10-31 | HEAD = lock (`v3.7.1` 2025-02-12) | Yes | Yes | `opts`, `keys` | Keep, or drop for Snacks pickers |
| `venv-selector.nvim` | `cc4bb39` 2026-05-20 | HEAD = lock (no release) | Yes | Yes, with the Snacks picker | `ft`, `keys`, `opts` | Keep. Set `picker = 'snacks'` |
| `vim-fugitive` | `3b753cf` 2026-03-07 | HEAD = lock (`v3.7` 2022 is older) | Yes | Yes | `lazy`, `event` | Keep |
| `vim-maximizer` | `2e54952` 2015-08-22 | HEAD = lock | Yes | Yes | `keys` | Replace with `Snacks.zen.zoom()` |
| `which-key.nvim` | `3aab214` 2025-10-28 | HEAD = lock (`v3.17.0` 2025-02-22) | Yes | Loads | `event`, `opts`, `keys` | Keep |

## Key findings

1. No plugin is archived on GitHub on 2026-09-19. Two plugins have a statement from the maintainer about the end of work: `plenary.nvim` and the `master` branch of `harpoon`. The Supermaven service has a sunset statement.
2. At the latest versions, one plugin has a known defect on Neovim 0.12: `Comment.nvim`. The sandbox test reproduced the error `[Comment.nvim] nil`. The built-in `gc` commented the same line correctly.
3. Six plugins are not necessary: `Comment.nvim`, `nvim-ts-context-commentstring`, `telescope.nvim`, `minuet-ai.nvim`, `nvim-dap-virtual-text`, and `lazy.nvim`. Two plugins have a replacement that is already installed or built in: `supermaven-nvim` and `vim-maximizer`.
4. Only `venv-selector.nvim` pulls `telescope.nvim`. With `options.picker = 'snacks'`, `:VenvSelect` opened a Snacks picker on 0.12.5.
5. `nvim-lspconfig` is still necessary as a source of server configs. On Neovim 0.12, it does not define `:LspInfo`, `:LspRestart`, and the other `:Lsp*` commands. Use `:lsp` and `:checkhealth vim.lsp`.
6. The `automatic_enable` option of `mason-lspconfig.nvim` also starts `stylua` and `sqruff` as LSP servers. The sandbox showed a `stylua --lsp` client in a Lua buffer. `nvim-lint` and `conform.nvim` already run `sqruff`.
7. The GitHub Copilot language server is in `ensure_installed`, but nothing in the config reads its output. The sidekick NES feature is off, and the built-in inline completion is not active.
8. Between the locked commits and the latest versions, no change breaks this config. The config has three old items: `undo_stage_hunk` (deprecated in `gitsigns.nvim`), `lsp_fallback` (legacy in `conform.nvim`), and the old `neigh_pattern` values of `mini.pairs`.
9. These lazy.nvim features in the specs have no equal in `vim.pack`: `opts` (automatic `setup()`), `opts_extend`, `keys`, `event`, `ft`, `priority`, a spec fragment for `gitsigns.nvim`, and `build`. Two plugin features work only with lazy.nvim: `Snacks.picker.lazy()` and the `lazy.nvim` library entry of `lazydev.nvim`.

## Method

1. Each plugin repository was cloned into the sandbox. The locked commit, the newest tag, and the HEAD of each branch came from `git log` and `git describe` in those clones.
2. The GitHub API gave the archived flag, the latest release, and the pinned issues of each repository on 2026-09-19.
3. The latest version is the newest release tag. If there is no release, or if the lock is newer than the newest release, the latest version is the default branch HEAD.
4. Some specs pin a branch or a version range: `blink.cmp` (`1.*`), `mini.*` (`*`), `multicursor.nvim` (`1.0`), `harpoon` (`harpoon2`), and `nvim-treesitter` (`main`). For these plugins, the latest version is the newest commit in that range.
5. A copy of the config ran on the Neovim 0.12.5 binary with sandbox `XDG_*` directories and no `lazy-lock.json`. `:Lazy! sync` installed the newest commit that each spec permits. The new lockfile matched the "Latest version" column.
6. The copy had three test-only changes. The `vim.loader` cache was off because the sandbox path made the cache file names too long (`ENAMETOOLONG`). The Mason install lists had only `lua_ls` and `stylua`. The parser list was shorter.
7. The test opened Lua, Python, Go, TSX, HTML, and Markdown files. Then it did these actions:
   - `require()` of each plugin
   - `:Oil`, `:Trouble`, `:MaximizerToggle`, `:Git`, and `:VenvSelect`
   - `gcc`, `saiw)`, a `treesj` split, a `harpoon` add, and a `multicursor` add
   - `dapui` open and close, a `stylua` format, Snacks pickers, and `Snacks.zen.zoom()`
   - `:checkhealth`
8. The errors from `nvim-lint` about `ruff`, `bandit`, and `golangci-lint` come from tools that the sandbox did not install. They are not plugin defects.

## Answers to the questions

### Is `telescope.nvim` still necessary?

No. Only `venv-selector.nvim` declares it, as a dependency in `lua/plugins/python.lua:6`. No other spec and no other Lua file in the config refers to `telescope`.

- `venv-selector.nvim` supports these pickers: `telescope`, `fzf-lua`, `snacks`, `mini-pick`, and `vim.ui.select` ([README:37](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/README.md#L37)).
- With `picker = "auto"`, it selects the first installed picker in the order `telescope`, `fzf-lua`, `snacks`, `mini-pick`, `native` ([gui.lua:28-33](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/lua/venv-selector/gui.lua#L28-L33), [gui.lua:72-79](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/lua/venv-selector/gui.lua#L72-L79)). Thus Telescope wins only because it is installed.
- Sandbox result: with `options.picker = 'snacks'`, `:VenvSelect` opened one Snacks picker with two environments (the project `.venv` and a `pyenv` interpreter).
- The `0.1.x` branch has no commit after 2024-05-24. The `master` branch is active and has tag `v0.2.2`. The minimum for `master` is Neovim `>=v0.11.7` ([README:46](https://github.com/nvim-telescope/telescope.nvim/blob/40aedd8/README.md#L46)).
- `venv-selector.nvim` also lists `nvim-lspconfig` as a dependency (`lua/plugins/python.lua:5`). Its source has no reference to `lspconfig`. Its README says that the user configures the servers with `vim.lsp.config` ([README:98](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/README.md#L98)).

Recommendation: remove `telescope.nvim` and its `plenary.nvim` entry from `lua/plugins/python.lua:4-7`. Set `options = { picker = 'snacks' }` in `lua/plugins/python.lua:14`. Keep `plenary.nvim` only because `harpoon` uses it.

### `Comment.nvim` and `nvim-ts-context-commentstring` against the built-in `gc`

The built-in commenting is in Neovim since 0.10 (`runtime/doc/news-0.10.txt:332`). It gives `gc{motion}`, `gcc`, `{Visual}gc`, and the `gc` text object (`runtime/doc/various.txt:601-640` of 0.12.5).

The built-in code gets `'commentstring'` in two steps (`runtime/lua/vim/_comment.lua:8-62` of 0.12.5):

1. It reads the `bo.commentstring` metadata of the treesitter captures at the cursor.
2. If there is no metadata, it uses the `'commentstring'` of the deepest injected language at the cursor.

The `main` branch of `nvim-treesitter` sets `bo.commentstring` to `{/* %s */}` on `jsx_element` ([jsx/highlights.scm:153-157](https://github.com/nvim-treesitter/nvim-treesitter/blob/f603a2f/runtime/queries/jsx/highlights.scm#L153-L157)). Thus the built-in `gc` knows the JSX comment form without an extra plugin.

Sandbox result on 0.12.5 (the line that `gcc` changed):

| Case | Config (`Comment.nvim` and the hook) | Built-in `gc` only | Built-in `gc` and the `get_option` override |
| --- | --- | --- | --- |
| TSX, JSX child line | `{/* <span>hi</span> */}` | `{/* <span>hi</span> */}` | `{/* <span>hi</span> */}` |
| HTML, line in `<script>` | `// let a = 1;` | `// let a = 1;` | `// let a = 1;` |
| Markdown, line in a `lua` code block | `-- local a = 1` | `-- local a = 1` | `-- local a = 1` |
| `conf` file, no parser | error `[Comment.nvim] nil`, line not changed | `# a = 1` | not tested |

- The `Comment.nvim` error is an open upstream issue since 2026-03-20 ([Comment.nvim#517](https://github.com/numToStr/Comment.nvim/issues/517)). The cause is a change in 0.12: `vim.treesitter.get_parser()` returns `nil` when it cannot make a parser (`runtime/doc/news.txt:500-501`). The fix ([PR #518](https://github.com/numToStr/Comment.nvim/pull/518)) is open and not merged.
- `Comment.nvim` has no commit after 2024-06-09. Its help file says `For Neovim version 0.7` ([doc/Comment.txt:1](https://github.com/numToStr/Comment.nvim/blob/e30b7f2/doc/Comment.txt#L1)).
- `nvim-ts-context-commentstring` has fixes for 0.12 ([a681c21](https://github.com/JoosepAlviste/nvim-ts-context-commentstring/commit/a681c21), [0e8937b](https://github.com/JoosepAlviste/nvim-ts-context-commentstring/commit/0e8937b)). Its wiki gives an override of `vim.filetype.get_option` for the built-in commenting ([wiki](https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations#native-commenting-in-neovim-010)). In the tested cases, this override changed nothing.
- The built-in commenting has no block comment. You lose the `gb`, `gbc`, `gco`, `gcO`, and `gcA` maps of `Comment.nvim`. The which-key health report in the sandbox listed these maps.

Recommendation: remove both plugins (`lua/plugins/snacks.lua:369-385`) and use the built-in `gc`. For JSX comments in a language that the tests did not cover, for example Vue or Svelte, add the `get_option` override from the wiki.

### The three AI plugins

| Plugin | Plugin status | Service status | Use in this config |
| --- | --- | --- | --- |
| `supermaven-nvim` | Last commit 2024-10-07. No release. | Sunset on 2025-11-21. Free autocomplete for existing customers "for the foreseeable future". No end date. | Active: `setup({})` in `lua/plugins/ml.lua:2-9` |
| `minuet-ai.nvim` | Active. `v0.10.0` on 2026-07-31. | No own service. It calls an LLM provider with your API key. | Not active: the spec is a comment (`lua/plugins/ml.lua:11-29`), and the blink source is a comment (`lua/plugins/intellisense.lua:102`, `:111-119`) |
| `sidekick.nvim` | Active. Last commit 2026-09-08. | NES needs the GitHub Copilot language server. The CLI part runs local AI CLIs. | CLI part active (`lua/plugins/ml.lua:38-62`, `:76-152`). NES off (`lua/plugins/ml.lua:36`) |

- The Supermaven statement is on the [Supermaven blog](https://supermaven.com/blog/sunsetting-supermaven) (2025-11-21). About Neovim and JetBrains users, it says `We will continue to provide autocomplete inference free for these existing customers`. The post says that the sunset comes one year after the acquisition of Supermaven by Cursor.
- On 2026-09-19, the sandbox downloaded the `sm-agent` binary (`v20`) from `supermaven.com`, and `require('supermaven-nvim.api').is_running()` returned `true`. The test did not examine the quality of the completions. Access for new accounts is not verified.
- The GitHub Copilot server is in `ensure_installed` (`lua/plugins/lsp.lua:162`). Thus `mason-lspconfig.nvim` calls `vim.lsp.enable()` for it. Its config has `root_markers = { '.git' }` and no `filetypes` ([lsp/copilot.lua:107-111](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/lsp/copilot.lua#L107-L111)). A config with no `filetypes` attaches to all filetypes (`runtime/doc/lsp.txt:873-874`). The sandbox did not install this server. The server gives suggestions only when `vim.lsp.inline_completion` is active ([lsp/copilot.lua:17](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/lsp/copilot.lua#L17)). The config has that code only as a comment (`lua/plugins/intellisense.lua:51-60`).
- The `<tab>` map for NES (`lua/plugins/ml.lua:65-75`) only returns `<Tab>` while NES is off.

Overlaps:

- Inline ghost text: `supermaven-nvim`, `minuet-ai.nvim` (virtual text or a blink source), and the built-in `vim.lsp.inline_completion` of 0.12 with the Copilot server (`runtime/doc/news.txt:229-231`, `runtime/doc/lsp.txt:2388-2418`).
- Next edit suggestion: `sidekick.nvim` NES and the `duet` feature of `minuet-ai.nvim` ([minuet README](https://github.com/milanglacier/minuet-ai.nvim/blob/3b0a4c5/README.md#duet-next-edit-prediction)).
- AI CLI in a terminal: only `sidekick.nvim`.

Recommendation: keep `sidekick.nvim`. Remove `minuet-ai.nvim` from the blink dependencies (`lua/plugins/intellisense.lua:20`). Replace `supermaven-nvim` with one inline provider:

1. The Copilot server with the built-in `vim.lsp.inline_completion`. No plugin is necessary, and the server is already installed. A GitHub Copilot account is necessary. A free plan exists ([lsp/copilot.lua:12](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/lsp/copilot.lua#L12)). The same server can also feed sidekick NES.
2. `minuet-ai.nvim` with an Anthropic API key, as in the comment in `lua/plugins/ml.lua:11-29`.

If you select neither option, remove `copilot` from `ensure_installed`.

### `nvim-lspconfig` and `mason-lspconfig.nvim` with `vim.lsp.config` and `vim.lsp.enable`

Neovim 0.11 and 0.12 find `lsp/<name>.lua` files on `'runtimepath'` and merge them. `vim.lsp.enable()` starts the servers (`runtime/doc/lsp.txt:168-180` of 0.12.5).

What `nvim-lspconfig` still adds:

- The `lsp/` directory with the base config of each server: `cmd`, `filetypes`, `root_markers`, and `settings` ([README:11-13](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/README.md#L11-L13)). All 22 server names in this config exist at HEAD, and none is deprecated.
- The files in `.config/nvim/lsp/` change only parts of these configs. `lsp/basedpyright.lua` adds `root_markers` and `before_init`. `lsp/gopls.lua` adds `settings`. `lsp/zls.lua` is complete without `nvim-lspconfig`.
- The legacy `require('lspconfig')` module is deprecated and will be removed ([README:9-10](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/README.md#L9-L10)). This config does not call it.
- The minimum is Nvim 0.11.3 ([README:33](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/README.md#L33)).
- On a Neovim that has the `:lsp` command, `plugin/lspconfig.lua` returns before it defines `:LspInfo`, `:LspStart`, `:LspRestart`, `:LspStop`, and `:LspLog` ([plugin/lspconfig.lua:6-8](https://github.com/neovim/nvim-lspconfig/blob/ffd261c/plugin/lspconfig.lua#L6-L8), commit [45c93f9](https://github.com/neovim/nvim-lspconfig/commit/45c93f91) of 2025-12-16). The locked commit already has this change. Use `:lsp enable`, `:lsp disable`, `:lsp restart`, and `:lsp stop` (`runtime/doc/lsp.txt:149-165`).

What `mason-lspconfig.nvim` still adds ([README:37-42](https://github.com/mason-org/mason-lspconfig.nvim/blob/49b16d6/README.md#L37-L42)):

- `ensure_installed` with `nvim-lspconfig` server names.
- `automatic_enable`: it calls `vim.lsp.enable()` for each installed Mason package that maps to a server name. The default is `true`.
- The `:LspInstall` command and the translation between the two name sets.
- Extra configs for some servers. None of them is a server of this config.
- The minimum is `neovim >= 0.11.0`, `mason.nvim >= 2.0.0`, and `nvim-lspconfig >= 2.0.0` ([README:54-56](https://github.com/mason-org/mason-lspconfig.nvim/blob/49b16d6/README.md#L54-L56)).

A finding for this config: the Mason registry maps the packages `stylua` and `sqruff` to server names ([mappings.lua:11-19](https://github.com/mason-org/mason-lspconfig.nvim/blob/49b16d6/lua/mason-lspconfig/mappings.lua#L11-L19), registry version `2026-09-19-furry-weed`). `mason-tool-installer.nvim` installs both tools for formatting and linting (`lua/plugins/lsp.lua:208-209`). As a result, `automatic_enable` starts both as LSP servers. In the sandbox, `:checkhealth vim.lsp` listed a `stylua` client with the command `{ "stylua", "--lsp" }`.

Recommendation:

1. Keep `nvim-lspconfig`. Without it, you must write the base config of about 20 servers.
2. Keep `mason-lspconfig.nvim` and set `automatic_enable = { exclude = { 'stylua', 'sqruff' } }` ([README:101-111](https://github.com/mason-org/mason-lspconfig.nvim/blob/49b16d6/README.md#L101-L111)).
3. An alternative is to drop `mason-lspconfig.nvim`, install the servers by their Mason package names in `mason-tool-installer.nvim`, and call `vim.lsp.enable()` with an explicit list. `mason-tool-installer.nvim` accepts `nvim-lspconfig` names only when `mason-lspconfig.nvim` is installed ([README:46](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/blob/443f1ef/README.md#L46)).

### `multicursor.nvim`, `harpoon`, `venv-selector.nvim`, `vim-maximizer`, and the nvim-dap group

`multicursor.nvim`:

- The branches `1.0` and `main` point to the same commit `704b99f` of 2026-03-24. The repository has no tag. The README example uses `branch = "1.0"` ([README:28](https://github.com/jake-stewart/multicursor.nvim/blob/704b99f/README.md#L28)).
- The add and clear actions worked on 0.12.5.
- Neovim `master` (0.13 development) merged native multiple cursors on 2026-09-01 ([neovim#41587](https://github.com/neovim/neovim/pull/41587)). The 0.12.5 help has no match for this feature.
- The maintainer said `I will fix any bugs that may come with 0.13 so setups don't break` ([multicursor.nvim#156](https://github.com/jake-stewart/multicursor.nvim/issues/156)).
- Recommendation: keep it on the `1.0` branch.

`harpoon`:

- The README of the `master` branch says that `master` is deprecated and that all future changes go to `harpoon2` ([README:4](https://github.com/ThePrimeagen/harpoon/blob/1bc17e3/README.md#L4)).
- The `harpoon2` branch had ten commits in 2025. After February 2025, it had one change (2025-04-01) and its merge (2025-10-31). Its README states `neovim 0.8.0+` ([README:37](https://github.com/ThePrimeagen/harpoon/blob/87b1a35/README.md#L37)).
- It uses `plenary.path` ([data.lua:1](https://github.com/ThePrimeagen/harpoon/blob/87b1a35/lua/harpoon/data.lua#L1), [config.lua:3](https://github.com/ThePrimeagen/harpoon/blob/87b1a35/lua/harpoon/config.lua#L3)). The issue about the end of `plenary.nvim` has no answer ([harpoon#712](https://github.com/ThePrimeagen/harpoon/issues/712)).
- The add action worked on 0.12.5.
- Recommendation: keep it on `harpoon2`. If `plenary.nvim` stops to work, the built-in global file marks (`mA` to `mZ`) give the same jump to a file, but without a menu.

`venv-selector.nvim`:

- Active: the last commit is from 2026-05-20. The minimum is Neovim 0.11 ([README:106](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/README.md#L106)).
- It works on 0.12.5 with the Snacks picker (see the Telescope answer).
- It restarts the Python LSP clients with the selected environment ([hooks.lua:1-19](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/lua/venv-selector/hooks.lua#L1-L19)). `lsp/basedpyright.lua:5-35` also finds `.venv` at start. The test did not examine the two together.
- Recommendation: keep it. Set `picker = 'snacks'`, and remove `telescope.nvim` and `nvim-lspconfig` from its dependency list.

`vim-maximizer`:

- It has no commit after 2015-08-22. `:MaximizerToggle` worked on 0.12.5.
- `Snacks.zen.zoom()` is already installed and worked on 0.12.5. It shows the window in a full-width floating window ([docs/zen.md:62-72](https://github.com/folke/snacks.nvim/blob/882c996/docs/zen.md#L62-L72), [docs/zen.md:136-141](https://github.com/folke/snacks.nvim/blob/882c996/docs/zen.md#L136-L141)). It does not resize the splits.
- Recommendation: map `<leader>wm` to `Snacks.zen.zoom()` and remove `vim-maximizer` (`lua/plugins/snacks.lua:689-694`).

The nvim-dap group:

- `nvim-dap` is active (last commit 2026-09-11). The README lists `0.12.x (Recommended)` ([README:24-28](https://github.com/mfussenegger/nvim-dap/blob/cfa2d58/README.md#L24-L28)). The primary repository is on Codeberg ([README:18](https://github.com/mfussenegger/nvim-dap/blob/cfa2d58/README.md#L18)), and the GitHub copy has the same HEAD.
- `nvim-dap-go` has no commit after 2025-07-11. It uses `iter_matches(..., { all = true })` ([dap-go-ts.lua:92](https://github.com/leoluz/nvim-dap-go/blob/b442115/lua/dap-go-ts.lua#L92)). Neovim 0.12 removed the `all` option and always gives all nodes (`runtime/doc/news.txt:93-95`). Thus the old option has no effect.
- `nvim-dap-python` has no commit after 2025-12-20. `setup('uv')` in `lua/plugins/debug.lua:118` is a documented form ([README:46-48](https://github.com/mfussenegger/nvim-dap-python/blob/1808458/README.md#L46-L48)).
- `nvim-dap-ui` had three commits after the lock (the last on 2026-07-14). `nvim-nio` is necessary for it. Open and close worked on 0.12.5.
- `nvim-dap-virtual-text` does nothing without `setup()` ([README:24-27](https://github.com/theHamsta/nvim-dap-virtual-text/blob/fbdb48c/README.md#L24-L27)). The config has the call only as a comment (`lua/plugins/debug.lua:92-107`).
- `lua/plugins/debug.lua:9` uses `williamboman/mason.nvim`. GitHub sends that URL to `mason-org/mason.nvim` (HTTP 301). `lua/plugins/lsp.lua:196` uses the new URL. With `vim.pack`, use one URL.
- Recommendation: keep `nvim-dap`, `nvim-dap-go`, `nvim-dap-python`, `nvim-dap-ui`, and `nvim-nio`. Remove `nvim-dap-virtual-text`, or call its `setup()`. An option is `nvim-dap-view` (see "New developments").

## Plugin details

Each entry gives the versions, the status, the Neovim version, the changes after the lock, the lazy.nvim features, the use, and the recommendation. The status "not archived" comes from the GitHub API on 2026-09-19.

### Plugin manager

`lazy.nvim` ([folke/lazy.nvim](https://github.com/folke/lazy.nvim)):

- Versions: locked `306a055` (2025-12-17). Latest release `v11.17.5` (2025-11-06). HEAD = lock.
- Status: not archived. No commit after 2025-12-17. No statement from the maintainer.
- Neovim: minimum 0.8.0 ([README:61](https://github.com/folke/lazy.nvim/blob/306a055/README.md#L61)). It worked on 0.12.5 in the sandbox.
- Use: `init.lua:1-23` makes and loads it.
- Recommendation: drop. `vim.pack` replaces it (`runtime/doc/news.txt:374`). See the `nvim-vim-pack` research.

### Completion and snippets

`blink.cmp` ([saghen/blink.cmp](https://github.com/saghen/blink.cmp)):

- Versions: locked `78336bc` = `v1.10.2` (2026-04-04). This is the latest release. The `main` branch (`473c928`, 2026-09-10) is the unreleased v2.
- Status: active. The README says `V2 is under active development with many breaking changes. Consider staying on stable` ([README:1-4](https://github.com/saghen/blink.cmp/blob/473c928/README.md#L1-L4)). The new `blink.lib` plugin is necessary for V2, and V2 drops Neovim older than 0.12 ([a38e436](https://github.com/saghen/blink.cmp/commit/a38e436)).
- Neovim: the minimum for v1 is 0.10 ([doc/installation.md:10](https://github.com/saghen/blink.cmp/blob/78336bc/doc/installation.md#L10)). `v1.10.2` has fixes for the `vim.NIL` change of 0.12 ([CHANGELOG.md:16-19](https://github.com/saghen/blink.cmp/blob/78336bc/CHANGELOG.md#L16-L19)). It worked on 0.12.5.
- Changes after the lock: none on the v1 line.
- lazy.nvim features: `version = '1.*'`, `opts`, and `opts_extend` (`lua/plugins/intellisense.lua:24`, `:32`, `:130`). The prebuilt fuzzy library downloads only when the checkout is on a tag ([doc/installation.md:4](https://github.com/saghen/blink.cmp/blob/78336bc/doc/installation.md#L4)). In the sandbox, the checkout was on `v1.10.2`, and `libblink_cmp_fuzzy.dylib` downloaded.
- Use: yes.
- Recommendation: keep on `1.*` (in `vim.pack`, `version = vim.version.range('1.*')`). Do not use `main` before the v2 release.

`friendly-snippets` ([rafamadriz/friendly-snippets](https://github.com/rafamadriz/friendly-snippets)):

- Versions: locked `6cd7280` (2026-01-23). HEAD `b4d01b0` (2026-09-10). No release.
- Status: active. Not archived.
- Neovim: data only. It worked on 0.12.5.
- Changes after the lock: new snippets and fixes. Some Python and Lua prefixes changed ([6e9e545](https://github.com/rafamadriz/friendly-snippets/commit/6e9e545), [eeae4af](https://github.com/rafamadriz/friendly-snippets/commit/eeae4af)).
- lazy.nvim features: a dependency of `blink.cmp` (`lua/plugins/intellisense.lua:6`).
- Use: yes, through the blink `snippets` source.
- Recommendation: keep.

`lazydev.nvim` ([folke/lazydev.nvim](https://github.com/folke/lazydev.nvim)):

- Versions: locked `ff2cbcb` (2026-03-14). Latest release `v1.10.0` (2025-10-23). HEAD = lock.
- Status: not archived. No statement from the maintainer.
- Neovim: minimum 0.10.0 ([README:35](https://github.com/folke/lazydev.nvim/blob/ff2cbcb/README.md#L35)). It worked on 0.12.5.
- lazy.nvim features: `ft = 'lua'` and `opts` (`lua/plugins/intellisense.lua:9-18`). Without lazy.nvim, it finds plugins on `'runtimepath'` and in `pack/*/opt/*` ([pkg.lua:66-112](https://github.com/folke/lazydev.nvim/blob/ff2cbcb/lua/lazydev/pkg.lua#L66-L112)). That is the layout of `vim.pack`.
- Use: yes, as a blink source (`lua/plugins/intellisense.lua:105-110`). The `library` list names `lazy.nvim` and `LazyVim` (`lua/plugins/intellisense.lua:15-16`). `LazyVim` is not installed, and `lazy.nvim` goes away.
- Recommendation: keep. Replace the `library` entries with the plugins that you want in Lua completion.

`minuet-ai.nvim` ([milanglacier/minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim)):

- Versions: locked `d29dec4` (2026-05-27). Latest release `v0.10.0` (2026-07-31). HEAD `3b0a4c5` (2026-08-14).
- Status: active. Not archived.
- Neovim: minimum 0.10, and 0.11 for the built-in completion front end ([README:97](https://github.com/milanglacier/minuet-ai.nvim/blob/3b0a4c5/README.md#L97), [README:116](https://github.com/milanglacier/minuet-ai.nvim/blob/3b0a4c5/README.md#L116)). It loaded on 0.12.5.
- Changes after the lock: new `duet` features for next edit prediction. None affects this config, because the config does not set it up.
- Use: no. See "The three AI plugins".
- Recommendation: drop, or adopt it as the one completion provider.

`supermaven-nvim` ([supermaven-inc/supermaven-nvim](https://github.com/supermaven-inc/supermaven-nvim)):

- Versions: locked `07d20fc` (2024-10-07). HEAD = lock. No release.
- Status: not archived. No commit after 2024-10-07. The service is in sunset (see "The three AI plugins").
- Neovim: no stated minimum. It loaded on 0.12.5, and its agent started.
- lazy.nvim features: `config` only (`lua/plugins/ml.lua:2-9`).
- Use: yes.
- Recommendation: replace.

`sidekick.nvim` ([folke/sidekick.nvim](https://github.com/folke/sidekick.nvim)):

- Versions: locked `208e1c5` (2026-04-22). Latest release `v2.3.0` (2026-03-20) is older than the lock. HEAD `3d80a47` (2026-09-08).
- Status: active. Not archived.
- Neovim: minimum 0.11.2 ([README:33](https://github.com/folke/sidekick.nvim/blob/3d80a47/README.md#L33)). It loaded on 0.12.5. The health check reported `No Copilot LSP server is enabled`, because the sandbox did not install that server.
- Changes after the lock: three fixes. None affects this config.
- lazy.nvim features: `opts` and `keys` (`lua/plugins/ml.lua:35-153`).
- Use: yes, the AI CLI part.
- Recommendation: keep.

### LSP, formatting, and linting

`nvim-lspconfig` ([neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)):

- Versions: locked `3371bf2` (2026-06-25). Latest release `v2.11.0` (2026-07-21). HEAD `ffd261c` (2026-09-18) adds new server configs, fixes for single servers, and two refactors of the legacy code.
- Status: active. Not archived.
- Neovim: minimum 0.11.3. See the answer above for 0.12.
- Changes after the lock: `ruff_lsp` is deprecated in favor of `ruff` ([d9794a4](https://github.com/neovim/nvim-lspconfig/commit/d9794a48)). The config uses `ruff`, thus there is no effect. The only breaking commit removes `lsp/rls.lua` ([b187583](https://github.com/neovim/nvim-lspconfig/commit/b187583b)), which this config does not use. A fix for `eslint` ([9c3bcf4](https://github.com/neovim/nvim-lspconfig/commit/9c3bcf42)) and a new language id for `docker_language_server` ([9745bbf](https://github.com/neovim/nvim-lspconfig/commit/9745bbfa)) touch servers of this config.
- lazy.nvim features: a dependency only (`lua/plugins/lsp.lua:197`, `lua/plugins/python.lua:5`).
- Use: yes, as the source of server configs.
- Recommendation: keep.

`mason.nvim` ([mason-org/mason.nvim](https://github.com/mason-org/mason.nvim)):

- Versions: locked `2a6940a` = `v2.3.1` (2026-06-11). HEAD = lock.
- Status: active. Not archived.
- Neovim: minimum 0.10.0 ([README:83](https://github.com/mason-org/mason.nvim/blob/2a6940a/README.md#L83)). It worked on 0.12.5.
- lazy.nvim features: `opts = {}` (`lua/plugins/lsp.lua:196`). Two specs name the plugin with two URLs (`lua/plugins/lsp.lua:196`, `lua/plugins/debug.lua:9`).
- Use: yes.
- Recommendation: keep. Use the `mason-org` URL only.

`mason-lspconfig.nvim` ([mason-org/mason-lspconfig.nvim](https://github.com/mason-org/mason-lspconfig.nvim)):

- Versions: locked `50bf387` (2026-06-26). Latest release `v2.3.0` (2026-06-11) is older than the lock. HEAD `49b16d6` (2026-09-18).
- Status: active. Not archived.
- Neovim: minimum 0.11.0. It worked on 0.12.5.
- Changes after the lock: 14 commits, all with the title `chore: update generated code`.
- lazy.nvim features: `opts` (`lua/plugins/lsp.lua:155`). lazy.nvim calls `setup(opts)` after `mason.nvim` through the dependency order. With `vim.pack`, call `require('mason').setup()` first.
- Use: yes.
- Recommendation: keep, with the `exclude` list (see the answer above).

`mason-tool-installer.nvim` ([WhoIsSethDaniel/mason-tool-installer.nvim](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim)):

- Versions: locked `443f1ef` (2026-01-22). HEAD = lock. No release.
- Status: not archived. Last commit 2026-01-22.
- Neovim: the same minimum as `mason.nvim` ([README:12](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/blob/443f1ef/README.md#L12)). It loaded on 0.12.5.
- lazy.nvim features: `opts` and `config` (`lua/plugins/lsp.lua:205-242`).
- Use: yes.
- Recommendation: keep.

`conform.nvim` ([stevearc/conform.nvim](https://github.com/stevearc/conform.nvim)):

- Versions: locked `619363c` (2026-05-24). Latest release `v9.1.0` (2025-08-22) is older than the lock. HEAD `016802d` (2026-08-11).
- Status: active. Not archived.
- Neovim: minimum 0.10 ([README:33](https://github.com/stevearc/conform.nvim/blob/016802d/README.md#L33)). On 0.12 it uses `vim.text.diff` ([runner.lua:219-230](https://github.com/stevearc/conform.nvim/blob/016802d/lua/conform/runner.lua#L219-L230)). A `stylua` format worked on 0.12.5.
- Changes after the lock: 11 commits for single formatters. None affects this config.
- Old item in the config: `lsp_fallback = true` (`lua/plugins/lsp.lua:46`). Conform changes it to `lsp_format = "fallback"` for backward compatibility ([init.lua:430-437](https://github.com/stevearc/conform.nvim/blob/016802d/lua/conform/init.lua#L430-L437)).
- lazy.nvim features: `lazy` and `event` (`lua/plugins/lsp.lua:117-118`).
- Use: yes.
- Recommendation: keep. Change `lsp_fallback = true` to `lsp_format = 'fallback'`.

`nvim-lint` ([mfussenegger/nvim-lint](https://github.com/mfussenegger/nvim-lint)):

- Versions: locked `a219b2c` (2026-06-25). HEAD `3d55c8f` (2026-08-25). No release.
- Status: active. The GitHub repository is a copy of the Codeberg repository, and both have the same HEAD.
- Neovim: minimum 0.9.5 ([README:21](https://github.com/mfussenegger/nvim-lint/blob/3d55c8f/README.md#L21)). It ran the linters on 0.12.5.
- Changes after the lock: five commits for single linters. None affects this config.
- lazy.nvim features: `lazy` and `event` (`lua/plugins/lsp.lua:82-83`).
- Use: yes.
- Recommendation: keep.

### Treesitter

`nvim-treesitter` ([nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)):

- Versions: locked `4916d65` (2026-04-03) on `main`. HEAD of `main` `f603a2f` (2026-09-19). No release on `main`.
- Status: not archived on 2026-09-19. The GitHub API shows no commit from 2026-04-03 to 2026-07-18. Reports say that the owner archived the repository on 2026-04-03 ([LazyVim#7098](https://github.com/LazyVim/LazyVim/issues/7098)) and made it active again on 2026-07-18 ([a comment in Comment.nvim#517](https://github.com/numToStr/Comment.nvim/issues/517#issuecomment-5017308183)). The two dates are not verified in a statement from the owner.
- Neovim: 0.12.0 or later, and `tree-sitter-cli` 0.26.1 or later ([README:19-21](https://github.com/nvim-treesitter/nvim-treesitter/blob/f603a2f/README.md#L19-L21)). The sandbox health check gave an error for the local `tree-sitter` 0.25.10, but the parsers compiled.
- Changes after the lock: parser and query updates. The removed parsers are not in the list of this config.
- lazy.nvim features: `branch = 'main'`, `lazy = false`, and `build = ':TSUpdate'` (`lua/plugins/lsp.lua:251-253`).
- Use: yes.
- Recommendation: keep. See the `nvim-treesitter-main` research for the details.

`nvim-treesitter-textobjects` ([nvim-treesitter/nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)):

- Versions: locked `851e865` (2026-04-07) on `main`. HEAD `5c7b026` (2026-09-03).
- Status: active. Not archived.
- Neovim: no stated minimum. A `select_textobject('@function.outer')` call worked on 0.12.5.
- Changes after the lock: four commits. None affects this config.
- Use: only `setup({})` (`lua/plugins/lsp.lua:265`). The config defines no maps. `sidekick.nvim` can use it for the `{function}` and `{class}` context ([sidekick README:43](https://github.com/folke/sidekick.nvim/blob/3d80a47/README.md#L43)).
- Recommendation: keep it only if you add maps or use that sidekick context. Otherwise, drop it.

`nvim-ts-autotag` ([windwp/nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag)):

- Versions: locked `88c1453` (2026-04-15). HEAD = lock. No release.
- Status: not archived.
- Neovim: minimum 0.9.5 ([README:40](https://github.com/windwp/nvim-ts-autotag/blob/88c1453/README.md#L40)). It loaded on 0.12.5.
- Use: yes (`lua/plugins/lsp.lua:259`).
- Recommendation: keep.

`nvim-ts-context-commentstring` ([JoosepAlviste/nvim-ts-context-commentstring](https://github.com/JoosepAlviste/nvim-ts-context-commentstring)):

- Versions: locked `6141a40` (2026-04-04). HEAD = lock. No release.
- Status: not archived.
- Neovim: minimum 0.9.4 ([README:23](https://github.com/JoosepAlviste/nvim-ts-context-commentstring/blob/6141a40/README.md#L23)). It has 0.12 fixes.
- lazy.nvim features: a dependency with its own `config` (`lua/plugins/snacks.lua:371-378`).
- Use: yes, only as the `Comment.nvim` hook.
- Recommendation: drop with `Comment.nvim`.

`treesj` ([Wansmer/treesj](https://github.com/Wansmer/treesj)):

- Versions: locked `79aedb4` (2026-05-28). HEAD = lock. No release.
- Status: not archived.
- Neovim: minimum 0.9 ([README:48](https://github.com/Wansmer/treesj/blob/79aedb4/README.md#L48)). A split worked on 0.12.5.
- lazy.nvim features: `keys` and `opts` (`lua/plugins/snacks.lua:668-686`). The `nvim-treesitter` dependency is optional ([README:49](https://github.com/Wansmer/treesj/blob/79aedb4/README.md#L49)).
- Use: yes.
- Recommendation: keep.

### Editing

`Comment.nvim` ([numToStr/Comment.nvim](https://github.com/numToStr/Comment.nvim)):

- Versions: locked `e30b7f2` (2024-06-09). HEAD = lock. Latest release `v0.8.0` (2023-04-13).
- Status: not archived. No commit after 2024-06-09.
- Neovim: help file for 0.7. On 0.12.5, it fails in a buffer with no parser (see the answer above).
- lazy.nvim features: `opts = {}` and `config` together (`lua/plugins/snacks.lua:379-384`).
- Use: yes.
- Recommendation: drop.

`mini.pairs` ([nvim-mini/mini.pairs](https://github.com/nvim-mini/mini.pairs)):

- Versions: locked `4a01414` = `v0.18.0` (2026-06-19). This is the latest tag. HEAD `b1c5a72` (2026-07-23).
- Status: active. Not archived.
- Neovim: `mini.nvim` supports 0.10 and newer ([mini.nvim README](https://github.com/nvim-mini/mini.nvim#readme)). HEAD stopped the support of 0.9 ([b1fd9df](https://github.com/nvim-mini/mini.pairs/commit/b1fd9df)). It worked on 0.12.5.
- Old item in the config: the `mappings` in `lua/plugins/lsp.lua:411-423` copy the old defaults with `neigh_pattern = '[^\\].'`. The maintainer changed the defaults to `'^[^\\]'`, because the old form fails with multibyte characters ([4089aa6](https://github.com/nvim-mini/mini.pairs/commit/4089aa6)). The config keeps the old form.
- lazy.nvim features: `version = '*'` and `opts` (`lua/plugins/lsp.lua:399-400`).
- Use: yes.
- Recommendation: keep. Delete the `mappings` table to get the new defaults.

`mini.surround` ([nvim-mini/mini.surround](https://github.com/nvim-mini/mini.surround)):

- Versions: locked `580e4cb` = `v0.18.0` (2026-06-19). HEAD `8d5d0c5` (2026-07-16).
- Status: active. Not archived.
- Neovim: 0.10 and newer. `saiw)` worked on 0.12.5.
- Changes after the lock: three fixes and the end of 0.9 support. None affects this config.
- lazy.nvim features: `version = '*'` and `opts` (`lua/plugins/snacks.lua:648-649`). The `mappings` in the config are the same as the defaults.
- Use: yes.
- Recommendation: keep.

`multicursor.nvim` ([jake-stewart/multicursor.nvim](https://github.com/jake-stewart/multicursor.nvim)):

- Versions: `1.0` = `main` = lock `704b99f` (2026-03-24).
- Status: not archived. See the answer above.
- lazy.nvim features: `branch = '1.0'` (`lua/plugins/snacks.lua:776`).
- Use: yes.
- Recommendation: keep.

### Files, navigation, and UI

`oil.nvim` ([stevearc/oil.nvim](https://github.com/stevearc/oil.nvim)):

- Versions: locked `b73018b` (2026-06-02). HEAD = lock. Latest release `v2.16.0` (2026-05-24).
- Status: active. Not archived.
- Neovim: minimum 0.10 ([README:23](https://github.com/stevearc/oil.nvim/blob/b73018b/README.md#L23)). `:Oil` worked on 0.12.5.
- lazy.nvim features: `lazy = false` and `opts` (`lua/plugins/file.lua:10-18`).
- Use: yes. The Snacks explorer is also on (`lua/plugins/snacks.lua:38`, `:84-89`). Thus the config has two file explorers.
- Recommendation: keep.

`snacks.nvim` ([folke/snacks.nvim](https://github.com/folke/snacks.nvim)):

- Versions: locked `882c996` (2026-05-25). HEAD = lock. Latest release `v2.31.0` (2026-03-20).
- Status: not archived. No commit after 2026-05-25. No statement from the maintainer.
- Neovim: minimum 0.9.4 ([README:48](https://github.com/folke/snacks.nvim/blob/882c996/README.md#L48)). Pickers, the explorer, and zoom worked on 0.12.5.
- lazy.nvim features: `opts`, `keys` (about 40 maps in `lua/plugins/snacks.lua:53-351`), `priority`, and `lazy = false`. `Snacks.picker.lazy()` (`lua/plugins/snacks.lua:317-322`) calls `require("lazy.core.config")` with no guard ([source/lazy.lua:5-6](https://github.com/folke/snacks.nvim/blob/882c996/lua/snacks/picker/source/lazy.lua#L5-L6)). The other lazy.nvim calls in Snacks look at `package.loaded.lazy` first.
- Use: yes.
- Recommendation: keep. Delete the `<leader>sp` map.

`which-key.nvim` ([folke/which-key.nvim](https://github.com/folke/which-key.nvim)):

- Versions: locked `3aab214` (2025-10-28). HEAD = lock. Latest release `v3.17.0` (2025-02-22).
- Status: not archived. No commit after 2025-10-28.
- Neovim: minimum 0.9.4 ([README:26](https://github.com/folke/which-key.nvim/blob/3aab214/README.md#L26)). It loaded on 0.12.5. The test did not open the popup, because the popup waits for keys.
- lazy.nvim features: `event = 'VeryLazy'`, `opts`, and `keys` (`lua/plugins/snacks.lua:355-367`). Its calls into lazy.nvim look at `package.loaded.lazy` first.
- Use: yes.
- Recommendation: keep.

`lualine.nvim` ([nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)):

- Versions: locked `221ce6b` (2026-05-31). HEAD = lock. No release.
- Status: not archived.
- Neovim: minimum 0.7 ([README:12](https://github.com/nvim-lualine/lualine.nvim/blob/221ce6b/README.md#L12)). The statusline worked on 0.12.5.
- lazy.nvim features: `dependencies` only.
- Use: yes.
- Recommendation: keep.

`gruvbox.nvim` ([ellisonleao/gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim)):

- Versions: locked `154eb5f` (2026-04-15). HEAD = lock. Latest release `2.0.0` (2023).
- Status: not archived.
- Neovim: minimum 0.8.0 ([README:17](https://github.com/ellisonleao/gruvbox.nvim/blob/154eb5f/README.md#L17)). It worked on 0.12.5.
- lazy.nvim features: `priority = 1000` (`lua/plugins/colors.lua:4`). With `vim.pack`, load it before the other plugins.
- Use: yes.
- Recommendation: keep.

`nvim-web-devicons` ([nvim-tree/nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)):

- Versions: locked `dfbfaa9` (2026-05-27). HEAD `914decf` (2026-09-18). No release.
- Status: active. Not archived.
- Neovim: no stated minimum. It worked on 0.12.5.
- Changes after the lock: new icons. None affects this config.
- Use: yes, a dependency of `oil.nvim`, `trouble.nvim`, and `lualine.nvim`.
- Recommendation: keep.

`trouble.nvim` ([folke/trouble.nvim](https://github.com/folke/trouble.nvim)):

- Versions: locked `bd67efe` (2025-10-31). HEAD = lock. Latest release `v3.7.1` (2025-02-12).
- Status: not archived. No commit after 2025-10-31.
- Neovim: minimum 0.9.2 ([README:47](https://github.com/folke/trouble.nvim/blob/bd67efe/README.md#L47)). `:Trouble diagnostics` worked on 0.12.5.
- lazy.nvim features: `opts` and `keys` (`lua/plugins/lsp.lua:372-394`).
- Use: yes. The config also maps Snacks pickers for diagnostics, the quickfix list, and the location list (`lua/plugins/snacks.lua:253-266`, `:295-301`, `:323-329`).
- Recommendation: keep, or drop it and use the Snacks pickers.

`harpoon` ([ThePrimeagen/harpoon](https://github.com/ThePrimeagen/harpoon)): see the answer above. lazy.nvim features: `branch = 'harpoon2'` and `dependencies` (`lua/plugins/snacks.lua:617-619`).

`vim-maximizer` ([szw/vim-maximizer](https://github.com/szw/vim-maximizer)): see the answer above. lazy.nvim features: `keys` (`lua/plugins/snacks.lua:691-693`).

`telescope.nvim` ([nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)): see the answer above. The latest GitHub release is `v0.2.1` (2025-12-31), and the tag `v0.2.2` (2026-02-16) has no release page. lazy.nvim features: `branch = '0.1.x'` inside a dependency (`lua/plugins/python.lua:6`).

`plenary.nvim` ([nvim-lua/plenary.nvim](https://github.com/nvim-lua/plenary.nvim)):

- Versions: locked `74b06c6` (2026-04-10). HEAD = lock.
- Status: not archived yet. The README says `This repository is no longer actively maintained and will be officially archived soon`. Critical bug fixes stopped on 2026-06-30 ([README:5-11](https://github.com/nvim-lua/plenary.nvim/blob/74b06c6/README.md#L5-L11)).
- Neovim: it loaded on 0.12.5. It still uses `vim.loop`, which 0.12.5 keeps as an alias of `vim.uv`.
- Use: a dependency of `harpoon` and `telescope.nvim`.
- Recommendation: keep it only while `harpoon` uses it.

### Git

`vim-fugitive` ([tpope/vim-fugitive](https://github.com/tpope/vim-fugitive)):

- Versions: locked `3b753cf` (2026-03-07). HEAD = lock. Latest tag `v3.7` (2022).
- Status: not archived.
- Neovim: no stated minimum. `:Git` worked on 0.12.5.
- lazy.nvim features: `lazy = false` and `event` together (`lua/plugins/git.lua:4-5`). With `lazy = false`, lazy.nvim loads it at start and the `event` has no effect.
- Use: yes.
- Recommendation: keep.

`gitsigns.nvim` ([lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)):

- Versions: locked `2038c66` (2026-06-18). Latest release `v2.1.0` (2026-03-26) is older than the lock. HEAD `8d79f24` (2026-09-16).
- Status: active. Not archived.
- Neovim: minimum 0.11.0 ([README:138](https://github.com/lewis6991/gitsigns.nvim/blob/8d79f24/README.md#L138)). HEAD dropped 0.10 ([5eb287f](https://github.com/lewis6991/gitsigns.nvim/commit/5eb287f)). It attached to a Git file on 0.12.5.
- Changes after the lock: a new `:Gitsigns diff` panel ([f66d5f2](https://github.com/lewis6991/gitsigns.nvim/commit/f66d5f2)) and fixes. None breaks this config.
- Old item in the config: `gs.undo_stage_hunk` (`lua/plugins/snacks.lua:748`). The help says `DEPRECATED: use gitsigns.stage_hunk() on staged signs` ([doc/gitsigns.txt:609-610](https://github.com/lewis6991/gitsigns.nvim/blob/8d79f24/doc/gitsigns.txt#L609-L610)).
- lazy.nvim features: `event` and `opts` (`lua/plugins/snacks.lua:701-704`). A second spec fragment named `gitsigns.nvim` uses `opts = function()` only to make a Snacks toggle (`lua/plugins/snacks.lua:759-772`). `vim.pack` has no spec merge. Move that toggle into plain code after the Snacks setup.
- Use: yes.
- Recommendation: keep. Remove the `<leader>ghu` map, because `<leader>ghs` on a staged hunk unstages it.

### Debugging

`nvim-dap` ([mfussenegger/nvim-dap](https://github.com/mfussenegger/nvim-dap)), `nvim-dap-go` ([leoluz/nvim-dap-go](https://github.com/leoluz/nvim-dap-go)), `nvim-dap-python` ([mfussenegger/nvim-dap-python](https://github.com/mfussenegger/nvim-dap-python)), `nvim-dap-ui` ([rcarriga/nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)), and `nvim-dap-virtual-text` ([theHamsta/nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text)): see the answer above.

- Minimum Neovim: `nvim-dap-go` 0.9.0 ([README:16](https://github.com/leoluz/nvim-dap-go/blob/b442115/README.md#L16)). `nvim-dap-python` 0.5 ([README:8](https://github.com/mfussenegger/nvim-dap-python/blob/1808458/README.md#L8)). `nvim-dap-ui` and `nvim-dap-virtual-text` state no minimum.
- Changes after the lock: `nvim-dap` has three fixes, and `nvim-dap-ui` has three fixes. None affects this config.
- lazy.nvim features: `dependencies` (`lua/plugins/debug.lua:4-19`) and `ft = 'python'` for `nvim-dap-python` (`lua/plugins/debug.lua:12`). The `config` function calls `require('dap-python')` at once (`lua/plugins/debug.lua:118`). With `vim.pack`, install `nvim-dap-python` before that call.

`nvim-nio` ([nvim-neotest/nvim-nio](https://github.com/nvim-neotest/nvim-nio)):

- Versions: locked `21f5324` = `v1.10.1` (2025-01-20). HEAD `edcc181` (2026-07-15).
- Status: not archived.
- Changes after the lock: one fix. It calls the LSP client methods with colon syntax, and this stops deprecation warnings ([edcc181](https://github.com/nvim-neotest/nvim-nio/commit/edcc181)).
- Use: a dependency of `nvim-dap-ui`.
- Recommendation: keep while `nvim-dap-ui` stays. Use HEAD, because the release does not have the fix.

### Python

`venv-selector.nvim` ([linux-cultist/venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim)): see the answer above. lazy.nvim features: `ft`, `keys`, `opts`, and `dependencies` (`lua/plugins/python.lua:3-15`). The `ft` and `keys` load triggers become plain code with `vim.pack`.

## New developments that fit this config

Each item gives the source and what it replaces.

- Built-in inline completion in Neovim 0.12 with the Copilot server that the config already installs (`runtime/doc/news.txt:229-231`, `runtime/doc/lsp.txt:2388-2418`). It replaces `supermaven-nvim`.
- Built-in `gc` with the `bo.commentstring` query metadata of `nvim-treesitter` `main` (see the answer above). It replaces `Comment.nvim` and `nvim-ts-context-commentstring`.
- `options.picker = 'snacks'` in `venv-selector.nvim` ([docs/OPTIONS.md](https://github.com/linux-cultist/venv-selector.nvim/blob/cc4bb39/docs/OPTIONS.md)). It removes `telescope.nvim`.
- `Snacks.zen.zoom()` in the installed `snacks.nvim`. It replaces `vim-maximizer`.
- `:lsp` in Neovim 0.12 (`runtime/doc/news.txt:232`). It replaces the `:Lsp*` commands of `nvim-lspconfig`, which 0.12 does not get.
- Built-in treesitter incremental selection with `an`, `in`, `]n`, and `[n` in Visual mode (`runtime/doc/news.txt:409-411`, `runtime/doc/treesitter.txt:612-630`). It can replace the custom selection code in `lua/plugins/lsp.lua:316-365`. See the `nvim-treesitter-main` research.
- [nvim-dap-view](https://github.com/igorlfs/nvim-dap-view) `v1.2.1` (2026-08-07). It is a debug UI for `nvim-dap` with inline virtual text, and it has no `nvim-nio` dependency. The minimum is Neovim 0.11. It can replace `nvim-dap-ui`, `nvim-nio`, and `nvim-dap-virtual-text`. The sandbox did not do a test of it.
- `:Gitsigns diff` on `gitsigns.nvim` HEAD ([f66d5f2](https://github.com/lewis6991/gitsigns.nvim/commit/f66d5f2), 2026-09-09). It is a panel with a file tree and a diff for each file. It overlaps `Snacks.picker.git_diff()` and the status buffer of `vim-fugitive`. It is not in a release yet.
- Native multiple cursors in Neovim `master` ([neovim#41587](https://github.com/neovim/neovim/pull/41587), 2026-09-01). This is not in 0.12.5. Keep `multicursor.nvim` on 0.12.
- `blink.cmp` v2 on `main`. It has breaking changes, and `blink.lib` is necessary for it. It is not released. Stay on `1.*`.

## Side findings

- `<leader>gb` has two maps: `Snacks.picker.git_branches()` (`lua/plugins/snacks.lua:137-142`) and `dap.run_to_cursor` (`lua/plugins/debug.lua:374`). The map that loads last wins.
- `sqruff` runs three times for SQL buffers: as an LSP server, in `nvim-lint` (`lua/plugins/lsp.lua:98`), and in `conform.nvim` (`lua/plugins/lsp.lua:143`).
- The Neovim 0.12 changes for the core config, for example the deprecated `float` option of `vim.diagnostic.jump()` (`lua/plugins/lsp.lua:67`, `:71`), are in the `nvim-0.12-upgrade` research.

## Primary sources

- Neovim 0.12.5 runtime documents: `runtime/doc/news.txt`, `runtime/doc/deprecated.txt`, `runtime/doc/lsp.txt`, `runtime/doc/pack.txt`, `runtime/doc/various.txt`, `runtime/doc/treesitter.txt`, and `runtime/lua/vim/_comment.lua` in the 0.12.5 macOS build.
- Each plugin repository at the commit in the links above, and the GitHub API on 2026-09-19.
- [Sunsetting Supermaven](https://supermaven.com/blog/sunsetting-supermaven), 2025-11-21.
- [Comment.nvim#517](https://github.com/numToStr/Comment.nvim/issues/517), [harpoon#712](https://github.com/ThePrimeagen/harpoon/issues/712), [multicursor.nvim#156](https://github.com/jake-stewart/multicursor.nvim/issues/156), [LazyVim#7098](https://github.com/LazyVim/LazyVim/issues/7098), [neovim#41587](https://github.com/neovim/neovim/pull/41587).
- [nvim-ts-context-commentstring wiki, Integrations](https://github.com/JoosepAlviste/nvim-ts-context-commentstring/wiki/Integrations).
