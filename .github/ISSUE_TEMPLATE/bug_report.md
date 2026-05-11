---
name: Bug report
about: Create a report to help us improve
title: 'bug: [replace these brackets with the actual title]'
labels: bug
assignees: S1M0N38
---

**Versions**

- *OS* [e.g. macOS 26.4]
- *Neovim* [e.g. 0.12.2]
- *love2d.nvim* [e.g. 3.0.0]
- *LÖVE* [e.g. 11.5]


## Test with `repro.lua`

> [!IMPORTANT]
> Please do not skip this step. For most users, issues occur because of their Neovim configuration.

1. Create the file `repro.lua` with the following content:

```lua
-- repro.lua — Minimal config for reproducing love2d.nvim issues
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/S1M0N38/love2d.nvim",
})

-- Configure LÖVE executable if not on $PATH
-- vim.g.love2d_path_to_love_bin = "love"

-- You should be able to:
--   - Run :Love run / :Love stop
--   - See GLSL strings highlighted (run :TSInstall glsl)
--   - Hover (<S-k>) on love functions and see documentation

-- Add additional setup here ...
```

2. Open your LÖVE `main.lua` using `repro.lua` as config:

```
nvim -u repro.lua main.lua
```

> [!TIP]
> Alternatively, you can clone this repository, navigate to the `tests/demo-game` directory and run `make dev`.

3. Reproduce the bug

4. If relevant, share any logs or error messages (check `:messages`).

## Expected behavior

What did you expect to happen?

## Actual behavior

What happened instead?

## Steps to reproduce

Write down the steps to reproduce the behavior:

1. Open a LÖVE project file
2. Run `:Love run`
3. Observe the error
4. ...

## Screenshots / Videos

If applicable, add screenshots or recordings to help explain the problem. You can drag and drop images or videos directly into this text area.
