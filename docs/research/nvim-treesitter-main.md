# nvim-treesitter `main` at the latest version

This research compares the treesitter spec of the config with the latest `main` of `nvim-treesitter` and `nvim-treesitter-textobjects`. The target is Neovim 0.12.5 with `vim.pack`. The research changed no file of the config.

## Summary

| # | Question | Result | Item for the migration plan |
| --- | --- | --- | --- |
| 1 | Does each call of the spec exist in the latest `main`? | Yes. Each call exists and works on 0.12.5 in the sandbox. There are four mismatches: the spec sets the treesitter `indentexpr` also for languages with no `indents` query (`vim` and `gitconfig` lose their indent), the `pcall` around the async `install()` catches nothing, the comment "blade was dropped" is wrong, and the custom incremental selection copies the new built-in `an`/`in`. | Section 1 |
| 2 | Requirements of the latest `main` | Neovim 0.12.0 or later, `tree-sitter` CLI 0.26.1 or later from a package manager (not npm), a C compiler, `curl`, `tar`. This machine has the npm CLI 0.25.10: `:checkhealth` reports an error, and each build fails when `node` is not on `PATH`. Latest `main` fails on Neovim 0.11.5. | Install Homebrew `tree-sitter-cli` (0.27.0). Remove the npm package, because the nvm `bin` directory comes before Homebrew in `PATH`. Update Neovim and `nvim-treesitter` together. |
| 3 | The parsers of the `ensure` list | All 43 are in the registry. No parser has a new name. `install()` adds 6 dependencies. `blade` is in the registry. Two parsers of the live machine left the registry: `jsonc` and `tmux`. | Section 3 |
| 4 | textobjects keymaps | `setup()` stores options only. Each keymap is a `vim.keymap.set` call to a module function. The shape is in section 4. | Choose the keys. Think about `vim.g.no_plugin_maps`. |
| 5 | Plugins that use the nvim-treesitter API | Two plugins fail. `telescope.nvim` branch `0.1.x` calls `nvim-treesitter.configs`/`parsers`, and its previewer fails with `main`. `Comment.nvim` fails on 0.12 for a buffer with no parser. Each other plugin works. | Move `telescope.nvim` to a `0.2.x` tag or `master`. Replace `Comment.nvim` (it has no fix for 0.12). |
| 6 | Why is the live clone on `master`? | lazy.nvim installs a plugin only when its directory is absent. It changes the branch only in `:Lazy update`, `:Lazy sync`, or `:Lazy restore`. The clone is at `v0.10.0` on `master`. The code shows that the live spec stops at `CFG:265` with the `master` clones. | Delete the lazy root, the `master` parsers in it, and two source trees of `master` (section 6). |
| 7 | Sandbox test on 0.12.5 | 49 parsers (43 and 6 dependencies) installed in 15 s. Highlights, injections (with markdown code fences), folds, indent, textobjects, and autotag work. Both health checks show no error with CLI 0.27.0. | Section 7 |
| 8 | Parser update after a plugin update | The docs say: run `:TSUpdate` after each update of the plugin, as a build step. With `vim.pack`, a `PackChanged` hook does this. The sandbox test of the hook passed. | Add the hook of section 8. |

## Sources and versions

- Date of the research: 2026-09-19.
- `nvim-treesitter` branch `main` at `f603a2f` (2026-09-19). `main` has no release tag. The newest tag, `v0.10.0`, is on `master` only. The lockfile has `4916d65` (2026-04-03), 55 commits older. Between the two commits, `init.lua`, `config.lua`, the README, and the help file did not change.
- `nvim-treesitter-textobjects` branch `main` at `5c7b026` (2026-09-03). It has no release tag. The lockfile has `851e865`, 4 commits older.
- `nvim-ts-autotag` at `88c1453` (2026-04-15). This is the HEAD of `main` and also the locked commit.
- Neovim 0.12.5, the macOS arm64 release archive.
- `tree-sitter` CLI 0.27.0, the latest release (2026-08-30), in the sandbox only. The machine has 0.25.10 from npm.

Short names in the citations:

| Short name | Meaning |
| --- | --- |
| `CFG` | `.config/nvim/lua/plugins/lsp.lua` in this repository, branch `unified`. The spec is at lines 245-367. |
| `NTS` | nvim-treesitter at https://github.com/nvim-treesitter/nvim-treesitter/tree/f603a2f4da48728f80257fb5fbb90145fd1dc173 |
| `NTO` | nvim-treesitter-textobjects at https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/5c7b0263797dfd1bd6202f2b219f3b53a80b2187 |
| `RT` | the runtime of Neovim 0.12.5, `scratchpad/nvim-research/nvim-macos-arm64/share/nvim/runtime`. The same files are at tag `v0.12.5` of https://github.com/neovim/neovim |
| `LZ` | lazy.nvim at https://github.com/folke/lazy.nvim/tree/306a05526ada86a7b30af95c5cc81ffba93fef97 (the locked commit and the HEAD) |
| `SBX` | the sandbox of this research, `scratchpad/nvim-research/treesitter`. It is not in the repository. |

A citation such as `NTS/README.md:34` means that file, line 34.

## 1. The calls of the spec against the latest `main`

