# dotfiles

## Install

Run the bootstrap script after you clone the repository:

```sh
scripts/bootstrap.sh
```

The script works on macOS and Linux. It installs the system packages needed to build Python, installs Homebrew when needed, and then installs or updates these tools:

- Stow, Neovim, Tree-sitter, jq, pyenv, uv, Zsh, fzf, ripgrep, fd, lazygit, and tmux
- The latest stable Go toolchain, gopls, Delve, golangci-lint, goimports, and templ
- The latest stable Alacritty release on macOS and Linux
- nvm with the latest Node.js LTS release
- The latest stable CPython release through pyenv. Python does not have an LTS channel.
- The latest Bun release in the nvm-managed Node.js installation
- Oh My Zsh, zsh-autosuggestions, and zsh-syntax-highlighting

Linux installations also get wl-clipboard. The script removes the unsupported npm Tree-sitter CLI when it is present. It compiles the Alacritty terminfo entries into `~/.terminfo` and links the dotfiles. It installs TPM and the configured tmux plugins. It also restores the locked Neovim plugin revisions and verifies the configured parsers and Mason tools. You can run it again after a pull.

## Neovim

The configuration requires Neovim 0.12 or later and Tree-sitter CLI 0.26.1 or later. The bootstrap script installs them and installs the plugins from `nvim-pack-lock.json` without a confirmation prompt.

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

The wrapper pins ccusage. The first run downloads that version through `npx`. Later runs use the npm cache.
