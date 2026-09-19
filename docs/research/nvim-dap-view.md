# Replace nvim-dap-ui with nvim-dap-view

Research date: 2026-09-19. Target: Neovim 0.12.5 and the staged `vim.pack` migration in `.config/nvim`.

## Recommendation

Replace `nvim-dap-ui` and `nvim-nio` with `nvim-dap-view` 1.x in this migration.

Use the default manual mode of `nvim-dap-view`. Keep `<leader>u` as the explicit UI toggle. Remove the four DAP listeners that open and close the UI. This choice fits a workflow that uses the debugger rarely and keeps the layout stable on each launch.

The replacement keeps the features that this config uses. It has scopes, threads and stack frames, watches, breakpoints, the REPL, the debug terminal, and an evaluation hover. It uses one primary window with selectable sections. The current `dap-ui` defaults use six windows in two layouts.

Keep inline virtual text disabled in the first change. The current config did not turn on `nvim-dap-virtual-text`, so this does not remove active behavior. The isolated run verified the built-in implementation with a C parser and `locals` query. It can be enabled later without adding another plugin.

## Versions and dependencies

The latest release is [`v1.2.1`](https://github.com/igorlfs/nvim-dap-view/releases/tag/v1.2.1), published on 2026-08-07. The minimum Neovim version is 0.11. Inline virtual text depends on Neovim 0.12 or later. The official `vim.pack` example uses a `1.*` version range ([installation](https://github.com/igorlfs/nvim-dap-view/blob/v1.2.1/README.md#installation)).

The runtime code depends on `nvim-dap`. It has no dependency on `nvim-nio`. A Nerd Font is optional. Treesitter `locals` queries are necessary only for inline virtual text ([feature documentation](https://github.com/igorlfs/nvim-dap-view/blob/v1.2.1/docs/src/routes/home/%2Bpage.md)).

Use this pack list:

```lua
vim.pack.add({
  gh('mfussenegger/nvim-dap'),
  {
    src = gh('igorlfs/nvim-dap-view'),
    version = vim.version.range('1.*'),
  },
  gh('leoluz/nvim-dap-go'),
  gh('mfussenegger/nvim-dap-python'),
})
```

Remove these pack entries:

```lua
gh('nvim-neotest/nvim-nio')
gh('rcarriga/nvim-dap-ui')
```

`vim.pack` will record the selected 1.x tag in `nvim-pack-lock.json`. After a successful restart, `:PackClean` can remove the inactive `nvim-dap-ui` and `nvim-nio` directories.

## Feature comparison

| Config function | `nvim-dap-ui` | `nvim-dap-view` | Result |
| --- | --- | --- | --- |
| Open, close, and toggle | `open()`, `close()`, `toggle()` | Same API names | Verified |
| Evaluate under the cursor | `dapui.eval()` | `dap-view.hover()` | Verified |
| Scopes | Separate scopes window | Scopes section | Verified |
| Threads and stack frames | Stacks window | Threads section | Verified |
| Watches | Watches window | Watches section | Verified |
| Breakpoint list | Breakpoints window | Breakpoints section | Verified with limits below |
| REPL | `nvim-dap` REPL window | `nvim-dap` REPL section | Verified |
| Debug terminal | Console window | Separate terminal or Console section | Supported. Program output was verified |
| Inline values | Separate `nvim-dap-virtual-text` plugin | Built in and disabled by default | Source verified. Runtime result was inconclusive |
| UI layout | Four left windows and two bottom windows by default | One primary window with sections | Observed |
| Extra dependency | `nvim-nio` | None | Source verified |

The primary layout difference is useful here. In an 80 by 22 headless screen, `dap-ui` opened four 40-column side windows and two 10-line bottom windows. `dap-view` opened one 6-line bottom window. Its default section keys are `W`, `S`, `E`, `B`, `T`, and `R`. `g?` shows the local actions.

`nvim-dap-view` has three documented breakpoint limits. Its panel does not show conditions. The panel does not refresh without an active session. The panel can delete a breakpoint but cannot toggle one ([known issues](https://github.com/igorlfs/nvim-dap-view/blob/v1.2.1/docs/src/routes/known-issues/%2Bpage.md)). These limits do not affect `<leader>b`, which continues to call `dap.toggle_breakpoint()`.

## Exact configuration change

Replace these declarations:

```lua
local ui = require('dapui')

require('dapui').setup()
```

with:

```lua
local view = require('dap-view')

view.setup({
  auto_toggle = false,
  virtual_text = { enabled = false },
})
```

The explicit values document the intended low-disruption behavior. They are also the plugin defaults.

Replace the evaluation mapping with:

```lua
vim.keymap.set('n', '<leader>?', function()
  view.hover(nil, true)
end, { desc = 'dap value under cursor' })
```

Replace the UI toggle with:

```lua
vim.keymap.set('n', '<leader>u', function()
  view.toggle(true)
end, { desc = 'toggle debugger ui' })
```

The `true` argument hides the terminal when the toggle closes the UI. Opening the toggle still restores the primary view and any active debug terminal.

Delete these listeners:

```lua
dap.listeners.before.attach.dapui_config = function()
  ui.open()
end
dap.listeners.before.launch.dapui_config = function()
  ui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  ui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  ui.close()
end
```

All adapter definitions, launch configurations, breakpoints, and step mappings stay as they are.

If automatic behavior is wanted later, set `auto_toggle = true` and do not restore the custom listeners. The plugin opens before `attach` and `launch`. It closes on `event_terminated` or `disconnect` when the last session ends. Its source accounts for multiple sessions ([listeners](https://github.com/igorlfs/nvim-dap-view/blob/v1.2.1/lua/dap-view/listeners.lua)).

## A/B sandbox evaluation

The evaluation used the dedicated Neovim 0.12.5 binary. The `dap-ui` baseline used codelldb with a compiled C program. The `dap-view` run used a local stdio DAP adapter with the same source and state. The sandbox blocks the local socket that codelldb opens. Both runs set a breakpoint inside `twice()`, inspected state, and continued to normal exit.

The root was:

```text
/private/tmp/claude-504/-Users-s-ved-repos-me-dotfiles/ab6923e3-134a-4336-a1e2-0d2bd3791268/scratchpad/nvim-research/dap-view/
```

The two runs had distinct `HOME`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME`, and `XDG_CACHE_HOME` trees under `ui/` and `view/`. They did not use the live Neovim config or data directories.

Evaluation inputs and results:

| Item | Path |
| --- | --- |
| Shared evaluation script | `test.lua` |
| Shared adapter setup | `common-init.lua` |
| C fixture | `target/main.c` |
| Compiled fixture | `target/main` |
| dap-ui init | `ui/config/nvim/init.lua` |
| dap-view init | `view/config/nvim/init.lua` |
| dap-ui result | `results/ui.log` |
| dap-view result | `results/view.log` |

Both sides used `nvim-dap` revision `9e848e0`. The baseline used `nvim-dap-ui` revision `1a66cab` and `nvim-nio` revision `21f5324`. The replacement used the `nvim-dap-view` v1.2.1 source archive.

The dap-view run gave these results:

- Manual open, close, and both toggle directions worked.
- The launch listener opened the primary view when `auto_toggle = true` in the evaluation config.
- codelldb stopped at `main.c:5` in `twice()`.
- Scopes showed `x = 21` and `y = 42`.
- Threads showed the `twice` and `main` frames.
- The breakpoint section showed `main.c:5`.
- A watch showed `x = 21`.
- The hover showed `21`.
- The REPL evaluated `x` as `21`.
- Program output included `result=42`.
- The run received initialization, launch, stop, exit, and termination events.
- The primary dap-view window closed after termination.
- Inline virtual text showed `21` beside `x` and `42` beside `y` after the C parser and its `locals` query were installed.

The first evaluation log marked `auto_close_on_end` as failed because its window counter also counted the evaluation hover. The corrected assertion checks the primary `dap-view://main` window, which was absent after termination. Only `dap-view://hover` remained. The same condition affected the dap-ui result. Close the hover with `q` when it is no longer useful.

The dap-ui REPL assertion failed because codelldb was in command mode and treated `x` as an LLDB memory command. Its hover, scopes, stacks, watches, and breakpoint panel worked. This result is about the adapter context in that run. It is not a missing dap-ui REPL.

The first dap-view virtual-text assertion produced no extmarks because the fixture had not linked the C `locals` query into the sandbox data directory. The fixture then installed the parser and query link in the layout that nvim-treesitter uses. It produced two inline extmarks with the expected values. The final dap-view run had no failed assertions.

## Risks and operating notes

- One window cannot show scopes, threads, and watches at the same time. Use the winbar keys to change sections. This is the primary tradeoff for the smaller layout.
- The UI uses `'winbar'`. A plugin that replaces the winbar must exclude `dap-view`, `dap-view-term`, `dap-view-hover`, and `dap-view-help` buffers.
- The default `follow_tab = false` does not reopen the view after a tab change. The explicit toggle opens it in the current tab.
- Automatic close listens to termination and disconnect. It does not close from an `event_exited` event alone. The tested codelldb session sent both exit and termination.
- The Console section means the debuggee terminal. Adapter output can go to the `nvim-dap` REPL instead. The codelldb run sent `result=42` to the REPL in the dap-view case.
- Inline virtual text is a smaller implementation than `nvim-dap-virtual-text`. It requires a parser and a `locals` query for the current language.
- The current release plans keep the single-window mode. Multiple-window layouts are a separate future option ([v2 plan](https://github.com/igorlfs/nvim-dap-view/issues/64)).

## Post-change validation

After the config change, use one real project for each adapter that matters:

1. Start a session with `<F5>` and confirm that no UI opens by itself.
2. Push `<leader>u` and inspect Scopes, Threads, Breakpoints, Watches, and REPL.
3. Push `<leader>?` on a local variable and expand one structured value.
4. Continue until the program writes output. Inspect the REPL and Console section.
5. Push `<leader>u` twice and confirm that the primary view and terminal close and reopen.
6. End the session and confirm that no primary debug window remains.
7. Do the procedure again with Go, Python, C or C++, and Zig as available.
8. If inline values are wanted, turn on `virtual_text.enabled`, stop on a local variable, and inspect the result before keeping that option.

The replacement is viable now. The single-window design and manual toggle match this config better than the current always-open multi-window layout.