| `CFG` line | Call or field | Status | Source |
| --- | --- | --- | --- |
| 251-253 | `branch = 'main'`, `lazy = false`, `build = ':TSUpdate'` | Correct for lazy.nvim. The plugin does not support lazy loading. `vim.pack` has no `build` field, see section 8. | `NTS/README.md:34-46` |
| 255 | textobjects `branch = 'main'` | Correct. | `NTO/README.md:17-35` |
| 259 | `require('nvim-ts-autotag').setup()` | Exists and works. | `nvim-ts-autotag/lua/nvim-ts-autotag.lua:37` |
| 261-262 | `require('nvim-treesitter').setup()` | Exists. With no argument it does nothing. The docs say that a call is necessary only for a value that is not the default. | `NTS/lua/nvim-treesitter/init.lua:3-5`, `NTS/lua/nvim-treesitter/config.lua:15-23`, `NTS/README.md:50` |
| 265 | `require('nvim-treesitter-textobjects').setup({})` | Exists. An empty table changes nothing. | `NTO/lua/nvim-treesitter-textobjects/init.lua:4-8` |
| 270-277 | the `ensure` list | Each name is in the registry, see section 3. | `NTS/lua/nvim-treesitter/parsers.lua` |
| 278 | `pcall(function() nts.install(ensure) end)` | `install` exists and returns an async task. It skips parsers that are installed. When all parsers are installed, the call takes 1.3 ms. The `pcall` is not useful, see 1.2. | `NTS/lua/nvim-treesitter/install.lua:506-551`, `NTS/doc/nvim-treesitter.txt:106-130` |
| 288 | `nts.get_available()` | Exists. It returns the 323 languages of the registry and fires `User TSUpdate`. The call takes 0.1 ms. | `NTS/lua/nvim-treesitter/config.lua:62-78`, `NTS/doc/nvim-treesitter.txt:167-173` |
| 295 | `vim.treesitter.language.get_lang(ft)` | Exists. It returns the filetype when no language has a registration. The plugin registers 63 languages for other filetypes, for example `tsx` for `typescriptreact`. | `RT/doc/treesitter.txt:1239-1251`, `NTS/plugin/filetypes.lua:1-69` |
| 297 | the gate `available[lang]` | Works. In the sandbox, the filetypes `fugitive` and `oil` got no highlighter and no install. | test 7.3 |
| 300 | `vim.treesitter.start(buf, lang)` | Exists. | `RT/doc/treesitter.txt:1168` |
| 301 | `indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"` | Exists, with the same quotes as the README. It applies also to languages with no `indents` query, see 1.1. | `NTS/README.md:103-111`, `NTS/lua/nvim-treesitter/init.lua:27-29` |
| 305 | `vim.treesitter.language.add(lang)` | Exists. It returns `true` when the parser loads, and `nil` and an error when it does not. | `RT/doc/treesitter.txt:1205-1225` |
| 311 | `nts.install({ lang }):await(cb)` | `Task:await` exists. It calls `cb(err, ...)`. The spec ignores `err` and calls `start()`, which fails silently in its `pcall`. | `NTS/lua/nvim-treesitter/async.lua:83-93` |
| 316-365 | incremental selection with `vim.treesitter.get_node()`, `TSNode:range()`, `TSNode:parent()` | Works. Neovim 0.12 has the same function built in, see 1.4. | `RT/doc/treesitter.txt:993`, test 7.6 |

The spec does not set folds. The README gives `foldexpr = 'v:lua.vim.treesitter.foldexpr()'` and `foldmethod = 'expr'` for a `FileType` autocommand (`NTS/README.md:94-101`). The sandbox test of folds used these two options, see 7.4.

### 1.1 The treesitter `indentexpr` for a language with no `indents` query

`CFG:301` sets the treesitter `indentexpr` for each language that has a parser. When a language has no `indents` query, `get_indents` returns an empty map (`NTS/lua/nvim-treesitter/indent.lua:95-98`). Then each new line gets indent 0. The health check shows no `indents` query for 24 installed languages, for example `vim`, `git_config`, `dockerfile`, `gitcommit`, `json5`, and `vimdoc` (section 7.7).

A sandbox test typed `o` after an indented line. The result:

| Filetype | `indentexpr` | Indent of the new line |
| --- | --- | --- |
| `vim` | the spec: `v:lua.require'nvim-treesitter'.indentexpr()` | 0 |
| `vim` | the runtime: `GetVimIndent()` | 2 spaces |
| `gitconfig` | the spec | 0 |
| `gitconfig` | the runtime: `GetGitconfigIndent()` | 1 tab |
| `yaml` | the spec (a query exists) | 2 spaces |
| `yaml` | the runtime: `GetYAMLIndent(v:lnum)` | 2 spaces |

A possible guard: set the `indentexpr` only when `vim.treesitter.query.get(lang, 'indents')` is not `nil`. The plan must decide.

The README calls the treesitter indent "experimental" (`NTS/README.md:105`). The sandbox found two more differences from the runtime indent, see 7.4.

### 1.2 The `pcall` around `install()`

`install()` is an async function (`NTS/lua/nvim-treesitter/install.lua:547`). It returns a task at once and does not raise an error for a failed build. A failed build writes an error to the log and to the message area (`NTS/lua/nvim-treesitter/log.lua:71-76`). Thus the `pcall` at `CFG:278` catches nothing.

As a result, when the `tree-sitter` CLI is absent, each start of Neovim tries each install again. Each try shows one error. On a new machine, this is 49 errors at each start. This comes from the code and from the test with one parser in section 2, which also gives the error texts.

### 1.3 The comment about `blade`

The comment at `CFG:268-269` says that `blade` is not in the registry. This is not correct. `blade` is in the registry at `NTS/lua/nvim-treesitter/parsers.lua:112`. Commit `548ed98f` (2025-03-12) added it. It is also on `master`.

Neovim 0.12.5 detects the filetype `blade` for `*.blade.php` (`RT/lua/vim/filetype.lua:2716`). The live machine has `blade.so` from `master`.

### 1.4 The incremental selection is now in Neovim

Neovim 0.12 adds `an`, `in`, `]n`, `[n`, `]N`, and `[N` in Visual mode, and `vim.treesitter.select()` (`RT/doc/news.txt:409-412`, `RT/doc/treesitter.txt:611-636`, `RT/doc/treesitter.txt:1158-1168`). When a buffer has no parser, `an` and `in` use the LSP `selectionRange`.

In the sandbox, from the same cursor position in `sample.lua`, the custom `<C-space>` and the built-in `an` selected the same nodes:

| Keys | Selection |
| --- | --- |
| `v` `an` | `a + b` |
| `v` `an` `an` | `return a + b` |
| `<C-space>` | `a + b` |
| `<C-space>` `<C-space>` | `return a + b` |

Thus the plan can remove `CFG:316-365` and use the built-in keys. This is a choice for the plan.

### 1.5 A second buffer during an auto-install

This item comes from the code only. No test verified it. When a parser is not installed, `CFG:308-311` starts one install and sets `pending[lang]`. The callback starts the highlighter only for the first buffer. A second buffer of the same language that opens during the install gets no highlighter until `:edit`.

## 2. The requirements of the latest `main`

