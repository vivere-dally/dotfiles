# Neovim Keymap Cheatsheet

## Essentials (NEW)

| Key | Action |
|-----|--------|
| `jk` | Exit insert mode |
| `H` | Start of line |
| `L` | End of line |
| `Ctrl+s` | Save file |
| `Esc` | Clear search + close floats |
| `leader q` | Close buffer |
| `leader Q` | Quit all |

---

## Surround (CHANGED: c → s)

| Key | Action |
|-----|--------|
| `sa{motion}{char}` | Add surrounding |
| `sd{char}` | Delete surrounding |
| `sr{old}{new}` | Replace surrounding |
| `sf{char}` | Find next |
| `sF{char}` | Find prev |

---

## Code (leader c)

| Key | Action |
|-----|--------|
| `leader cr` | Rename symbol |
| `leader ca` | Code action |
| `leader cf` | Format |
| `leader cl` | Lint |
| `leader cj` | Join block |
| `leader cs` | Split block |

---

## LSP Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `grr` | References |
| `gi` | Implementations |
| `grt` | Type definition |
| `gD` | Declaration |
| `gs` | Signature help |
| `K` | Hover docs |
| `gl` | Show diagnostic |
| `]d` | Next diagnostic |
| `[d` | Prev diagnostic |

---

## Search & Replace

| Key | Action |
|-----|--------|
| `leader /` | Grep project |
| `leader space` | Smart find files |
| `leader ff` | Find all files |
| `leader fr` | Recent files |
| `leader ,` | Buffers |
| `leader rw` | Replace word under cursor |
| `leader sw` | Grep word/selection |

---

## Multicursor (CHANGED)

| Key | Action |
|-----|--------|
| `leader n` | Match & add cursor |
| `leader N` | Match backwards |
| `leader S` | Skip match (was s) |
| `leader P` | Skip backwards (was S) |
| `Up/Down` | Add cursor above/below |
| `Ctrl+q` | Toggle cursor |

---

## Git

| Key | Action |
|-----|--------|
| `leader lg` | Lazygit |
| `leader gs` | Git status |
| `leader gb` | Branches |
| `leader gl` | Git log |
| `leader gf` | File history |
| `]h` | Next hunk |
| `[h` | Prev hunk |
| `leader ghs` | Stage hunk |
| `leader ghr` | Reset hunk |

---

## Windows (leader w)

| Key | Action |
|-----|--------|
| `leader we` | Split vertical |
| `leader wq` | Split horizontal |
| `leader ww` | Close window |
| `leader wr` | Equal size |
| `leader wm` | Maximize toggle |
| `leader wh/j/k/l` | Navigate |

---

## Harpoon (leader h)

| Key | Action |
|-----|--------|
| `leader ha` | Add file |
| `leader hh` | Toggle menu |
| `leader h1-4` | Jump to slot |

---

## Movement

| Key | Action |
|-----|--------|
| `Ctrl+d` | Half-page down (centered) |
| `Ctrl+u` | Half-page up (centered) |
| `n` | Next match (centered) |
| `N` | Prev match (centered) |
| `Ctrl+j` | Quickfix next |
| `Ctrl+k` | Quickfix prev |

---

## Editing

| Key | Action |
|-----|--------|
| `J` (visual) | Move selection down |
| `K` (visual) | Move selection up |
| `leader d` | Delete to void |
| `leader p` | Paste (keep register) |
| `leader X` | Make executable |

---

## Diagnostics (leader x)

| Key | Action |
|-----|--------|
| `leader xx` | Toggle diagnostics |
| `leader xX` | Buffer diagnostics |
| `leader xQ` | Quickfix list |

---

## Debug

| Key | Action |
|-----|--------|
| `leader b` | Toggle breakpoint |
| `F5` | Continue |
| `F6` | Run to cursor |
| `F7` | Step into |
| `F8` | Step over |
| `F9` | Step out |
| `F10` | Step back |
| `F11` | Restart session |
| `leader ?` | Show the value under the cursor |
| `leader u` | Toggle DAP View |

---

## Tabs (leader t)

| Key | Action |
|-----|--------|
| `leader to` | New tab |
| `leader tc` | Close tab |
| `leader tj` | Next tab |
| `leader tk` | Prev tab |

---

## Files

| Key | Action |
|-----|--------|
| `leader -` | Oil file browser |
| `leader e` | Snacks explorer |

---

<style>
body { font-family: system-ui, -apple-system, sans-serif; max-width: 400px; margin: 0 auto; padding: 1rem; background: #1a1a2e; color: #eee; }
h1 { font-size: 1.4rem; text-align: center; border-bottom: 2px solid #4a4a6a; padding-bottom: 0.5rem; }
h2 { font-size: 1rem; color: #7dd3fc; margin: 1rem 0 0.5rem; border-left: 3px solid #7dd3fc; padding-left: 0.5rem; }
table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
th { display: none; }
td { padding: 0.25rem 0.5rem; border-bottom: 1px solid #333; }
td:first-child { font-family: monospace; color: #fbbf24; white-space: nowrap; }
hr { border: none; border-top: 1px solid #333; margin: 0.5rem 0; }
code { background: #2a2a4a; padding: 0.1rem 0.3rem; border-radius: 3px; }
</style>
