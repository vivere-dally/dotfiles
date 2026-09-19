# dotfiles

- (mac) `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- install stow

  - (linux) `sudo apt install stow`
  - (mac) `sudo brew install stow`

- alacritty:
  - some [terminal issues](https://unix.stackexchange.com/questions/597445/why-would-i-set-term-to-xterm-256color-when-using-alacritty)
  - TLDR:
    - download the alacritty/extra/ folder and copy it into the alacritty/ you just made, then:
    - `sudo tic -xe alacritty,alacritty-direct extra/alacritty.info`

TODO - automate poetry install


useful:
- https://github.com/wez/wezterm/discussions/4680

## Neovim

The configuration requires Neovim 0.12 or later. Install the Tree-sitter command line tool through Homebrew. The npm package can hide the Homebrew version when nvm comes first in `PATH`.

```sh
brew upgrade neovim
brew install tree-sitter-cli
npm uninstall -g tree-sitter-cli
scripts/stow.sh
```

Start Neovim and accept the plugin installation prompt. The first start installs the plugins from `nvim-pack-lock.json`. Parser and Mason installations continue in the background.

Use these commands for plugin maintenance:

- `:PackUpdate` fetches updates and opens a review buffer. Write that buffer to apply the updates.
- `:PackRestore` moves installed plugins to the revisions in the lock file. Run it after a pull changes `nvim-pack-lock.json`.
- `:PackClean` removes plugins that the configuration no longer names. Run it only after a start with no plugin group error.

Run `:checkhealth vim.pack` when an installation stops. An interrupted clone can leave a partial plugin directory. Delete only the directory that the health report names, then start Neovim again.

## LLM usage

Run `llm-usage` to show daily token use and estimated API cost for Claude Code, Codex, OpenCode, and pi. The command reads the local data of each harness and uses the offline pricing data from ccusage.

Pass ccusage commands and options after the wrapper name:

```sh
llm-usage monthly
llm-usage session
llm-usage codex daily
llm-usage daily --since 20260901 --json
```

In Neovim, `:LlmUsage` opens the daily report in a floating window. Pass the same arguments to the command, for example `:LlmUsage codex monthly`. Use `r` to refresh the report and `q` to close it.

The wrapper pins ccusage. The first run downloads that version through `bunx`. Later runs use the Bun cache.