| Requirement | Source | This machine | What fails when it is absent |
| --- | --- | --- | --- |
| Neovim 0.12.0 or later | `NTS/README.md:19`, `NTS/lua/nvim-treesitter/health.lua:27-29`, commit `c82bf96f` (2026-04-01) | 0.11.5 today, 0.12.5 is the target | `install()` stops at `config.lua:171` because `vim.list.unique` is new in 0.12 (`RT/doc/news.txt:309`). A test on 0.11.5 gave `attempt to index field 'list' (a nil value)`. |
| `tree-sitter` CLI 0.26.1 or later, from a package manager, not npm | `NTS/README.md:21`, `NTS/lua/nvim-treesitter/health.lua:10`, `health.lua:53-66` | 0.25.10 from npm, a Node script wrapper | Each install runs `tree-sitter build -o parser.so` (`NTS/lua/nvim-treesitter/install.lua:305-317`). With no CLI, each build fails. See the log below. |
| `node` | not necessary since commit `fd2880e8` (2025-10-30) | nvm Node 24.11.1 | Only the npm wrapper needs it: its first line is `#!/usr/bin/env node`. With no `node` on `PATH`, each build fails. |
| A C compiler | `NTS/README.md:22` | `/usr/bin/cc`, Apple clang 15.0.0 | `tree-sitter build` stops with `Failed to execute the C compiler`. |
| `curl` and `tar` | `NTS/README.md:20`, `NTS/lua/nvim-treesitter/install.lua:236-274` | `/usr/bin/curl` 8.7.1, `/usr/bin/tar` bsdtar 3.5.3 | Not tested. The code logs `Error during download` or `Error during tarball extraction`. |
| A writable install directory on `runtimepath` | `NTS/lua/nvim-treesitter/health.lua:90-104` | `stdpath('data')/site` is on `runtimepath` by default | The health check reports an error. |

The log of the three failure tests (install of `rust`, CLI 0.25.10 or none):

```text
# No tree-sitter on PATH
error(install/rust): Error during "tree-sitter build": vim/_core/system:324: ENOENT: no such file or directory (cmd): 'tree-sitter'

# The npm wrapper on PATH, but no node
error(install/rust): Error during "tree-sitter build": env: node: No such file or directory

# CC=/nonexistent/cc (simulates no C compiler)
thread 'main' panicked at cli/src/main.rs:848:18:
called `Result::unwrap()` on an `Err` value: Failed to execute the C compiler with the following command:
LC_ALL="C" "/nonexistent/cc" "-O2" ...
```

The CLI 0.25.10 from npm, with `node` on `PATH`:

- It built all 49 parsers of the `ensure` list and their dependencies.
- It built `pod` and `swift`, two parsers that the registry marks with `generate = true`.
- `:checkhealth nvim-treesitter` reports `❌ ERROR tree-sitter-cli v0.26.1 is required`.

Thus 0.25.10 works today for this list, but the plugin does not support it. The minimum became 0.26.1 in commit `5465196b` (2026-01-29). Commit `fd2880e8` sets `TREE_SITTER_JS_RUNTIME=native` for `tree-sitter generate` (`NTS/lua/nvim-treesitter/install.lua:205-211`). The message of that commit gives `tree-sitter` 0.26 as the minimum for this variable.

The maintainer does not recommend npm. This is the reply on https://github.com/nvim-treesitter/nvim-treesitter/issues/8572:

> Installing `tree-sitter-cli` with `npm` is _not_ recommended; it must be in your default $PATH.

The npm wrapper is on `PATH` only in a shell that loads nvm. Its first line is `#!/usr/bin/env node` (`~/.nvm/versions/node/v24.11.1/lib/node_modules/tree-sitter-cli/cli.js:1`).

Homebrew on this machine has two formulas, from `brew info`:

- `tree-sitter-cli` 0.27.0 is the CLI.
- `tree-sitter` 0.27.0 is the library. It is installed.

In `PATH`, the nvm `bin` directory is entry 6 and the Homebrew `bin` directory is entry 7. Thus after `brew install tree-sitter-cli`, the npm 0.25.10 wrapper still comes first. The plan must remove the npm package (`npm uninstall -g tree-sitter-cli`) or change the order of `PATH`.

The README gives this support policy: the latest stable Neovim and the latest nightly (`NTS/README.md:24-28`). Neovim 0.12.5 is the latest stable release.

## 3. The parsers of the `ensure` list

A script read the registry of `NTS` (323 languages) and looked up each name of `CFG:270-277`.

| Result | Parsers |
| --- | --- |
| In the registry, tier 1 (stable) | `python` |
| In the registry, tier 2 (unstable) | the other 42 names |
| Absent from the registry | none |
| New name | none |
| Needs `tree-sitter generate` | none. In the whole registry, only `latex`, `mlir`, `ocamllex`, `perl`, `pod`, `swift`, `teal`, and `unison` need it. |
| Dependencies that `install()` adds | `dtd` (for `xml`), `ecma` and `jsx` (for `javascript`, `typescript`, `tsx`), `html_tags` (for `html`, `svelte`), `php_only` (for `php`), `tsv` (for `csv`) |
| Dependencies that are also in the list | `c` (for `cpp`), `css` (for `scss`), `markdown_inline` (for `markdown`), `typescript` (for `tsx`) |
| Query-only entries (no parser) | `ecma`, `html_tags`, `jsx` |

The dependencies come from the `requires` field. `install()` adds them automatically (`NTS/lua/nvim-treesitter/config.lua:163-169`). Thus 43 names give 49 installs and 46 parser files.

The live machine has 60 parsers from `master`. Two of them left the registry of `main`:

| Parser | Change | What happens with the spec |
| --- | --- | --- |
| `jsonc` | removed in commit `d2350758` (2025-12-06) | The `json` parser now has a registration for the filetype `jsonc` (`NTS/plugin/filetypes.lua:27`). |
| `tmux` | removed in commit `78bebef1` (2026-07-18), because the upstream repository removed its generated files | The gate at `CFG:297` skips `tmux`. The Vim syntax stays. |

The other 15 live parsers that are not in the `ensure` list are in the registry: `blade`, `editorconfig`, `hcl`, `just`, `kotlin`, `make`, `nginx`, `odin`, `pem`, `powershell`, `properties`, `query`, `r`, `terraform`, and `tsv`. The `FileType` autocommand of the spec installs each one when a buffer of that language opens.

## 4. `nvim-treesitter-textobjects` `main`: the configuration shape

The `main` branch is a standalone plugin (commit `e8165e1`). It has no `plugin/` directory, no module system, and no default keymap. It does not call `nvim-treesitter`. It uses only the parsers and its own `queries/<lang>/textobjects.scm` files.

