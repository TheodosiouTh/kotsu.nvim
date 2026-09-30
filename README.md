# kotsu.nvim

> **kotsu** (コツ): the knack for doing something.

Ask Neovim _how_ to do something and get the fastest key sequence, grounded in **your own keymaps**, in a centred popup.

```
:Kotsu delete to the end of the paragraph
```



- **Fastest way, not just your bindings.** Answers combine your mappings with built-in motions, operators and text objects.
- **Knows your mappings.** Every mapping with a description is sent as context, so answers prefer your bindings over generic ones.
- **One-shot, no chat panel.** Ask, read, press `q`.
- **No dependencies.** Plain Lua, Neovim 0.10+.

## Requirements

- Neovim **0.10+**
- A backend. By default the [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) CLI (`claude`) on your `PATH`, or [your own function](#custom-backend).

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "TheodosiouTh/kotsu.nvim",
  cmd = "Kotsu",
  keys = { { "<Leader>?", function() require("kotsu").prompt() end, desc = "How do I…?" } },
  opts = {},
}
```

Then run `:checkhealth kotsu`.

## Usage

|                        |                       |
| ---------------------- | --------------------- |
| `:Kotsu <question>`    | Ask directly          |
| `:Kotsu` / `<Leader>?` | Open the input prompt |
| `q` / `<Esc>`          | Close the popup       |

Bind the prompt yourself with the always-available `<Plug>` mapping, no `setup()` needed:

```lua
vim.keymap.set("n", "<Leader>?", "<Plug>(kotsu-prompt)", { desc = "How do I…?" })
```

## Configuration

Defaults:

```lua
require("kotsu").setup({
  keymap = "<Leader>?",          -- false = no mapping
  backend = "claude",            -- or a function, see below
  timeout_ms = 60000,
  model = "haiku",               -- passed to the backend, e.g. --model
  effort = "low",                -- passed to the backend, e.g. --effort
  context = {
    modes = { "n", "x", "o", "i" },
    max_mappings = 500,
  },
  prompt = {
    extra = nil,                 -- e.g. "I use AstroNvim."
  },
  window = {
    border = "rounded",
    min_width = 40,
    max_width = 0.7,             -- fraction of editor columns
    max_height = 0.6,            -- fraction of editor lines
  },
})
```

The built-in `"claude"` backend always runs with `--safe-mode --tools ""
--no-session-persistence`, so `:Kotsu` never loads your CLAUDE.md, hooks,
skills, MCP servers or plugins, and never writes a session to disk. That's
independent of `model`/`effort` above, and not configurable.

### Custom backend

```lua
backend = function(prompt, opts, on_done)
  -- opts.timeout_ms, opts.model, opts.effort are the configured values
  -- (model/effort may be nil). Call on_done(true, answer) or
  -- on_done(false, "error message").
end
```

## License

MIT
