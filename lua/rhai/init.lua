---@mod rhai rhai.nvim: Rhai language support for Neovim

local M = {}

--- Set up rhai.nvim.
---
--- ```lua
--- require("rhai").setup({
---   format_on_save = true,
--- })
--- ```
---@param opts? rhai.UserConfig
function M.setup(opts)
  local cfg = require("rhai.config").set(opts)

  require("rhai.lsp").setup(cfg.lsp)
  require("rhai.format").setup()

  if cfg.treesitter then
    require("rhai.treesitter").register()
  end
end

return M