`setup()` stores options only (`NTO/lua/nvim-treesitter-textobjects/init.lua:4-8`). These are the options and their defaults (`NTO/lua/nvim-treesitter-textobjects/config.lua:5-36`):

| Option | Default | Meaning |
| --- | --- | --- |
| `select.lookahead` | `false` | Jump forward to the next text object. |
| `select.lookbehind` | `false` | Look back for a text object. |
| `select.selection_modes` | `{}` | A map from capture to `'v'`, `'V'`, or `'<c-v>'`, or a function. |
| `select.include_surrounding_whitespace` | `false` | A boolean, or a function. |
| `move.set_jumps` | `true` | Add each move to the jumplist. |

Each keymap is a `vim.keymap.set` call to a module function. This shape comes from `NTO/README.md:43-194`. The `<lhs>` values are placeholders:

```lua
require('nvim-treesitter-textobjects').setup({
  select = { lookahead = true, selection_modes = { ['@function.outer'] = 'V' } },
  move = { set_jumps = true },
})

local select = require('nvim-treesitter-textobjects.select')
local move = require('nvim-treesitter-textobjects.move')
local swap = require('nvim-treesitter-textobjects.swap')

-- select: modes x and o
vim.keymap.set({ 'x', 'o' }, '<lhs>', function()
  select.select_textobject('@function.outer', 'textobjects')
end)

-- move: modes n, x, and o
vim.keymap.set({ 'n', 'x', 'o' }, '<lhs>', function()
  move.goto_next_start('@function.outer', 'textobjects')
end)
-- also: goto_next_end, goto_previous_start, goto_previous_end, goto_next, goto_previous
-- a list of captures is permitted: { '@loop.inner', '@loop.outer' }

-- swap: mode n
vim.keymap.set('n', '<lhs>', function() swap.swap_next('@parameter.inner') end)
vim.keymap.set('n', '<lhs>', function() swap.swap_previous('@parameter.inner') end)

-- optional: repeat the last move with ; and ,
local rm = require('nvim-treesitter-textobjects.repeatable_move')
vim.keymap.set({ 'n', 'x', 'o' }, '<lhs>', rm.repeat_last_move_next)
vim.keymap.set({ 'n', 'x', 'o' }, '<lhs>', rm.repeat_last_move_previous)
-- builtin_f_expr, builtin_F_expr, builtin_t_expr, builtin_T_expr make f, F, t, T repeatable
```

The signatures:

| Function | Source |
| --- | --- |
| `select.select_textobject(query_string, query_group)` | `NTO/lua/nvim-treesitter-textobjects/select.lua:154` |
| `move.goto_next_start`, `goto_next_end`, `goto_previous_start`, `goto_previous_end`, `goto_next`, `goto_previous`, each `(query_strings, query_group)` | `NTO/lua/nvim-treesitter-textobjects/move.lua:159-199` |
| `swap.swap_next`, `swap.swap_previous`, each `(query_strings, query_group)` | `NTO/lua/nvim-treesitter-textobjects/swap.lua:209-222` |
| `repeatable_move.repeat_last_move`, `repeat_last_move_next`, `repeat_last_move_previous`, `builtin_f_expr`, and the other `builtin_*_expr` functions | `NTO/lua/nvim-treesitter-textobjects/repeatable_move.lua:95-161` |

The `query_group` can also be `locals` or `folds`, for example `@local.scope` or `@fold` (`NTO/README.md:88-91`, `NTO/README.md:136-142`).

Notes for the choice of keys:

- The README sets `vim.g.no_plugin_maps = true` in `init` to stop the ftplugin maps (`NTO/README.md:21-31`). For example, `RT/ftplugin/python.vim:59` maps `]]`, `[[`, `]m`, and `[m` when that variable is not set.
- The Neovim 0.12.5 markdown ftplugin maps `]]` and `[[` in each markdown buffer. It does not read `no_plugin_maps` (`RT/ftplugin/markdown.lua:7-12`). A buffer-local map wins over a global map.
- The README says "peek", but `main` has no LSP interop. Commit `c1ab434` removed it.
- The custom-capture example of the README gives a third argument `mode` to `select_textobject` (`NTO/README.md:226-230`). The function has two parameters (`select.lua:154`).

The sandbox did a test of `select_textobject('@function.outer')`, `goto_next_start('@function.outer')`, and `swap_next('@parameter.inner')` on `sample.lua`. All three worked (section 7.6).

## 5. Plugins of `lazy-lock.json` and the nvim-treesitter API

Method:

- The research cloned each of the other 40 plugins of the lockfile into the sandbox.
- It searched the HEAD of each default branch with `git grep` for `nvim-treesitter`, `ts_utils`, `get_parser_configs`, `define_modules`, `nvim_treesitter#`, `TSInstall`, and `TSUpdate`.
- It searched the latest semver tag of 16 plugins in the same way.
- It searched each plugin for `vim.treesitter.get_parser`. Neovim 0.12 changed this function: it returns `nil` for no parser and does not raise an error (`RT/doc/news.txt:500-501`).

