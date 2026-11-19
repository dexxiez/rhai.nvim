# rhai.nvim

[Rhai](https://rhai.rs) language support for Neovim.

- **LSP:** diagnostics, hover, go-to-definition, references, rename, completion, symbols, semantic highlighting
- **Formatting:** via the language server, with optional format-on-save
- **Tree-sitter (optional):** highlighting, folds, indents
- **`:checkhealth rhai`** to see what's working

Requires **Neovim 0.11+**. No nvim-lspconfig needed.

## Install

### 1. Add the plugin

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "dexxiez/rhai.nvim",
  ft = "rhai",
  opts = {},
}
```

### 2. Install the language server

Run this inside Neovim (needs [Rust/cargo](https://rustup.rs)):

```vim
:RhaiInstall
```

It runs `cargo install` in the background (takes a few minutes) and puts `rhai` in `~/.cargo/bin`. Make sure that folder is on your `PATH`.

<details>
<summary>Install it manually instead</summary>

```bash
cargo install --git https://github.com/rhaiscript/lsp --locked rhai-cli
```

</details>

### 3. (Optional) Tree-sitter highlighting

With [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) installed, run:

```vim
:TSInstall rhai
```

rhai.nvim registers the [tree-sitter-rhai](https://github.com/elkowar/tree-sitter-rhai) grammar for you (works with both the `main` and `master` branches). Without it, you still get highlighting from the language server.

## Configuration

These are the defaults. Pass only what you want to change.

```lua
require("rhai").setup({
  -- Format .rhai files with the language server when saving.
  format_on_save = false,

  -- Use tree-sitter highlighting when the `rhai` parser is installed.
  treesitter = true,

  lsp = {
    enabled = true,
    cmd = { "rhai", "lsp", "stdio" },       -- use a full path if `rhai` isn't on PATH
    root_markers = { "Rhai.toml", ".git" },
    settings = {},
  },
})
```

All options are type-annotated (`rhai.UserConfig`), so lua-language-server gives you completion and type checks for them.

### Formatting

- Format any time with `:lua vim.lsp.buf.format()`. The server formats whole files only, so `gq` on a selection doesn't use it.
- The formatter uses the buffer's indent settings. For 4-space indents, add this to `after/ftplugin/rhai.lua`:

  ```lua
  vim.bo.expandtab = true
  vim.bo.shiftwidth = 4
  ```

### Project config

The language server reads `Rhai.toml` at your project root (e.g. to choose which files belong to the project). Create one with `rhai config init`.

### Without `setup()`

The plugin ships an `lsp/rhai.lua` config, so this works too:

```lua
vim.lsp.enable("rhai")
```

## Commands

| Command          | What it does                                |
| ---------------- | ------------------------------------------- |
| `:RhaiInstall`   | Install the language server with cargo      |
| `:RhaiInstall!`  | Reinstall it                                |
| `:checkhealth rhai` | Check Neovim, the server, and tree-sitter |

## Troubleshooting

Run `:checkhealth rhai` first. Common fixes:

- **"`rhai` not found"**: run `:RhaiInstall`, or add `~/.cargo/bin` to your `PATH`, or set `lsp.cmd = { "/full/path/to/rhai", "lsp", "stdio" }`.
- **No highlighting**: install the parser (`:TSInstall rhai`) or check the server is running (`:checkhealth rhai`).
- **Server logs**: `:lua vim.cmd.edit(vim.lsp.log.get_filename())`

> The upstream [Rhai language server](https://github.com/rhaiscript/lsp) is marked experimental, and some features may be rough.

## Development

```bash
make deps   # build the language server + parser into .deps/
```

```bash
make all    # stylua check, lua-language-server type check, tests
```

Tests run headless with `nvim -l tests/run.lua`. Tests that need the server or parser are skipped if those aren't available.

## Credits

- [rhaiscript/lsp](https://github.com/rhaiscript/lsp): the Rhai language server and formatter
- [elkowar/tree-sitter-rhai](https://github.com/elkowar/tree-sitter-rhai) (MIT): the grammar. `queries/rhai/` is adapted from its queries.
