# AGENTS.md

A Neovim 0.12 config. Plugins install with the built-in `vim.pack`. This repo is a squashed subtree at
`.config/nvim` in joelstoddard/dotfiles: a change reaches the live editor only after a subtree pull there.

## Commands

- **Lint:**
  - `nix run nixpkgs#lua51Packages.luacheck -- init.lua lua tests`
  - `nix run nixpkgs#stylua -- --check init.lua lua tests` (format with the same command minus `--check`)
- **Test:** `sh tests/run.sh`, or `sh tests/run.sh tests/test_<area>.lua` for one file.
  - The first run installs every plugin, parser and Mason tool into `~/.local/share/nvim-test`, which takes several
    minutes. If it stops part-way (for example, a network drop), rerun it: finished items are kept.
  - The test install keeps the plugin revisions from its first run. Delete `~/.local/share/nvim-test` to make the
    next run reinstall at the latest versions the plugin list allows.
  - Do not start two first runs at the same time: they share that install.
  - Each test case starts its own nvim on this checkout's config, through `tests/helpers.lua`.
  - Mason checks its registry online about once a day. Offline, that check warns, and the startup test reports the
    warning.

## Layout

- `init.lua`: load order.
- `lua/config/`: core settings, keymaps, autocommands, LSP, indent shading.
- `lua/plugins/`: one file per plugin; `init.lua` there lists every plugin for `vim.pack`.
- `lua/languages/`: one file per language (parsers, servers, linters, formatters, line length); a new language file
  also needs an entry in the `names` list in `lua/languages/init.lua`.
- `tests/`: the suite (mini.test), the runner and the install bootstrap.

## Conventions

- Work in a git worktree, never in the main checkout.
- Write the failing test first, with `sh tests/run.sh <file>`.
- Specs stay untracked in `.claude/specs/`: committed files are copied into the dotfiles.
- Test fixtures go in temporary folders outside the repo. yamlls skips validation for files under git-ignored
  folders, so a fixture there can pass for the wrong reason.
- Never point a test or a worktree config at `~/.local/share/nvim`.