| Plugin | Version that the research read | Reference to nvim-treesitter | Works with `main` and 0.12.5 |
| --- | --- | --- | --- |
| `telescope.nvim` | branch `0.1.x` at `a0bbec2` (the spec asks for `0.1.x`), tag `v0.2.2`, `master` at `40aedd8` | `0.1.x` calls `nvim-treesitter.configs`, `nvim-treesitter.parsers`, and `nvim-treesitter.locals` in `lua/telescope/previewers/utils.lua:6-8` and `lua/telescope/builtin/__files.lua:371-440`. `v0.2.2` and `master` have no reference. | `0.1.x`: no. The file previewer fails with `attempt to call field 'ft_to_lang' (a nil value)`, issue https://github.com/nvim-telescope/telescope.nvim/issues/3487. `v0.2.2` and `master`: yes. |
| `Comment.nvim` | `e30b7f2` (2024-06-09), the HEAD and the locked commit | none | No, on 0.12. For a buffer with no parser, `ft.calculate` gets `nil` from `get_parser` and fails (`lua/Comment/ft.lua:293-305`). Sandbox: `gcc` in a `conf` buffer shows `[Comment.nvim] nil`. Issue #517 is open. The fix PRs #518 and #521 are not merged. |
| `nvim-ts-autotag` | `88c1453` | `init()` returns when `define_modules` is `nil` (`lua/nvim-ts-autotag.lua:7-14`). `internal.lua:458-466` reads `nvim-treesitter.configs` only when `setup()` was not called. | Yes. The spec calls `setup()`. Sandbox: `<section>` got `</section>` in `html` and `typescriptreact`. |
| `nvim-ts-context-commentstring` | `6141a40`, the HEAD and the locked commit | `plugin/ts_context_commentstring.lua:17-22` returns when `define_modules` is `nil`. The old module path is deprecated (`internal.lua:143-151`). | Yes. `utils.lua:56-63` accepts a `nil` parser. It calls `nvim_buf_get_option`, which is deprecated but present (`RT/doc/deprecated.txt:127`). |
| `sidekick.nvim` | `3d80a47` (HEAD), tag `v2.3.0` | `nvim-treesitter-textobjects.shared.textobject_at_point` in `lua/sidekick/cli/context/textobject.lua:41-55` | Yes. The signature agrees with `NTO/lua/nvim-treesitter-textobjects/shared.lua:314`. |
| `mini.surround` | `8d5d0c5` (HEAD), tag `v0.18.0` | `nvim-treesitter.query` in `lua/mini/surround.lua:1058` and `1491`, only with `use_nvim_treesitter = true` (default `false`) | Yes. The config does not use `gen_spec.input.treesitter`. With `main`, the plugin uses the core API. |
| `nvim-dap-virtual-text` | `fbdb48c`, the HEAD and the locked commit | `ts_utils` and `nvim-treesitter.parsers`, only when the core functions are absent (`lua/nvim-dap-virtual-text/virtual_text.lua:15-21`, `100-121`) | Yes. 0.12 has the core functions. The config does not call its `setup()` (`.config/nvim/lua/plugins/debug.lua:92` is a comment). |
| `lazy.nvim` | `306a055`, tag `v11.17.5` | `pcall(require, "nvim-treesitter")` in `LZ/lua/lazy/core/util.lua:379-384` | Yes. `vim.pack` replaces it. |
| `conform.nvim` | `016802d` (HEAD), tag `v9.1.0` | The `format-queries` formatter needs a script that `main` removed (`lua/conform/formatters/format-queries.lua:1-15`). | Yes. The config does not use that formatter. |
| `nvim-lspconfig` | `ffd261c` (HEAD) | The docs of `ts_query_ls` name the path `/lazy/nvim-treesitter/parser/` (`lua/lspconfig/configs/ts_query_ls.lua:31-35`). | Yes. The config does not use `ts_query_ls`. |
| `treesj` | `79aedb4`, the HEAD and the locked commit | A comment only (`lua/treesj/treesj/utils.lua:28`). nvim-treesitter is optional (`README.md:46-49`). | Yes. It uses the core API. |
| `trouble.nvim` | `bd67efe`, tag `v3.7.1` | A message text only (`lua/trouble/view/treesitter.lua:78`) | Yes. |
| `blink.cmp` | `473c928` (HEAD), tag `v1.10.2` | none. The search found `snippets_utils`, which is not `ts_utils`. | Yes. `lib/window/docs.lua:92-93` accepts a `nil` parser. |
| the other 27 plugins: `friendly-snippets`, `gitsigns.nvim`, `gruvbox.nvim`, `harpoon`, `lazydev.nvim`, `lualine.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim`, `mason.nvim`, `mini.pairs`, `minuet-ai.nvim`, `multicursor.nvim`, `nvim-dap`, `nvim-dap-go`, `nvim-dap-python`, `nvim-dap-ui`, `nvim-lint`, `nvim-nio`, `nvim-web-devicons`, `oil.nvim`, `plenary.nvim`, `snacks.nvim`, `supermaven-nvim`, `venv-selector.nvim`, `vim-fugitive`, `vim-maximizer`, `which-key.nvim` | the HEAD of each default branch | none | Not affected by the nvim-treesitter API. The plugin audit covers 0.12.5 in general. |

About `telescope.nvim`: `.config/nvim/lua/plugins/python.lua:6` loads it only as a dependency of `venv-selector.nvim`. The Telescope GUI of `venv-selector.nvim` has no previewer (a `git grep` for `preview` in its `lua` directory found nothing). Thus the failure shows only in a Telescope picker with a file preview.

About `Comment.nvim`: `nvim-ts-context-commentstring` also works with the built-in `gc` of Neovim (`nvim-ts-context-commentstring/README.md:71`). The plugin audit must choose the replacement.

## 6. The live machine (read only)

The research read these files. It ran no git command in them.

| Fact | Evidence |
| --- | --- |
| The spec in `~/dotfiles` asks for `main`. | `~/dotfiles/.config/nvim/lua/plugins/lsp.lua:250-253`. That file differs from `CFG` only at line 184 (`pyright` against `basedpyright`). |
| The live lockfile says `main` at `4916d65`. | `~/dotfiles/.config/nvim/lazy-lock.json:27` |
| The clone is on `master` at `42fc28b`, which is tag `v0.10.0` (2025-05-24). | `.git/HEAD` is `ref: refs/heads/master`. `.git/refs/heads/master` is `42fc28b`. `.git/packed-refs` gives `42fc28b` for `refs/tags/v0.10.0`. |
| The clone has no local `main` branch. | `.git/refs/heads` has only `master`. |
| The textobjects clone is on `master` too, at `5ca4aaa`. | `~/.local/share/nvim/lazy/nvim-treesitter-textobjects/.git/HEAD` and `.git/refs/heads/master` |
| `master` parsers are in the plugin directory: 60 `parser/*.so` and 60 `parser-info/*.revision`. | directory lists |
| The install directory of `main` does not exist. | `~/.local/share/nvim/site` is absent. |
| Two source trees of `master` stay in the data directory. | `~/.local/share/nvim/tree-sitter-lua`, `~/.local/share/nvim/tree-sitter-commonlisp` |

Why lazy.nvim did not change the branch:

