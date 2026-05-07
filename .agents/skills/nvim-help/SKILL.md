---
name: nvim-help
description: >
  Search and read Neovim's built-in :help documentation to look up API signatures,
  parameter types, option values, and event specifications from the user's installed
  runtime. Use when the user wants to consult reference material — function docs, help
  tags, option descriptions — not when they want to write, create, or debug something.
  Pairs with Context7 (neovim/neovim) for code examples; this skill provides exact
  local signatures and docs.
---

# Neovim Help

Neovim's help docs are plain text in `$VIMRUNTIME/doc/`. Resolve the path once per session:

```bash
VIMRUNTIME=$(nvim -l /dev/stdin <<< 'io.write(vim.env.VIMRUNTIME)' 2>/dev/null)
```

Tags are `*like-this*`, cross-references are `|like-this|`, code blocks are between `>` and `<` lines.

## Search tags by keyword

```bash
grep -i '<keyword>' "$VIMRUNTIME/doc/tags"
```

Output: `<tag>\t<help-file>\t<search-pattern>`

When presenting tag search results, show the **full path** to each file.

## Read a help section for an exact tag

Escape dots (`\.`) and parens (`\(\)`) for sed.

```bash
sed -n '/\*<exact-tag>\*/,/^====/p' "$VIMRUNTIME/doc/<help-file>"
# e.g. sed -n '/\*vim\.keymap\.set()\*/,/^====/p' "$VIMRUNTIME/doc/lua.txt"
# e.g. sed -n '/\*nvim_open_win()\*/,/^====/p' "$VIMRUNTIME/doc/api.txt"
```

## Full-text search across all help files

```bash
grep -rn '<pattern>' "$VIMRUNTIME/doc/"*.txt
```

## Table of contents for a help file

```bash
awk '/^===/{getline; print "  L" NR ": " $0}' "$VIMRUNTIME/doc/<file>"
```

## List all tags in a file

```bash
awk -F'\t' '$2 == "<file>" {print $1}' "$VIMRUNTIME/doc/tags"
```

## List all help files

```bash
ls "$VIMRUNTIME/doc/"*.txt
```

## Output format

Always return the **full raw help text** — not a summary or paraphrase.

### Single file

State the file path **above** the code block, then the raw vimdoc in a fenced block:

From `$VIMRUNTIME/doc/lua.txt`:
```vimdoc
vim.keymap.set({modes}, {lhs}, {rhs}, {opts})               *vim.keymap.set()*
    ...
```

### Multiple files

Use **separate code blocks** for each help file, each with its own file path above.

### Exploratory searches

When a keyword search returns multiple tags, show the **most relevant** section in full.
Then list other relevant tags the user can request next.

## Context7 (optional)

If the Context7 MCP tool is available, query it for richer Lua code examples using
library ID `neovim/neovim`. This complements the exact parameter signatures from
local help docs.

## General rules

- Do not put the file path inside the code block — always above it
- Do not narrate how the text was found
- If multiple help files are relevant, use separate code blocks per file
