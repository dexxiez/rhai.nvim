-- Default config for the Rhai language server (https://github.com/rhaiscript/lsp).
-- Neovim 0.11+ finds this file automatically, so `vim.lsp.enable("rhai")` works
-- even without calling `require("rhai").setup()`.

---@type vim.lsp.Config
return {
  cmd = { "rhai", "lsp", "stdio" },
  filetypes = { "rhai" },
  root_markers = { "Rhai.toml", ".git" },
}