1. lazy.nvim marks a plugin as installed when its directory exists in the lazy root (`LZ/lua/lazy/core/plugin.lua:219-252`).
2. At startup, lazy.nvim installs only the plugins that are not installed or have a build to do (`LZ/lua/lazy/core/loader.lua:68-93`). The install pipeline clones and checks out a new directory only (`LZ/lua/lazy/manage/init.lua:79-104`).
3. Only the update pipeline adds the branch, fetches, and checks out (`git.origin`, `git.branch`, `git.fetch`, `git.checkout` in `LZ/lua/lazy/manage/init.lua:108-138`). `:Lazy update`, `:Lazy sync`, and `:Lazy restore` run it. `:Lazy restore` is the update with the lockfile (`LZ/lua/lazy/manage/init.lua:141-145`).
4. The checkout step reads the lockfile only when the pipeline sets `lockfile = true` (`LZ/lua/lazy/manage/task/git.lua:328-336`). lazy.nvim writes the lockfile from the state of each clone (`LZ/lua/lazy/manage/lock.lua:11-47`). The research did not find the origin of the `main` entry in the live lockfile.

The code shows what the live spec does on the two `master` clones. No run verified it.

- The `master` module of textobjects, `lua/nvim-treesitter-textobjects.lua`, has `has_textobjects` and `init` only. Thus `CFG:265` raises `attempt to call field 'setup' (a nil value)`, and the rest of the config function does not run.
- The `master` module of nvim-treesitter, `lua/nvim-treesitter.lua:1-22`, has `setup`, `define_modules`, and `statusline` only. Thus `install` and `get_available` do not exist. If the plan removes the textobjects call, `CFG:278` and `CFG:288` fail too.

