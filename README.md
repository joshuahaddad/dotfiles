# Dotfiles

Personal shell, terminal, git, and agent configuration for the `azureml` machines. The repo is a flat set of dotfiles plus one project manifest. Nothing here installs itself: copy or symlink the files into place by hand.

## Contents

| Path | What it is |
| --- | --- |
| `.bashrc` | Interactive bash setup: history, prompt, aliases, completion, and an automatic Python venv switcher. |
| `.config/zellij/config.kdl` | Zellij terminal multiplexer keybindings, plugin aliases, and UI options. |
| `.gitconfig.template` | Git identity and GitHub credential helper template. Placeholders must be filled in. |
| `.gatoragents/project.yml` | Manifest for the gatoragents runner: pinned node image, check command, and branch and path rules. |

## `.bashrc`

Loaded for interactive shells only. Non-interactive shells return early.

- **History:** `ignoreboth` (no duplicates, no lines starting with a space), appended rather than overwritten, `HISTSIZE=1000`, `HISTFILESIZE=2000`.
- **Window:** `checkwinsize` is on, so `LINES` and `COLUMNS` track resizes.
- **Prompt:** plain `user@host:path$` by default. A colored prompt is available by setting `force_color_prompt=yes`. For xterm-like terminals the window title is set to `user@host: path`.
- **Aliases:**
  - `ll` = `ls -alF`, `la` = `ls -A`, `l` = `ls -CF`
  - `ls`, `grep`, `fgrep`, `egrep` use `--color=auto`
  - `yq` points at `/usr/local/bin/yq`
  - `alert` sends a desktop notification via `notify-send` with the last command as its text; use it as `long-command; alert`
- **Extra files:** sources `~/.bash_aliases` if it exists, and bash completion from the usual system locations.
- **Auto venv:** `__auto_venv` runs from `PROMPT_COMMAND`. When the current directory is inside a directory with a `.venv/bin/activate` (searched upward from `$PWD`), it activates that venv. It deactivates the venv again when you leave the project. It is added to `PROMPT_COMMAND` only once, even if the file is sourced twice.

## `.config/zellij/config.kdl`

Zellij configuration. The keybindings use `keybinds clear-defaults=true`, so only the bindings below exist. Each mode is entered with a `Ctrl` key. Most modes return to `normal` after one action; `resize` and `move` stay in their mode until you leave with `Esc` or their `Ctrl` key.

| Mode | Enter with | Main bindings |
| --- | --- | --- |
| `normal` | (default) | `Alt n` new pane, `Alt f` toggle floating panes, `Alt [` / `Alt ]` previous / next swap layout, `Alt i` / `Alt o` move tab left / right, `Alt p` toggle pane in group, `Alt Shift p` toggle group marking, `Ctrl q` quit. Arrow and `Alt h/j/k/l` keys move focus. |
| `pane` | `Ctrl p` | Move focus (arrows, `hjkl`); `n` new pane, `d` new pane down, `r` new pane right, `s` new stacked pane; `f` fullscreen, `w` floating, `e` embed/float, `i` pin, `z` toggle frames; `c` rename pane; `x` close pane; `p` switch focus. |
| `tab` | `Ctrl t` | `1`–`9` go to tab; `h`/`l` or arrows previous/next; `n` new tab; `x` close tab; `r` rename tab; `s` toggle sync across panes; `b` break pane to new tab; `[` / `]` break pane left / right; `tab` toggle last tab. |
| `resize` | `Ctrl n` | Arrows or `hjkl` grow a pane in that direction; `HJKL` shrink; `+`, `-`, `=` resize in general. |
| `move` | `Ctrl h` | Arrows or `hjkl` move the pane; `n` / `tab` move to next position; `p` move backwards. |
| `scroll` | `Ctrl s` | Arrows or `hjkl` scroll; `d` / `u` half page; `PageUp` / `PageDown` page; `s` search; `e` edit scrollback in `$EDITOR`. `Ctrl c` jumps to bottom. |
| `search` | `s` in scroll mode, then `Enter` | `n` / `p` next / previous match; `c` case sensitivity; `o` whole word; `w` wrap. |
| `session` | `Ctrl o` | `d` detach (in `session` and `tmux`); `w` session manager; `l` layout manager; `p` plugin manager; `c` configuration; `a` about; `s` share. |
| `tmux` | `Ctrl b` | tmux-style bindings: `c` new tab, `n` / `p` next / previous tab, `%` / `"` split right / down, `,` rename tab, `[` scroll, `o` next pane, `z` fullscreen, `x` close pane, `Ctrl b` sends a literal `Ctrl b` through. |
| `locked` | `Ctrl g` (from any mode) | Only `Ctrl g` is bound, to return to `normal`. |

Shared bindings, available in most modes: `Ctrl g` locks, `Ctrl p` / `Ctrl t` / `Ctrl n` / `Ctrl h` / `Ctrl o` / `Ctrl s` / `Ctrl b` switch to the matching mode, and `Esc` returns to `normal` (except while entering a search or a rename).

Other settings in the file (most are commented-out defaults):

- `default_mode "normal"`
- `web_client { font "monospace" }`
- `load_plugins` loads `zellij:link` on startup.
- Plugin aliases: `about`, `compact-bar`, `configuration`, `filepicker`, `plugin-manager`, `session-manager`, `status-bar`, `strider`, `tab-bar`, `welcome-screen`.
- Web server, session serialization, and mouse behavior are at their defaults. The web server is off (`web_server false`), so it listens on `127.0.0.1:8082` only when started manually.
- Copying uses the terminal's OSC 52 by default, since `copy_command` is unset.

The file header says it was autogenerated by Zellij. Its previous version was copied to a `.bak` file on the original machine.

## `.gitconfig.template`

A template, not a live config. Copy it to `~/.gitconfig` and replace the placeholders:

- `user.email` = `YOUR_EMAIL`
- `user.name` = `YOUR_NAME`

It also sets the GitHub credential helper for `https://github.com` and `https://gist.github.com` to `gh auth git-credential`, so `gh auth login` must be run first. Each `helper =` line first clears any inherited helpers.

## `.gatoragents/project.yml`

Manifest for the gatoragents runner.

- `version`: `gatoragents.project/v1`
- `image`: a pinned `sha256` digest of the node image the runner uses. Changing it changes the runtime for every run.
- `check`: `[["true"]]`, a check command that runs `true` and always passes.
- `branch`: `["agent/*"]`, so runner work is limited to `agent/` branches.
- `refused_paths`: `["^\\.git/"]`, which blocks changes inside `.git/`.

## Setup

1. Copy `.bashrc` to `~/.bashrc`, or source it from your own file.
2. Copy `.config/zellij/config.kdl` to `~/.config/zellij/config.kdl`.
3. Copy `.gitconfig.template` to `~/.gitconfig` and fill in the placeholders, then run `gh auth login`.
4. Leave `.gatoragents/project.yml` in the repo root for the runner to read.

Machine-specific paths and tools referenced here, such as `/usr/local/bin/yq`, `notify-send`, and `gh`, must be installed separately.
