# From `lazy.nvim` to `vim.pack` on Neovim 0.12.5

Research date: 2026-09-19. Target: Neovim `v0.12.5` (2026-08-23). This document examines how to replace `lazy.nvim` with the built-in `vim.pack` in `.config/nvim`. It does not change the config.

All tests ran in the sandbox `scratchpad/nvim-research/vimpack/` with the 0.12.5 binary. Section 7 gives the paths and the scripts. A line reference such as `pack.lua:1004` points to the file of the tag `v0.12.5` (see "Sources"). The local runtime files are identical to the tag.

## Summary

| Question | Answer | Evidence |
| --- | --- | --- |
| Status of `vim.pack` | Experimental. The manual says `experimental, yet should be stable enough for daily use`. Four functions: `add`, `update`, `del`, `get`. No user commands in 0.12.5. The development branch (0.13) adds commands, a lockfile option, manifests, and a fixed event order. | `pack.txt:210-211`, section 1.9 |
| Lockfile | `nvim-pack-lock.json` in `stdpath('config')`. JSON with `rev`, `src`, and `version` for each plugin. `~/.config/nvim` is a symlink into `~/dotfiles`, thus the file lands in the live repository. Commit it. | `pack.lua:231-233`, `pack.lua:822-839` |
| Second Mac | A restart installs the missing plugins at the lockfile revisions, in one parallel batch (41 plugins, 8 s). It does not move plugins that are already on disk: run `vim.pack.update(nil, { target = 'lockfile' })`. | `pack.txt:331-345`, test D |
| First start | `vim.pack.add()` blocks `init.lua`. It asks for confirmation for each call with new plugins, clones in parallel, and stops with `timeout` after 120 s. | `pack.lua:514-588`, `_async.lua:3`, test C |
| Build steps | Only `nvim-treesitter` (`:TSUpdate`). Use a `PackChanged` autocmd for `kind == 'update'`, made before the first `vim.pack.add()`. `blink.cmp` `v1.10.2` downloads its library itself. | section 3, test D |
| `lazy.nvim` features in use | 12 spec fields. `keys` 7 specs (61 keys), `opts` 17, `config` 13, `dependencies` 13 specs (23 entries), `event` 5, `branch` 5, `lazy` 6, `ft` 3, `version` 3, `priority` 2, `opts_extend` 1, `build` 1. Also 1 spec fragment, the `setup('plugins')` import, and the bootstrap. | section 2 |
| Startup, median of 10 TUI runs | `lazy.nvim`: 89.7 ms. `vim.pack` with all plugins at start: 110.0 ms. `vim.pack` with manual lazy loading of the same 9 plugins: 89.9 ms. | section 4.4 |
| Most costly plugins | `treesj` 10.8 ms, `nvim-treesitter` 6.3 ms, `nvim-dap` 6.1 ms, `harpoon` 4.8 ms, `mason-lspconfig.nvim` 4.6 ms. The nine `vim.pack.add()` calls: 10.8 ms for 41 plugins. | section 4.5 |
| Layout | Keep `lua/plugins/<group>.lua`. Each file calls `vim.pack.add()`, then runs the setup code. Add `lua/pack.lua` for the build hook, the lazy-load helpers, and three commands. | section 5 |
| Necessary changes outside the specs | Call `vim.loader.enable()`. Replace `Snacks.picker.lazy()` (`<leader>sp`). Remove `'lazy.nvim'` and `'LazyVim'` from the `lazydev` library. Write `version = vim.version.range('1.*')`. Use one URL for `mason.nvim`. | sections 1.3, 2, 6 |
| Largest risks | Strict semver tags from 0.12.3. The 120 s limit. An interrupted clone that breaks each start. No dependency graph. A clean-up filter that deletes the plugins of a group that failed. | sections 1.9, 6 |

## 1. The `vim.pack` API of 0.12.5

### 1.1 Status

- `vim.pack` is new in 0.12 (`news.txt:374`).
- The manual gives this warning: `It is still considered experimental, yet should be stable enough for daily use` (`pack.txt:210-211`).
- The development branch already changes the API for 0.13 (section 1.9). Thus, keep the hooks small, and read `news.txt` before the upgrade to 0.13.

### 1.2 Functions

| Function | Options | What it does | Source |
| --- | --- | --- | --- |
| `vim.pack.add(specs, opts)` | `confirm` (default `true`). `load`: `false` during `init.lua`, `true` after it, or a function. | Installs the missing plugins, writes the lockfile, then runs `:packadd` (or the `load` function) for each plugin. | `pack.txt:420-454`, `pack.lua:1004-1064` |
| `vim.pack.update(names, opts)` | `force` (default `false`), `offline` (default `false`), `target` (`'version'` or `'lockfile'`) | Fetches, shows a confirmation buffer (`:write` applies, `:quit` cancels), writes `nvim-pack.log` in `stdpath('log')`. | `pack.txt:489-539`, `pack.lua:1263-1351` |
| `vim.pack.del(names, opts)` | `force` (default `false`) | Deletes the directories and the lockfile entries. Refuses an active plugin without `force`. | `pack.txt:456-465`, `pack.lua:1362-1399` |
| `vim.pack.get(names, opts)` | `info` (default `true`: branches and tags through Git) | Returns `active`, `path`, `rev`, `spec`, `branches`, `tags` for each plugin. | `pack.txt:467-487`, `pack.lua:1432-1487` |

Other facts:

- 0.12.5 has no user commands. `:packupdate` and `:packdel` exist only on the development branch (commit `b62c1049c`, PR #39693).
- `:checkhealth vim.pack` exists (`lua/vim/pack/health.lua`). It took 3.5 s for 41 plugins in the sandbox (issue #41645).
- The confirmation buffer has `]]` and `[[`, and an in-process LSP client for `gO`, `K`, and code actions (`pack.txt:503-523`).
- Measured in sandbox C: `vim.pack.update()` took 1.5 s for 41 plugins with a fetch, and 0.34 s with `offline = true`.
- `:restart lua vim.pack.update()` restarts Neovim and opens the update buffer (`gui.txt:96`).

### 1.3 Spec fields and versions

| Field | Type | Meaning |
| --- | --- | --- |
| `src` | string, necessary | A URL that `git clone` accepts. |
| `name` | string | The directory name. Default: the last part of `src` without `.git`. |
| `version` | `nil`, string, or `vim.VersionRange` | `nil`: the default branch. A string: a branch, a tag, or a commit. A range: the greatest semver tag in the range. |
| `data` | any | Free data. An event gets it in `ev.data.spec.data`. |

Source: `pack.txt:403-417`, `pack.lua:365-395`.

Version rules that affect this config:

- A plain string is a branch, a tag, or a commit, never a range. `version = '1.*'` stops with the error `is not a branch/tag/commit` (`pack.lua:628-636`). Write `version = vim.version.range('1.*')`.
- From 0.12.3, a range matches only strict semver tags, for example `v1.2.3` or `1.2.3` (`pack.txt:221-224`, `pack.lua:261-263`, PR #39342). Tags such as `v3.7` (`vim-fugitive`) or `v0.100` (`nvim-web-devicons`) do not match. Issue #40611 closed this as expected behavior.
- If no tag matches, `add()` and `update()` stop with the error `No versions fit constraint` (`pack.lua:644-653`).
- `nvim-treesitter` has the strict tag `v0.10.0` from 2025-05-24. This tag is on the archived `master` line, not on `main` (`git merge-base --is-ancestor` in the sandbox clone). A range such as `vim.version.range('*')` thus selects the old code. Keep `version = 'main'`.
- An update keeps the old default branch after a rename upstream. To get the new default branch, delete and add the plugin again (`pack.txt:499-501`).

Duplicate names:

- In one `add()` call, two specs with one name and a different `src` or `version` stop the call with a `Conflicting src` error (`pack.lua:442-454`).
- In a later `add()` call, vim.pack ignores the second spec without a message (`pack.lua:791-795`, `pack.txt:440-441`). The sandbox test confirmed both cases.
- This config names `mason.nvim` twice: `williamboman/mason.nvim` in `debug.lua:9` and `mason-org/mason.nvim` in `lsp.lua:196` and `lsp.lua:204`. Use `mason-org/mason.nvim` in all places.

### 1.4 Directory and Git

- The plugins go to `stdpath('data')/site/pack/core/opt/<name>` (`pack.txt:213-219`). vim.pack assumes that it manages each directory there.
- vim.pack needs the `git` program. It makes a blobless clone (`--filter=blob:none`) when Git is 2.27 or newer (`pack.lua:279-290`). This Mac has Apple Git 2.39.3.
- Each plugin stays in the detached `HEAD` state. Before an update, vim.pack stashes local changes in the plugin directory (`pack.lua:666-687`).
- After each checkout, it updates the submodules and makes the help tags of `doc/` again (`pack.lua:689-702`).

### 1.5 Lockfile

- Name and location: `nvim-pack-lock.json` in `stdpath('config')` (`pack.lua:231-233`). 0.12.5 has no option to move it. The option `'packlockfile'` exists only on the development branch (commit `0653e7a33`).
- Here, `~/.config/nvim` is a symlink to `../dotfiles/.config/nvim` (`ls -la`). Thus, vim.pack writes the lockfile into the live `~/dotfiles` repository, next to `lazy-lock.json` today. Commit it, and delete `lazy-lock.json` in the same change.
- The manual says: put the lockfile under version control, and do not edit it by hand (`pack.txt:226-235`). vim.pack repairs a damaged entry of an installed plugin.
- vim.pack reads the lockfile at its first call in a session. It installs each plugin that is in the lockfile but not on disk, at the lockfile `rev` (`pack.lua:864-951`).
- Format: JSON with sorted keys and a two-space indent (`pack.lua:822-839`). Each entry has `rev` (a full commit), `src`, and `version` when the spec has one. A string version is kept in single quotes. A range is kept as its bounds.

An excerpt of the prototype lockfile (sandbox C):

```json
{
  "plugins": {
    "blink.cmp": {
      "rev": "78336bc89ee5365633bcf754d93df01678b5c08f",
      "src": "https://github.com/saghen/blink.cmp",
      "version": "1.0.0 - 2.0.0"
    },
    "conform.nvim": {
      "rev": "016802de402556da54c36bd7359b441266b01cdd",
      "src": "https://github.com/stevearc/conform.nvim"
    },
    "harpoon": {
      "rev": "87b1a3506211538f460786c23f98ec63ad9af4e5",
      "src": "https://github.com/ThePrimeagen/harpoon",
      "version": "'harpoon2'"
    }
  }
}
```

Two Macs with one repository. Test D used a copy of the prototype config and an empty data directory:

1. On the Mac that changed the plugins, commit `nvim-pack-lock.json` and push.
2. On the other Mac, pull. Then start Neovim, or use `:restart`.
3. The first `vim.pack.add()` installs each missing plugin at its lockfile revision. In test D, 41 plugins installed in one parallel batch, and the full start took 8 s. The lockfile did not change (fix of issue #41017 in 0.12.5).
4. Plugins that are already on disk stay at their old revision. `add()` does not compare the revision on disk (`pack.txt:437-439`). Run `vim.pack.update(nil, { target = 'lockfile' })` and confirm with `:write`.
5. Test D set the lockfile entry of `conform.nvim` to the older commit `619363c`, as the other Mac would do. After the restart, the plugin stayed at `016802d`. After the update, it was at `619363c`.
6. Delete the plugins that the other Mac removed, with `vim.pack.del({ 'name' })` (`pack.txt:342-345`).

Caution: if you restart before step 6, vim.pack writes the removed plugin into the lockfile again. It shows `Repaired corrupted lock data for plugins: vim-maximizer` (test D). Thus, `git diff` shows the old entry until you run `vim.pack.del()`.

For a script, this command applies the lockfile without the buffer (test D):

```sh
nvim --headless -c 'lua vim.pack.update(nil, { target = "lockfile", force = true })' -c 'qa'
```

### 1.6 Events and build hooks

- `PackChangedPre` comes before a change, and `PackChanged` comes after it (`pack.txt:359-373`).
- `ev.data` has `active`, `kind` (`install`, `update`, or `delete`), `spec`, and `path` (`_meta/events.lua:36-42`).
- Make the autocmd before the first `vim.pack.add()`. If you make it later, it does not see the installs from the lockfile (`pack.txt:397-399`).
- At `install`, the plugin is not loaded yet, and `active` is `false`. If the hook uses code of the plugin, run `vim.cmd.packadd(name)` first (`pack.txt:386-394`).
- vim.pack installs and updates in parallel. In 0.12.5, the order of the events across plugins is not fixed. PR #40455 fixes the order for 0.13 only.
- An `update` event comes after `:write` in the confirmation buffer. With `force = true`, it comes at once (`pack.lua:1304-1346`).

Caution: do not keep the build command only in `spec.data`. On a new Mac, the first `add()` call installs all lockfile plugins. For a plugin of a later `add()` call, the `install` event then has `spec.data = nil` (`pack.lua:906-920`, test E). Select the plugin with `ev.data.spec.name`.

The hook for this config:

```lua
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('user.pack', { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end,
})
```

Test D moved `nvim-treesitter` to an older commit with `vim.pack.update({ 'nvim-treesitter' }, { target = 'lockfile', force = true })`. The hook ran, and `:TSUpdate` printed `All parsers are up-to-date`. `:TSUpdate` loads the parser table again before it compares the revisions (`lua/nvim-treesitter/install.lua:487-491` and `:556-557`). Thus, a restart is not necessary before the hook.

### 1.7 First start with nothing installed

What `vim.pack.add()` does (`pack.lua:1004-1064`):

1. It reads the lockfile and installs the missing lockfile plugins (section 1.5).
2. It finds the plugins of this call that are not on disk.
3. If `confirm` is `true`, it asks `These plugins will be installed: … Proceed? [Y]es, (N)o, (A)lways` (`pack.lua:565-588`). The answer `A` stops the prompts for the rest of the session.
4. It clones and checks out with `2 * uv.available_parallelism()` jobs in parallel (`pack.lua:514-521`). This Mac has 12 cores, thus 24 jobs.
5. It waits for all jobs, and `init.lua` stops at this line. The wait ends with the error `timeout` after 120 s (`_async.lua:3`, `_async.lua:49-53`).
6. It writes the lockfile and runs `:packadd!` for each installed plugin. At the end, it raises one error for all plugins that failed (`pack.lua:1041-1063`).

If you answer `N`, vim.pack installs nothing and raises no error. The `require()` calls after it then fail (`pack.lua:726-737`).

Observed in sandbox C, the prototype with nine `add()` calls and no lockfile:

- The first prompt listed `gruvbox.nvim` only. After `A`, the other eight calls installed without a prompt.
- Then `nvim-treesitter` wrote one message for each parser download. The messages filled the screen and stopped the start at `-- More --` prompts.
- The test left a prompt open for more than 120 s. Two `add()` calls then failed with `_async.lua:53: timeout`, and their plugins did not load in that session.
- The clones completed in the background. The next start repaired the lockfile entry of `telescope.nvim` and loaded all 41 plugins.

This agrees with issue #40629. On a new Mac, answer the prompts at once. Better, commit the lockfile first: then the first `add()` installs all plugins in one batch with one prompt.

### 1.8 Remove a plugin

- Remove the spec from the `vim.pack.add()` calls, restart, then run `vim.pack.del({ 'name' })` (`pack.txt:347-357`).
- A plugin that is on disk but in no `add()` call stays on disk and in the lockfile. Neovim does not load it.
- `vim.pack.update()` without names still updates such a plugin, because the default is all managed plugins (`pack.lua:466-476`, `pack.lua:1259-1267`).
- `:checkhealth vim.pack` reports it as `not active. Is it lazy loaded or did you forget to run vim.pack.del()?` (`pack/health.lua:231-236`).
- `vim.pack.del()` refuses an active plugin unless `force = true`. The error says `Remove them from init.lua, restart, and try again.` (`pack.lua:1374-1398`).
- If you delete a directory by hand, vim.pack sends no event (issue #37594, closed with the label `closed:wontfix`).

The manual gives a filter for all inactive plugins (`pack.txt:352-356`).

Caution: a group file that stops with an error leaves its plugins inactive. In sandbox D, the filter then deleted the ten plugins of the failed group. Use the filter only after a start without errors.

### 1.9 Known bugs and open issues

State on 2026-09-19. The fixes in the release branch come from `git log v0.12.0..v0.12.5 -- runtime/lua/vim/pack.lua`.

| Issue | State | Effect on 0.12.5 | Effect on this config |
| --- | --- | --- | --- |
| [#40629](https://github.com/neovim/neovim/issues/40629) `timeout` in `vim.pack.update()` | Open, `needs:repro`, `has:workaround` | The limit of 120 s applies to install and update. | Reproduced at the first start when a `-- More --` prompt stayed open (section 1.7). Workaround: run again, or update in smaller groups. |
| [#41586](https://github.com/neovim/neovim/issues/41586) An interrupted clone breaks each start | Closed 2026-09-18 by a docs change (PR #41955, 0.13) | Present. The reporter used 0.12.5 on macOS. | Delete the directory that `:checkhealth vim.pack` names. |
| [#41645](https://github.com/neovim/neovim/issues/41645) `:checkhealth vim.pack` is slow | Open | Present | 3.5 s for 41 plugins (sandbox). |
| [#40537](https://github.com/neovim/neovim/issues/40537) Update buffer and session restore | Open | The report uses `:packupdate` (0.13). Not verified on 0.12.5. | Low. Close the update buffer before `:restart`. |
| [#40611](https://github.com/neovim/neovim/issues/40611) Strict semver tags | Closed as expected (PR #39342, in 0.12.3) | Present by design | Ranges only for `blink.cmp` and `mini.*`. Their tags are strict. |
| [#41017](https://github.com/neovim/neovim/issues/41017) Lockfile written again after an install from it | Fixed in 0.12.5 (PR #41031) | Fixed | Test D: the lockfile did not change. |
| [#39612](https://github.com/neovim/neovim/issues/39612) Install prompt at each start on some file systems | Fixed in 0.12.3 (PR #39749) | Fixed | None. |
| [#34764](https://github.com/neovim/neovim/issues/34764) User commands | Done for 0.13 (PR #39693) | No commands | Add your own commands (section 5). |
| [#36078](https://github.com/neovim/neovim/issues/36078) Lockfile location | `'packlockfile'` for 0.13 (PR #40562) | Fixed location | None: the config directory is in the repository. |
| [#34778](https://github.com/neovim/neovim/issues/34778) `packspec` support | Open. 0.13 adds `pkg.json` manifests. | No dependency data | Keep the dependency order by hand. |
| [#34765](https://github.com/neovim/neovim/issues/34765) Local plugins | Open | Not supported | None: the config does not use `dev` or `dir`. |
| [#37594](https://github.com/neovim/neovim/issues/37594) No event after a manual delete | Closed, `closed:wontfix` | Present by design | Use `vim.pack.del()`, not `rm`. |
| [#38763](https://github.com/neovim/neovim/issues/38763) A `wl-copy` process disturbs vim.pack | Closed, not planned | Linux only | None on macOS. |

Other `vim.pack` fixes in the 0.12 line: `available_parallelism()` for the jobs (0.12.1), `GIT_DIR` and `GIT_WORK_TREE` from the environment (0.12.2), a `stash` call for older Git (0.12.2), and a nil `stderr` (0.12.4).

## 2. The `lazy.nvim` features of this config

Method: a script loads each file of `lua/plugins/` and counts the fields of each spec, also in nested `dependencies` (`scripts/count_specs.lua`, output `out/spec_counts.txt`). The files hold 49 spec entries: 26 top-level specs and 23 dependency entries. They name 41 plugins. With `lazy.nvim` itself, `lazy-lock.json` has 42 entries.

| `lazy.nvim` feature | Count | Where | `vim.pack` equivalent |
| --- | --- | --- | --- |
| Source `'owner/repo'` | 49 entries, 15 as a plain string | all files | `src = 'https://github.com/owner/repo'`. A `gh()` helper keeps it short (`pack.txt:279-286`). |
| `dependencies` | 13 specs, 23 entries | `debug.lua` 6, `intellisense.lua` 3, `lsp.lua` 6, `python.lua` 3, `file.lua` 1, `snacks.lua` 4 | No graph. Put the dependency in the same `add()` call or an earlier one. Call its setup first. |
| `opts` (table) | 16 | oil, lazydev, blink.cmp, mason-lspconfig, mason, mason-tool-installer, trouble, mini.pairs, sidekick, venv-selector, snacks, which-key, Comment, mini.surround, treesj, gitsigns | `require('<module>').setup({ … })` after `add()`. |
| `opts` (function) | 1 | The second `gitsigns.nvim` spec: `Snacks.toggle` on `<leader>uG` (`snacks.lua:760-771`) | Plain code after `require('gitsigns').setup()`. |
| `opts_extend` | 1 | `blink.cmp`, `sources.default` | Nothing. Only one spec sets these options. |
| `config` (function) | 13 | gruvbox, nvim-dap, vim-fugitive, nvim-lint, conform, mason-tool-installer, nvim-treesitter, supermaven, nvim-ts-context-commentstring, Comment, lualine, harpoon, multicursor | The body of the function, as plain code after `add()`. |
| `keys` | 7 specs, 61 keys | snacks 41, sidekick 11, trouble 4, treesj 2, venv-selector 1, which-key 1, vim-maximizer 1 | `vim.keymap.set()`. For lazy loading, a key stub (section 4.2). |
| `event` | 5 specs: `BufReadPre` 3, `BufNewFile` 4, `BufReadPost` 1, `BufWritePost` 1, `VeryLazy` 1 | vim-fugitive, nvim-lint, conform, gitsigns, which-key | An autocmd with `once = true` that runs `packadd` and the setup. `VeryLazy` becomes `UIEnter` plus `vim.schedule()`. |
| `ft` | 3 | venv-selector, lazydev, nvim-dap-python | A `FileType` autocmd with a pattern. Only venv-selector is lazy today (note below). |
| `lazy = false` | 4 | oil, vim-fugitive, nvim-treesitter, snacks | The default: an `add()` in `init.lua` loads at startup. |
| `lazy = true` | 2 | nvim-lint, conform | `add(…, { load = function() end })` plus the event autocmd. |
| `priority = 1000` | 2 | gruvbox, snacks | The order of the `require()` calls in `init.lua`. |
| `branch` | 5 | nvim-treesitter `main`, textobjects `main`, telescope `0.1.x`, harpoon `harpoon2`, multicursor `1.0` | `version = '<branch>'`. |
| `version` | 3 | blink.cmp `'1.*'`, mini.pairs `'*'`, mini.surround `'*'` | `vim.version.range('1.*')` and `vim.version.range('*')`. The mini README also gives `version = 'stable'`, a branch (`README.md:77-83`). |
| `build` | 1 | nvim-treesitter `':TSUpdate'` | A `PackChanged` hook (section 1.6). |
| Spec fragment by short name | 1 | `'gitsigns.nvim'` (`snacks.lua:760`) | Merge it into the one gitsigns block. |
| `require('lazy').setup('plugins')` | 1 | `init.lua:23` | An explicit list of `require('plugins.<group>')` calls. |
| Bootstrap clone | 1 | `init.lua:1-13` | Delete it. vim.pack is built in. |

Not used: `cmd`, `init`, `cond`, `enabled`, `dev`, `dir`, `tag`, `commit`, `pin`, `main`, `module`, `optional`, `submodules`, `name`, and `import` in a spec.

Behavior that the config gets from `lazy.nvim` without a spec field:

- `lazy.nvim` calls `vim.loader.enable()` in `setup()` (`lua/lazy/init.lua:61-71` of `lazy.nvim` `306a055`). With vim.pack, call `vim.loader.enable()` at the top of `init.lua`. The loader is experimental (`lua.txt:3718-3720`).
- `lazy.nvim` resets `'runtimepath'` and sets `'packpath'` to `$VIMRUNTIME` (`lua/lazy/core/config.lua:193-214` and `:295-314`). vim.pack keeps the default paths. It needs `stdpath('data')/site` in `'packpath'` (`pack.txt:213-216`).

Code that works only with `lazy.nvim`:

- `snacks.lua:317-322` maps `<leader>sp` to `Snacks.picker.lazy()`. This source reads `require("lazy.core.config").spec` (`lua/snacks/picker/source/lazy.lua:5-6`). In sandbox C, it failed with `module 'lazy.core.config' not found`. Replace it, for example with `Snacks.picker.files({ cwd = vim.fn.stdpath('config') .. '/lua/plugins' })`.
- `intellisense.lua:14-17` gives the `lazydev` library `'lazy.nvim'` and `'LazyVim'`. Without `lazy.nvim`, lazydev finds plugins in `'runtimepath'` and in `pack/*/opt/*` (`lua/lazydev/pkg.lua:66-113`). Remove the two names.

The load set of `lazy.nvim` today (sandbox B, `require('lazy').plugins()` at `VimEnter`):

- `lazy.nvim` loads 33 of its 42 plugins at startup.
- 9 plugins wait for a trigger: `treesj`, `trouble.nvim`, `sidekick.nvim`, `vim-maximizer` (keys), `venv-selector.nvim` (ft and keys), `gitsigns.nvim`, `nvim-lint`, `conform.nvim` (events), and `which-key.nvim` (`VeryLazy`).
- Three triggers have no effect. `vim-fugitive` has `lazy = false` and an `event`, and it loads at startup.
- `lazydev.nvim` (`ft = 'lua'`) is a dependency of `blink.cmp`. `nvim-dap-python` (`ft = 'python'`) is a dependency of `nvim-dap`. Both parents load at startup, thus `lazy.nvim` also loads the two dependencies at startup.

## 3. Build steps

The table gives the latest version of each plugin that has a build or download step. A search of all 41 README files for `build`, `run`, `do`, `make`, `cargo`, and `:TSUpdate` found no other step.

| Plugin and version | Today in `lazy.nvim` | With `vim.pack` | Source |
| --- | --- | --- | --- |
| `nvim-treesitter` `main`, `f603a2f4` (2026-09-19) | `build = ':TSUpdate'` | The `PackChanged` hook for `kind == 'update'` (section 1.6, tested). The config already installs missing parsers at each start. | `README.md:34-42` |
| `nvim-treesitter` tools | — | The README asks for `tree-sitter-cli` 0.26.1 or later, `not npm`. This Mac has 0.25.10 from npm. The report `nvim-treesitter-main` covers this. | `README.md:21` |
| `blink.cmp` `v1.10.2` (latest release, 2026-04-04) | `version = '1.*'`, no build | No build. On a tag, `blink.cmp` downloads its prebuilt fuzzy library at startup. It finds the tag with `git describe --tags --exact-match`. That works on the detached `HEAD` of vim.pack. Sandbox C: `Downloaded pre-built binary successfully`. | `doc/installation.md:3-6`, `lua/blink/cmp/fuzzy/download/git.lua:33-37` |
| `blink.cmp` `main`, `473c928` (not released) | — | Needs Neovim 0.12, `saghen/blink.lib`, and `require('blink.cmp').build():pwait()` with a Rust toolchain. Keep the range `1.*` until a release. | `doc/installation.md:5`, `:14-21`, `:56-65` on `main` |
| `supermaven-nvim` `07d20fc` | none | None. At the first setup, it downloads `sm-agent` to `$XDG_DATA_HOME/supermaven/` (sandbox message). | sandbox C |
| `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim` | none | None. Mason installs the tools at runtime. | `README.md` of each |

## 4. Lazy loading and startup time

### 4.1 What `vim.pack` gives

`vim.pack` has no triggers. It has three load modes through `opts.load` (`pack.lua:790-820`, `pack.txt:449-454`):

- `load = false`, the default during `init.lua`, runs `:packadd!`. The plugin goes into `'runtimepath'`. Neovim sources its `plugin/` files later, in the normal plugin step of startup (`starting.txt:516-523`). Thus, this mode defers nothing.
- `load = true`, the default after `init.lua`, runs `:packadd`. It sources `plugin/` at once, and after `VimEnter` also `after/plugin/`.
- `load = function(plug) … end` registers the plugin as active, but vim.pack does not change `'runtimepath'`. Your trigger runs `vim.cmd.packadd(name)` later. This is the hook for manual lazy loading.

Register all plugins at startup, also the lazy ones. Then a new Mac installs them at startup, and the clean-up filter does not see them as inactive. A `vim.pack.add()` call inside a trigger also works. But a plugin that is not on disk then installs at its first use.

### 4.2 Manual patterns

The helpers of `lua/pack.lua` (section 5) replace the three triggers of this config:

| `lazy.nvim` | Manual pattern |
| --- | --- |
| `keys` | `vim.pack.add(specs, { load = pack.defer })`, then `pack.on_keys(name, keys, setup)`. The stub runs `packadd` and the setup at the first use, then runs the key. |
| `event`, `ft` | `pack.on_event(name, events, pattern, setup)`: an autocmd that loads the plugin once. |
| `VeryLazy` | An `UIEnter` autocmd with `vim.schedule_wrap()`. |
| `cmd` | Not used here. A stub user command with the same name can load the plugin. |

Sandbox tests of these patterns:

- `bench/example_init.lua` used the code of section 5. `<leader>cs` and `<leader>cj` loaded `treesj`, and the table split and joined. `<leader>wm` loaded `vim-maximizer` and ran `:MaximizerToggle`.
- The prototype with lazy loading (configuration L) loaded `gitsigns`, `conform`, and `nvim-lint` when a file opened, and `venv-selector` on `ft=python`.

### 4.3 Method

- Neovim 0.12.5 on macOS 14.6.1, Apple M3 Pro, 12 cores.
- Four configurations, each with its own `XDG_*` directories and `HOME`:
  - A: the current config with `lazy.nvim` at the commits of `lazy-lock.json`.
  - B: the current config with `lazy.nvim` at the latest commits (`:Lazy! sync` without a lockfile).
  - C: a `vim.pack` prototype that loads all 41 plugins at startup. All 41 revisions are the same as in B.
  - L: C with manual lazy loading of the 9 plugins that B defers.
- Each run starts the TUI in its own `tmux` server of 160 x 45 cells, with `--startuptime`. An `UIEnter` autocmd quits after 400 ms.
- The value is the `NVIM STARTED` time of the embedded server. Neovim writes it at the first screen update (`src/nvim/normal.c:1476-1481`).
- Each series has 12 interleaved rounds. Rounds 1 and 2 are a warm-up. The median uses rounds 3 to 12.
- Scenario 1 starts without a file. Scenario 2 opens `bench/sample.lua`, a copy of `lua/plugins/lsp.lua`.
- C and L use the original spec tables (copied to `lua/lazyspec/`) for `opts`, `config`, and `keys`. Thus, they run the same setup code as A and B.

Two changes apply to all four configurations:

- `vim.loader` is off. The sandbox path is long, and the cache file names of the loader went over the 255-byte limit of macOS (`ENAMETOOLONG`). `lazy.nvim` turns the loader on by default. The real times of all configurations are thus lower. This effect is not measured.
- The Mason `ensure_installed` lists are empty, to stop downloads during the runs.

### 4.4 Results

Round 2, median and range of 10 runs, in ms:

| Configuration | No file | `nvim bench/sample.lua` |
| --- | --- | --- |
| A: `lazy.nvim`, locked commits | 97.9 (89.6 to 105.2) | 121.3 (112.8 to 126.0) |
| B: `lazy.nvim`, latest commits | 89.7 (82.2 to 94.5) | 120.5 (111.9 to 131.2) |
| C: `vim.pack`, all plugins at startup | 110.0 (103.0 to 121.5) | 137.7 (122.4 to 153.4) |
| L: `vim.pack`, manual lazy loading | 89.9 (86.8 to 116.8) | 115.0 (107.0 to 129.8) |

Round 1 (A, B, and C only) gave the same order. Without a file: 90.5, 90.0, and 106.3 ms. With the Lua file: 119.4, 120.5, and 134.1 ms.

Findings:

- With all plugins at startup, vim.pack is 14 to 20 ms slower than `lazy.nvim` (C against B).
- In C, the 9 plugins that `lazy.nvim` defers cost 17.5 ms together. This agrees with the difference.
- The same manual lazy loading removes the difference (L against B).
- The plugin versions have no clear effect (A against B). The spread of A in round 2 is larger than the difference.

### 4.5 Costly plugins

The prototype C records the time of each setup (`proto.time()`). The table gives the median of 10 TUI runs, in ms:

| Plugin | Setup | `lazy.nvim` today | Lazy-load option with `vim.pack` |
| --- | --- | --- | --- |
| `treesj` | 10.8 | keys | Key stub, as today. The largest single cost. |
| `nvim-treesitter` with textobjects, autotag, and the parser list | 6.3 | startup | None. The README says `This plugin does not support lazy-loading` (`README.md:46`). |
| `nvim-dap` with dap-ui, dap-go, and dap-python | 6.1 | startup | Key stubs for `<F5>`, `<leader>b`, and the other dap keys. A gain beyond `lazy.nvim`. |
| `harpoon` | 4.8 | startup | Key stubs for `<leader>h…`. |
| `mason-lspconfig.nvim` | 4.6 | startup | Keep at startup: it turns on the LSP servers. |
| `lualine.nvim` | 4.0 | startup | Keep: the first screen shows the status line. |
| `blink.cmp` | 4.0 | startup | `InsertEnter` is possible. Not measured. |
| `mini.surround` | 3.5 | startup | Key stubs are possible. |
| `supermaven-nvim` | 3.4 | startup | `InsertEnter` is possible. |
| `multicursor.nvim` | 3.1 | startup | Key stubs are possible. |
| `oil.nvim` | 2.5 | startup (`lazy = false`) | Keep. The config comment says that lazy loading is `very tricky` (`file.lua:9`, oil `README.md:44`). |
| `mason.nvim` | 2.3 | startup | Keep. |
| `gruvbox.nvim`, with the `colorscheme` | 2.1 | startup | Keep. |
| `venv-selector.nvim` | 2.1 | ft, keys | `FileType python` and a key stub. |
| `gitsigns.nvim` | 1.9 | events | An event autocmd. |
| `trouble.nvim` | 1.4 | keys | A key stub. |
| Each other plugin | less than 1.0 | — | — |
| Nine `vim.pack.add()` calls | 10.8 | — | See the note below. |

Notes:

- The `plugin/` scripts of all plugins take about 2 ms together (`--startuptime` logs of C).
- Most of the `add()` time is `:packadd!`: 8.5 ms for 41 plugins in a micro test (`bench/packaddcost.lua`).
- One `add()` call for 41 plugins and nine calls cost the same, about 10 ms (`bench/addcost.lua`, 12 runs each). Thus, one file for each group costs nothing extra.

## 5. File layout

Keep one file for each plugin group, as `lua/plugins/` does today:

```text
.config/nvim/
├── init.lua              options, vim.loader, core, pack hooks, then the groups
├── nvim-pack-lock.json   written by vim.pack, committed (replaces lazy-lock.json)
├── lua/core/             unchanged
├── lua/pack.lua          gh(), PackChanged hook, lazy-load helpers, commands
└── lua/plugins/
    ├── colors.lua
    ├── snacks.lua
    ├── file.lua
    ├── git.lua
    ├── intellisense.lua
    ├── lsp.lua
    ├── ml.lua
    ├── python.lua
    └── debug.lua
```

Rules for the group files:

- Each file starts with one `vim.pack.add()` call for its plugins. Then it runs the setup code in dependency order.
- Two groups can add one plugin, for example `nvim-web-devicons` or `plenary.nvim`. The first call wins, and the second does nothing (`pack.txt:440-441`). Give the same `src` and `version` in both.
- Do not move the group files into the `plugin/` directory of the config. Neovim sources that directory in alphabetical order after `init.lua`. The order of the groups is important: `colors` first, and `snacks` before the `gitsigns` code that uses `Snacks`.

`init.lua`:

```lua
vim.loader.enable() -- lazy.nvim did this before (experimental)

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.termguicolors = true

require('core')
require('pack') -- the PackChanged hook must exist before the first vim.pack.add()

for _, group in ipairs({ 'colors', 'snacks', 'file', 'git', 'intellisense', 'lsp', 'ml', 'python', 'debug' }) do
  require('plugins.' .. group)
end
```

`lua/pack.lua`:

```lua
local M = {}

function M.gh(repo)
  return 'https://github.com/' .. repo
end

-- Build steps (lazy.nvim `build`).
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('user.pack', { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == 'nvim-treesitter' and kind == 'update' then
      if not ev.data.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end,
})

-- Manual lazy loading: vim.pack.add(specs, { load = M.defer }), then a trigger.
function M.defer() end

local loaded = {}
function M.load(name, setup)
  if loaded[name] then
    return
  end
  loaded[name] = true
  vim.cmd.packadd(name)
  if setup then
    setup()
  end
end

-- lazy.nvim `keys`: the first use loads the plugin, then runs the key.
function M.on_keys(name, keys, setup)
  for _, k in ipairs(keys) do
    vim.keymap.set(k.mode or 'n', k[1], function()
      M.load(name, setup)
      if type(k[2]) == 'function' then
        return k[2]()
      end
      vim.api.nvim_feedkeys(vim.keycode(k[2]), 'n', false)
    end, { desc = k.desc, expr = k.expr })
  end
end

-- lazy.nvim `event` and `ft`.
function M.on_event(name, events, pattern, setup)
  vim.api.nvim_create_autocmd(events, {
    pattern = pattern,
    once = true,
    callback = function()
      M.load(name, setup)
    end,
  })
end

-- 0.12.5 has no commands (0.13 adds :packupdate and :packdel).
vim.api.nvim_create_user_command('PackUpdate', function(o)
  vim.pack.update(#o.fargs > 0 and o.fargs or nil)
end, { nargs = '*', desc = 'Update plugins, confirm with :write' })

vim.api.nvim_create_user_command('PackRestore', function()
  vim.pack.update(nil, { target = 'lockfile' })
end, { desc = 'Move plugins to the lockfile revisions' })

vim.api.nvim_create_user_command('PackClean', function()
  local names = vim.iter(vim.pack.get(nil, { info = false }))
    :filter(function(p) return not p.active end)
    :map(function(p) return p.spec.name end)
    :totable()
  if #names > 0 then
    vim.pack.del(names)
  end
end, { desc = 'Delete plugins that no vim.pack.add() names' })

return M
```

Example 1, `nvim-treesitter` in `lua/plugins/lsp.lua` (a branch, a build step, loaded at startup):

```lua
local gh = require('pack').gh

vim.pack.add({
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  { src = gh('nvim-treesitter/nvim-treesitter-textobjects'), version = 'main' },
  gh('windwp/nvim-ts-autotag'),
})

-- The body of the old `config` function, unchanged:
require('nvim-ts-autotag').setup()
local nts = require('nvim-treesitter')
nts.setup()
require('nvim-treesitter-textobjects').setup({})
-- parser list, FileType autocmd, incremental selection (lsp.lua:267-365 today)
```

Example 2, `treesj` in `lua/plugins/snacks.lua` (lazy loading on keys, the largest startup cost):

```lua
local pack = require('pack')

-- treesj uses nvim-treesitter, which lsp.lua adds at startup.
vim.pack.add({ pack.gh('Wansmer/treesj') }, { load = pack.defer })

pack.on_keys('treesj', {
  { '<leader>cj', function() require('treesj').join() end, desc = 'Code join (collapse block)' },
  { '<leader>cs', function() require('treesj').split() end, desc = 'Code split (expand block)' },
}, function()
  require('treesj').setup({ use_default_keymaps = false })
end)
```

## 6. Risks and gaps

| `lazy.nvim` gives | `vim.pack` 0.12.5 | Effect on this config |
| --- | --- | --- |
| The `:Lazy` UI: list, install, update, clean, log, profile | The update buffer with `]]`, `[[`, `gO`, `K`, and code actions. `vim.pack.get()`. `nvim-pack.log`. No list view, no clean command, no user commands. | Low. The three commands of section 5 cover the daily work. |
| Profiling (`:Lazy profile`) | `--startuptime` only | Low. |
| Lazy-load triggers (`event`, `ft`, `keys`, `cmd`) | `load = function` plus your autocmds and keymaps | Medium. 9 plugins, 14 to 20 ms. The helpers of section 5 cover them. |
| `dependencies` and the load order | None. `packspec` is open (#34778). 0.13 adds `pkg.json` manifests. | Low. Each group lists the dependencies next to the parent. |
| `opts` merge, `opts_extend`, spec fragments | None | Low. One fragment (gitsigns) and one `opts_extend` without effect. |
| `build` | A `PackChanged` hook. No event order across plugins in 0.12.5. | Low. Only `nvim-treesitter`. |
| `vim.loader` on by default | Call `vim.loader.enable()` yourself (experimental) | Medium. Without it, the start is slower. |
| `:checkhealth lazy` | `:checkhealth vim.pack`, 3.5 s for 41 plugins (#41645) | Low. |
| `:Lazy restore` | `vim.pack.update(nil, { target = 'lockfile' })` | Medium. Necessary on the second Mac after each pull that changes the lockfile. |
| `:Lazy clean` | A filter plus `vim.pack.del()`. It also deletes the plugins of a group that failed. | Medium. Run it only after a start without errors. |
| An install window at the first start | Messages in the command line, one prompt for each `add()` call, a limit of 120 s | Medium on a new Mac without the lockfile. Low with the lockfile. |
| Loose version ranges | Strict semver tags only (from 0.12.3) | Low. Do not give a range to `nvim-treesitter`, `vim-fugitive`, or `nvim-web-devicons`. |
| Help from the README (`readme` option) | Help tags from `doc/` only | Low. |
| Reload after a config change | None. `:restart` exists. | Low. |
| Local plugins (`dev`, `dir`) | None (#34765) | None. |
| Recovery after an interrupted clone | None. Each start fails until you delete the directory (#41586). | Medium. `:checkhealth vim.pack` names the directory. |
| `Snacks.picker.lazy()`, `lazydev` library names | They break without `lazy.nvim` | Must change (section 2). |
| A mixed migration | `lazy.nvim` sets `'packpath'` to `$VIMRUNTIME` (`config.lua:295-297`). A `vim.pack.add()` inside the `lazy.nvim` config does not find `site/pack`. | Medium. Change all groups in one commit. Or set `performance.reset_packpath = false` for the transition. |
| A stable API | 0.13 adds commands, `'packlockfile'`, a fixed event order, and manifests | Medium. Read `news.txt` before 0.13. |

Cross-references:

- The versions to select for each plugin (for example `telescope.nvim` `0.1.x` against the tag `v0.2.2`, or `multicursor.nvim` `1.0` against `main`) are in the report `nvim-plugin-audit`.
- The `tree-sitter-cli` version and the `main` branch of `nvim-treesitter` are in the report `nvim-treesitter-main`.

## 7. Sandbox and method

The sandbox directory is `/private/tmp/claude-504/-Users-s-ved-repos-me-dotfiles/ab6923e3-134a-4336-a1e2-0d2bd3791268/scratchpad/nvim-research/vimpack/`. All paths below are relative to it.

| Path | Content |
| --- | --- |
| `sbxA/`, `sbxB/` | The copied config with `lazy.nvim`: A with `lazy-lock.json`, B without it. Each has `lua/plugins/zz_bench.lua` (empty Mason lists) and the loader off in `init.lua`. |
| `sbxC/config/nvim/` | The `vim.pack` prototype: `init.lua`, `lua/proto/pack.lua`, `lua/plugins/*.lua`, `lua/lazyspec/` (the original specs), `nvim-pack-lock.json`. `PROTO_LAZY=1` selects configuration L. |
| `sbxD/`, `sbxE/` | The tests of the second Mac, the build hook, the removal, and `spec.data` |
| `scripts/env.sh`, `scripts/bench1.sh`, `scripts/benchall2.sh`, `scripts/summary.sh` | The environment and the startup measurement |
| `scripts/count_specs.lua`, `scripts/lazy_loaded.lua`, `scripts/ptimes.lua` | The spec count, the `lazy.nvim` load set, and the setup times |
| `bench/example_init.lua`, `bench/addcost.lua`, `bench/packaddcost.lua` | The test of the section 5 helpers and the micro tests |
| `logs/`, `out/` | The raw `--startuptime` logs and the outputs |
| `neovim/` | A blobless clone of `neovim/neovim` for `git log` and `git merge-base` |

## Sources

Neovim `v0.12.5` (the local runtime files are identical to the tag):

- `runtime/doc/pack.txt`: <https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/pack.txt>
- `runtime/lua/vim/pack.lua`: <https://github.com/neovim/neovim/blob/v0.12.5/runtime/lua/vim/pack.lua>
- `runtime/lua/vim/pack/health.lua`: <https://github.com/neovim/neovim/blob/v0.12.5/runtime/lua/vim/pack/health.lua>
- `runtime/lua/vim/_async.lua`: <https://github.com/neovim/neovim/blob/v0.12.5/runtime/lua/vim/_async.lua>
- `runtime/lua/vim/_meta/events.lua`: <https://github.com/neovim/neovim/blob/v0.12.5/runtime/lua/vim/_meta/events.lua>
- `runtime/doc/news.txt`, `lua.txt`, `starting.txt`, `gui.txt`: <https://github.com/neovim/neovim/tree/v0.12.5/runtime/doc>
- `src/nvim/normal.c`: <https://github.com/neovim/neovim/blob/v0.12.5/src/nvim/normal.c>
- Development branch items: commits `b62c1049c` (`:packupdate`), `0653e7a33` (`'packlockfile'`), `4cdd6d76c` (manifests), PR #40455 (event order): <https://github.com/neovim/neovim/pull/40455>
- Issues: see the table in section 1.9.

Plugins, at the revisions of the prototype lockfile:

- `lazy.nvim` `306a055`: <https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/lua/lazy/init.lua> and <https://github.com/folke/lazy.nvim/blob/306a05526ada86a7b30af95c5cc81ffba93fef97/lua/lazy/core/config.lua>
- `nvim-treesitter` `f603a2f4`: <https://github.com/nvim-treesitter/nvim-treesitter/blob/f603a2f4da48728f80257fb5fbb90145fd1dc173/README.md> and <https://github.com/nvim-treesitter/nvim-treesitter/blob/f603a2f4da48728f80257fb5fbb90145fd1dc173/lua/nvim-treesitter/install.lua>
- `blink.cmp` `v1.10.2`: <https://github.com/saghen/blink.cmp/blob/v1.10.2/doc/installation.md> and <https://github.com/saghen/blink.cmp/blob/v1.10.2/lua/blink/cmp/fuzzy/download/git.lua>
- `blink.cmp` `main` `473c928`: <https://github.com/saghen/blink.cmp/blob/473c928d8b9b5b3f638cd085a01899972cf205c6/doc/installation.md>
- `lazydev.nvim` `ff2cbcb`: <https://github.com/folke/lazydev.nvim/blob/ff2cbcba459b637ec3fd165a2be59b7bbaeedf0d/lua/lazydev/pkg.lua>
- `snacks.nvim` `882c996`: <https://github.com/folke/snacks.nvim/blob/882c996cf28183f4d63640de0b4c02ec886d01f2/lua/snacks/picker/source/lazy.lua>
- `mini.surround` `580e4cb`: <https://github.com/nvim-mini/mini.surround/blob/580e4cb98c5900d9fe743865fb5a5b2178b4ab18/README.md>
- `oil.nvim` `b73018b`: <https://github.com/stevearc/oil.nvim/blob/b73018b75affd13fa38e2fc94ef753b465f770d7/README.md>

This config: `.config/nvim/init.lua` and `.config/nvim/lua/plugins/*.lua` at the commit `edeb72b` of the branch `unified`.