The `master` branch does not support Neovim 0.12. Commit `cf12346a` (2026-03-23) put this text in its README (https://github.com/nvim-treesitter/nvim-treesitter/blob/master/README.md):

> **Neovim 0.10 or 0.11** (Neovim 0.12 is **not supported**)

Issue https://github.com/nvim-treesitter/nvim-treesitter/issues/8618 reports the markdown crash of `master` on 0.12. The maintainer closed it as "not planned", with this reply:

> The `master` branch is obsolete and not compatible with Nvim 0.12, please read the documentation.

What the migration must clean up:

| Path | Content | Why | Action |
| --- | --- | --- | --- |
| `~/.local/share/nvim/lazy/nvim-treesitter/parser/*.so` and `parser-info/*.revision` | 60 parsers and 60 revision files of `master` | `master` builds parsers into the plugin directory (`configs.lua:584-592` of `master`). They are ignored build output (`parser/.gitignore` of `master` ignores `*`), thus a checkout of `main` does not remove them. | Delete them with the lazy root. |
| `~/.local/share/nvim/lazy/` | the lazy root, 44 entries | `vim.pack` uses `stdpath('data')/site/pack/core/opt` (`RT/doc/pack.txt:213-219`). | Delete after `vim.pack` works. The `vim.pack` research covers the details. |
| `~/.local/share/nvim/tree-sitter-lua/`, `~/.local/share/nvim/tree-sitter-commonlisp/` | parser sources | The `master` installer downloads into `stdpath('data')` (`utils.lua:131-141` of `master`). Its last step removes the source tree (`install.lua:451-453` of `master`). Thus these two installs did not finish. | Delete. |
| `~/.local/share/nvim/site/parser`, `site/parser-info`, `site/queries` | absent today | These are the install directories of `main` (`NTS/lua/nvim-treesitter/config.lua:10`, `config.lua:25-40`). They do not overlap with `site/pack`. | Nothing to clean. `main` makes them. |

A caution for the order of the migration: `main` installs each query directory as a symbolic link into the plugin directory (`NTS/lua/nvim-treesitter/install.lua:343-350`, `install.lua:444-446`). The sandbox shows `site/queries/bash -> <plugin>/runtime/queries/bash`.

If a person installs parsers with `main` under lazy.nvim and then deletes the lazy root, each link has no target. `:TSUpdate` does not repair the links, because it compares only the parser revision (`NTS/lua/nvim-treesitter/install.lua:172-176`). To prevent this problem, go from the lazy `master` clone directly to `vim.pack`. If the links have no target, run `:TSInstall!` with the language names, or delete `site/queries` and install again.

## 7. Sandbox test with Neovim 0.12.5

Setup:

- `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_CACHE_HOME` point into `SBX/rt-027`.
- `init.lua` adds three plugins with `vim.pack.add` and `{ confirm = false }`: `nvim-treesitter` (`version = 'main'`), `nvim-treesitter-textobjects` (`version = 'main'`), and `nvim-ts-autotag`.
- A copy of `CFG:259-365` in `ts_config.lua` runs after `vim.pack.add`. The research copied the lines and did not link them.
- `vim.pack` installed `nvim-treesitter` at `f603a2f`, textobjects at `5c7b026`, and autotag at `88c1453`.
- `PATH` starts with the `tree-sitter` 0.27.0 release binary. A second run in `SBX/rt-025` used the npm 0.25.10 wrapper.

### 7.1 Install of the `ensure` list

On the first start, the `install(ensure)` call of the spec ran in the background. A script waited for the log:

```text
expected=49 finished=49 ok=49 errors=0 seconds=15.3
installed parsers: 46
```

The run with the npm CLI 0.25.10 gave the same result in 14.9 s. When all parsers are installed, `install(ensure)` takes 1.3 ms, and `init.lua` takes 7.8 ms in total (`--startuptime`).

### 7.2 Highlights and injections

After `:edit`, each sample buffer had an active highlighter and the treesitter `indentexpr`. `:verbose setlocal indentexpr?` gave the sandbox `init.lua` as the last source. Thus the `FileType` callback of the spec runs after the runtime indent plugins. The startup order agrees: Neovim enables the filetype and indent plugins before it loads the user config (`RT/doc/starting.txt:457-462`).

| File | Filetype | Language | Injected languages |
| --- | --- | --- | --- |
| `sample.lua` | `lua` | `lua` | none |
| `sample.py` | `python` | `python` | `regex` |
| `sample.go` | `go` | `go` | none |
| `sample.md` | `markdown` | `markdown` | `bash`, `json`, `lua`, `markdown_inline`, `python` |
| `sample.html` | `html` | `html` | `css`, `javascript` |
| `sample.tsx` | `typescriptreact` | `tsx` | none |
| `sample.conf`, `sample.txt` | `conf`, `text` | no parser | Vim syntax stays |

`vim.treesitter.get_captures_at_pos()` gave captures from the correct language in each injected region. The output of two runs, with row and column from 0:

```text
sample.md    5,0 -> markdown:@markup.raw.block lua:@keyword
sample.md    2,5 -> markdown:@spell markdown_inline:@markup.italic markdown_inline:@conceal
sample.md    11,0 "def f(x):" -> markdown:@markup.raw.block python:@keyword.function
sample.md    16,0 "echo \"$HOME\" | grep -c x" -> markdown:@markup.raw.block bash:@function.call bash:@function.builtin
sample.md    20,2 "{ \"a\": [1, 2, 3] }" -> markdown:@markup.raw.block json:@property json:@conceal
sample.html  4,6 "      body { color: red; }" -> css:@tag
sample.html  7,6 "      const x = () => 1;" -> javascript:@keyword
```

Row 5 of `sample.md` is `local x = function(a)` in a `lua` fence. Row 2 is the line with `*inline*`.

The headless runs attached no UI, and thus showed no drawn screen. For this reason, a second test ran Neovim in a real terminal under `script`.

The second test opened all samples, moved to the end and back, and ran `:redraw!`. It also added a new `go` code fence to `sample.md`. The message history had no treesitter error. A third run read the screen cells of three markdown fences with `nvim__inspect_cell()`. The first letter of the code had highlight attributes when treesitter was on, and no attributes when treesitter was off:

```text
treesitter on : "l" (lua local) bold + color, "d" (python def) color, "e" (bash echo) color
treesitter off: no attributes on these three cells
```

This is the case that crashed on `master` (`CFG:246-249`, issue #8618). It works on `main`.

### 7.3 Auto-install and the gate

- `sample.rs` (`rust`, not in the `ensure` list): the `FileType` callback installed `rust` and then started the highlighter. The log shows one download, one build, and one install. A counter saw one `FileType` event and one `install()` call.
- The filetypes `fugitive` and `oil` got no highlighter and no install.

### 7.4 Indent and folds

The indent test removed the white space at the start of each line, ran `gg=G`, and compared the result with the original file:

| File | Result |
| --- | --- |
| `sample.lua` | same as the original |
| `sample.go` | same as the original |
| `sample.tsx` | same as the original |
| `sample.html` | 2 lines differ: the CSS line in `<style>` and the JavaScript line in `<script>` got indent 0. The runtime `HtmlIndent()` also gives 0 for the CSS line, but 6 for the JavaScript line. |
| `sample.py` | not a valid test, because Python indent is syntax. A typed test gave a correct indent after `if x:`. After `return 1`, `o` gave indent 0. The runtime `python#GetIndent()` gives 8. |

Folds with `foldmethod=expr` and `foldexpr=v:lua.vim.treesitter.foldexpr()` gave these levels, one digit for each line:

```text
sample.lua   00122211011222100
sample.py    00012212332
sample.go    00001233321
sample.md    11112333212332122212221221111
```

### 7.5 Health checks

`:checkhealth nvim-treesitter` with the CLI 0.27.0. `SBX` replaces the sandbox path:

```text
nvim-treesitter:                                                            ✅

Requirements ~
- ✅ OK Neovim was compiled with tree-sitter runtime ABI version 15 (required >=13).
- ✅ OK tree-sitter-cli 0.27.0 (SBX/bin-ts027/tree-sitter)
- ✅ OK tar 3.5.3 (/usr/bin/tar)
- ✅ OK curl 8.7.1 (/usr/bin/curl)

OS Info ~
- version: Darwin Kernel Version 23.6.0: Mon Jul 29 21:14:30 PDT 2024; root:xnu-10063.141.2~1/RELEASE_ARM64_T6030
- release: 23.6.0
- machine: arm64
- sysname: Darwin

Install directory for parsers and queries ~
- SBX/rt-027/data/nvim/site
- ✅ OK is writable.
- ✅ OK is in runtimepath.

Installed languages     H L F I J ~
- bash                  ✓ ✓ ✓ ✓ ✓
- c                     ✓ ✓ ✓ ✓ ✓
- comment               ✓ . . . .
- cpp                   ✓ ✓ ✓ ✓ ✓
- css                   ✓ . ✓ ✓ ✓
- csv                   ✓ . . . .
- diff                  ✓ . ✓ . ✓
- dockerfile            ✓ . . . ✓
- dtd                   ✓ ✓ ✓ . ✓
- ecma
- git_config            ✓ . ✓ . ✓
- git_rebase            ✓ . . . ✓
- gitattributes         ✓ ✓ . . ✓
- gitcommit             ✓ . . . ✓
- gitignore             ✓ . . . ✓
- go                    ✓ ✓ ✓ ✓ ✓
- gomod                 ✓ . . . ✓
- gosum                 ✓ . . . .
- gotmpl                ✓ ✓ ✓ . ✓
- html                  ✓ ✓ ✓ ✓ ✓
- html_tags
- ini                   ✓ . ✓ . ✓
- javascript            ✓ ✓ ✓ ✓ ✓
- jsdoc                 ✓ . . . .
- json                  ✓ ✓ ✓ ✓ ✓
- json5                 ✓ . . . ✓
- jsx
- lua                   ✓ ✓ ✓ ✓ ✓
- luadoc                ✓ . . . .
- luap                  ✓ . . . .
- markdown              ✓ . ✓ ✓ ✓
- markdown_inline       ✓ . . . ✓
- php                   ✓ ✓ ✓ ✓ ✓
- php_only              ✓ ✓ ✓ ✓ ✓
- phpdoc                ✓ . . . .
- python                ✓ ✓ ✓ ✓ ✓
- regex                 ✓ . . . .
- rust                  ✓ ✓ ✓ ✓ ✓
- scss                  ✓ . ✓ ✓ ✓
- sql                   ✓ . ✓ ✓ ✓
- svelte                ✓ ✓ ✓ ✓ ✓
- toml                  ✓ ✓ ✓ ✓ ✓
- tsv                   ✓ . . . .
- tsx                   ✓ ✓ ✓ ✓ ✓
- typescript            ✓ ✓ ✓ ✓ ✓
- vim                   ✓ ✓ ✓ . ✓
- vimdoc                ✓ . . . ✓
- xml                   ✓ ✓ ✓ ✓ ✓
- yaml                  ✓ ✓ ✓ ✓ ✓
- zig                   ✓ ✓ ✓ ✓ ✓

  Legend: [H]ighlights, [L]ocals, [F]olds, [I]ndents, In[J]ections ~
```

The same check with the npm CLI 0.25.10 has one error:

```text
nvim-treesitter:                                                          1 ❌

Requirements ~
- ✅ OK Neovim was compiled with tree-sitter runtime ABI version 15 (required >=13).
- ❌ ERROR tree-sitter-cli v0.26.1 is required
```

`:checkhealth vim.treesitter` with the CLI 0.27.0 has no error and no warning. It has 323 lines with `OK`. The start of the output, and a summary of the rest:

```text
vim.treesitter:                                                             ✅

Treesitter features ~
- Treesitter ABI support: min 13, max 15
- WASM parser support: false

Treesitter parsers ~
- ✅ OK Parser: bash                      ABI: 15, path: SBX/rt-027/data/nvim/site/parser/bash.so
- ✅ OK Parser: c                         ABI: 15, path: SBX/rt-027/data/nvim/site/parser/c.so
- ✅ OK Parser: c                    (not loaded), path: NVIM/lib/nvim/parser/c.so
...
Treesitter queries ~
- ✅ OK apex            textobjects     SBX/rt-027/data/nvim/site/pack/core/opt/nvim-treesitter-textobjects/queries/apex
...

Summary of the 54 parser lines:
  48 loaded: 47 from SBX/rt-027/data/nvim/site/parser, and query from NVIM/lib/nvim/parser
   6 bundled, not loaded because site comes first: c, lua, markdown, markdown_inline, vim, vimdoc
  ABI 15: 32 parsers, ABI 14: 14 parsers, ABI 13: 2 parsers (gitignore, scss)
Summary of the queries: 269 OK lines, 0 errors.
```

The ABI of each parser comes from its committed `parser.c`. All values are in the range of Neovim 0.12.5, 13 to 15.

### 7.6 Textobjects, autotag, and incremental selection

| Test | Result |
| --- | --- |
| `select_textobject('@function.outer', 'textobjects')` in `sample.lua` at line 4 | selects lines 3 to 8, the whole `function M.add` |
| `goto_next_start('@function.outer', 'textobjects')` from line 1 | cursor goes to line 3 |
| `swap_next('@parameter.inner')` on `a` in `function M.add(a, b)` | `function M.add(b, a)` |
| `nvim-ts-autotag`: type `<section>` in `html` and in `typescriptreact` | `<section></section>` |
| custom `<C-space>` against the built-in `an` | the same selections, see 1.4 |

### 7.7 Languages with no `indents` query

The `I` column of the health output shows no `indents` query for these installed languages: `comment`, `csv`, `diff`, `dockerfile`, `dtd`, `git_config`, `git_rebase`, `gitattributes`, `gitcommit`, `gitignore`, `gomod`, `gosum`, `gotmpl`, `ini`, `jsdoc`, `json5`, `luadoc`, `luap`, `markdown_inline`, `phpdoc`, `regex`, `tsv`, `vim`, and `vimdoc`. Section 1.1 gives the effect.

## 8. Parser update after a plugin update, with no lazy.nvim

What the docs of `main` say:

> **When upgrading the plugin, you must make sure that all installed parsers are updated to the latest version** via `:TSUpdate`.

- The quote is from `NTS/README.md:34`. The README recommends automation and shows only a lazy.nvim spec (`NTS/README.md:35-43`).
- `:TSUpdate` updates each installed parser to the revision of the manifest, when that revision is newer. The help recommends it as a build step of the plugin manager (`NTS/doc/nvim-treesitter.txt:71-79`).
- For a script, `require('nvim-treesitter').update():wait(300000)` runs the update and waits (`NTS/doc/nvim-treesitter.txt:143-160`).
- The docs of `main` do not mention `vim.pack`. A search of the repository for `vim.pack` and `PackChanged` found nothing.

`vim.pack` gives the events `PackChangedPre` and `PackChanged` for this purpose. The event data has `kind` (`install`, `update`, or `delete`), `active`, `spec`, and `path` (`RT/doc/pack.txt:359-400`). The docs give an example hook. It runs `:packadd` first when the plugin is not active in the session. When a hook must run on install, the docs say to make the autocommand before the first `vim.pack.add()` call (`RT/doc/pack.txt:397-399`).

The sandbox did a test of this hook in `SBX/rt-hook`:

```lua
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then vim.cmd.packadd('nvim-treesitter') end
      vim.cmd('TSUpdate')
    end
  end,
})
vim.pack.add({ { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' } })
```

Steps and result:

1. Install `nvim-treesitter` at the locked commit `4916d65`, and install `lua`, `python`, `markdown`, `json`, and `go`.
2. Change `version` to `main`, start again, and run `vim.pack.update({ 'nvim-treesitter' }, { force = true })`.
3. `vim.pack` moved the plugin to `f603a2f`. The hook ran one time. `:TSUpdate` rebuilt only the 3 parsers with a new revision: `json`, `markdown`, and `markdown_inline`. The log ended with `Installed 3/3 languages`.
4. After the update, the revision of each of the 6 parsers agreed with the registry.

The hook does not have a case for `kind == 'install'`, and that case is not necessary. On the first install, `:TSUpdate` has no installed parser to update (`NTS/lua/nvim-treesitter/install.lua:556-561`), and the `install(ensure)` call of the spec installs the list.

## Sandbox files

These files are in `SBX` and not in the repository:

| File | Purpose |
| --- | --- |
| `samples/` | the sample files of the tests |
| `src/` | clones of `nvim-treesitter` and `nvim-treesitter-textobjects` |
| `plugins/` | clones of the other 40 plugins of the lockfile |
| `bin-ts027/tree-sitter` | the `tree-sitter` 0.27.0 release binary |
| `rt-027/`, `rt-025/`, `rt-hook/`, `rt-comment/`, `rt-011/` | the XDG directories of each test |
| `run.sh` | starts the 0.12.5 binary with the XDG directories of one test |
| `wait-install.lua`, `check-files.lua`, `check2.lua`, `check3.lua`, `check-noindent.lua`, `check-swap.lua`, `check-autotag.lua`, `check-comment.lua`, `tui-test.lua`, `tui-md.lua`, `fail-install.lua`, `hook-a.lua`, `hook-b.lua`, `time-calls.lua` | the test scripts |
| `check-ensure.lua`, `gen-list.lua`, `live-check.lua` | the scripts that read the registry |
| `rt-027-*.txt`, `rt-025-*.txt`, `fail-*.txt`, `gen-*.txt`, `hook-*.txt` | the test output |
