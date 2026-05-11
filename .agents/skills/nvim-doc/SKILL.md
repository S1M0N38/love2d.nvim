---
name: nvim-doc
description: >
  Write, update, and improve love2d.nvim help documentation (vimdoc) in
  doc/love2d.txt. Use when the user asks to write docs, update docs, generate
  the help file, add documentation for a function, or mentions vimdoc, help tags,
  or plugin documentation. Reads the plugin source code to extract API, commands,
  configuration, and other info from LuaCATS annotations and code structure, then
  writes a properly formatted doc/love2d.txt following vimdoc conventions. Do not
  use for general Neovim :help lookups (use nvim-help skill) or for writing
  README.md, CHANGELOG.md, or other non-vimdoc documentation.
allowed-tools: Bash read edit write
---

# love2d.nvim Documentation (vimdoc)

This skill writes and updates love2d.nvim help documentation. The output is
`doc/love2d.txt` — a plain text file that integrates with Neovim's `:help`
system using the vimdoc format.

## Vimdoc format rules

### General

- Text width: 78 characters (set by modeline `tw=78`)
- Section separators: exactly 80 `=` characters
- Tags: `*like-this*` — lowercase, hyphens for sections
- Cross-references: `|like-this|`
- Indentation within sections and code blocks: 2 spaces
- File must end with: `vim:tw=78:ts=8:et:ft=help:norl:`

### Section headers

Title in UPPERCASE left-aligned, tag right-aligned, total width 80 chars:

```
INTRODUCTION                                                           *love2d*
SETUP                                                           *love2d-setup*
COMMANDS                                                     *love2d-commands*
```

### Tags

- Sections: `*love2d-section-name*` (lowercase, hyphens)
- Functions: `*love2d.function()*` (includes parens)

Function tags on a separate line ABOVE the signature, right-aligned:

```
                                                              *love2d.setup()*
love2d.setup({opts}) ~
  Configure the plugin.
```

### Code blocks

Delimited by `>` (with filetype) and `<`:

```
>lua
  require("love2d").setup({
    path_to_love_bin = "love",
  })
<
```

### Configuration docs

Show `setup()` signature, then code block with ALL default options:

```
>lua
  {
    path_to_love_bin = "love",   -- Path to LÖVE binary (string, default: "love")
    output = nil,                -- Output panel: nil (default), false (disable), or table (window config)
  }
<
```

Read the actual config module (`lua/love2d/config.lua`) to get real defaults.

### Command docs

```
:Love run ~
  Run the detected LÖVE project once.

:Love watch ~
  Run with auto-restart on save (debounced 300ms).

:Love stop ~
  Stop the running LÖVE project and/or watch mode.

:Love info ~
  Show info about the current LÖVE project and job state.

:Love output ~
  Toggle the floating output panel.
```

## Workflow

### Step 1 — Read the source code

Read plugin source to extract everything needing documentation. Priority order:

1. **`lua/love2d/init.lua`** — Main module, setup() dispatcher
2. **`lua/love2d/config.lua`** — Default options
3. **`lua/love2d/job.lua`** — Job lifecycle (run/watch/stop/info)
4. **`lua/love2d/output.lua`** — Output panel
5. **`lua/love2d/lsp.lua`** — Dynamic LSP integration
6. **`lua/love2d/events.lua`** — Project detection events
7. **`lua/love2d/autocmd.lua`** — Enter/leave handlers
8. **`lua/love2d/health.lua`** — Health checks
9. **`lua/love2d/types.lua`** — LuaCATS type definitions
10. **`plugin/love2d.lua`** — :Love user command
11. **`compiler/love.lua`** — Compiler plugin (makeprg + errorformat)
12. **`README.md`** — Description (don't copy verbatim)

What to extract:
- **setup() and config defaults**: options, types, defaults, descriptions
- **Exported functions**: name, params, return type, behavior
- **User commands**: name, arguments, completion
- **Autocmds**: events listened to or fired

### Step 2 — Read existing docs (if updating)

Read `doc/love2d.txt` fully before editing. When updating, the goal is
**minimal changes** — only touch what's stale or missing.

- **Preserve existing tag names** — renaming breaks bookmarks
- **Preserve section structure** — never remove sections
- **Preserve narrative text** — explanatory paragraphs help readers
- **Update stale descriptions** — match current code behavior
- **Add missing docs** — new functions, options, commands

### Step 3 — Write the help file

Follow the format rules above. Canonical section order for love2d.nvim:

1. **INTRODUCTION** — `*love2d*` — Description, table of contents
2. **SETUP** — `*love2d-setup*` — Installation and setup()
3. **COMMANDS** — `*love2d-commands*` — :Love subcommands (run, watch, stop, info, output)
4. **LSP** — `*love2d-lsp*` — LSP integration details
5. **GLSL** — `*love2d-glsl*` — Treesitter injection support
6. **TROUBLESHOOTING** — `*love2d-troubleshooting*` — Common issues (optional)

### Step 4 — Validate

```bash
# Check broken references
grep -oP '\|[^|]+\|' doc/love2d.txt | tr -d '|' | sort -u | while read tag; do
  if ! grep -q "\*${tag}\*" doc/love2d.txt; then
    echo "BROKEN REFERENCE: |$tag|"
  fi
done

# Check line width
awk 'length > 78 && !/^\s*$/ { print NR": "length" chars: "$0 }' doc/love2d.txt

# Check matched code blocks
echo "Open: $(grep -c '^>' doc/love2d.txt)  Close: $(grep -c '^<' doc/love2d.txt)"
```
