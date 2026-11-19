---@mod rhai.config Configuration for rhai.nvim

---@class rhai.LspOpts
---@field enabled boolean Start the Rhai language server for `rhai` buffers.
---@field cmd string[] Command used to start the server.
---@field root_markers string[] Files that mark the project root.
---@field settings table<string, any> Settings sent to the server.

---@class rhai.Config
---@field lsp rhai.LspOpts
---@field format_on_save boolean Format `rhai` buffers with the LSP before writing.
---@field treesitter boolean Use tree-sitter highlighting when the parser is installed.

---@class rhai.UserLspOpts
---@field enabled? boolean
---@field cmd? string[]
---@field root_markers? string[]
---@field settings? table<string, any>

--- Options accepted by `require("rhai").setup()`. Every field is optional.
---@class rhai.UserConfig
---@field lsp? rhai.UserLspOpts
---@field format_on_save? boolean
---@field treesitter? boolean

local M = {}

---@type rhai.Config
M.defaults = {
  lsp = {
    enabled = true,
    cmd = { "rhai", "lsp", "stdio" },
    root_markers = { "Rhai.toml", ".git" },
    settings = {},
  },
  format_on_save = false,
  treesitter = true,
}

---@type rhai.Config
local current = vim.deepcopy(M.defaults)

---@param value any
---@return boolean
local function is_string_list(value)
  if type(value) ~= "table" or not vim.islist(value) then
    return false
  end
  for _, item in ipairs(value) do
    if type(item) ~= "string" then
      return false
    end
  end
  return true
end

---@param cfg rhai.Config
local function validate(cfg)
  vim.validate("format_on_save", cfg.format_on_save, "boolean")
  vim.validate("treesitter", cfg.treesitter, "boolean")
  vim.validate("lsp", cfg.lsp, "table")
  vim.validate("lsp.enabled", cfg.lsp.enabled, "boolean")
  vim.validate("lsp.cmd", cfg.lsp.cmd, function(v)
    return is_string_list(v) and #v > 0
  end, "non-empty list of strings")
  vim.validate("lsp.root_markers", cfg.lsp.root_markers, is_string_list, "list of strings")
  vim.validate("lsp.settings", cfg.lsp.settings, "table")
end

--- Merge user options over the defaults, validate them and store the result.
---@param opts? rhai.UserConfig
---@return rhai.Config
function M.set(opts)
  vim.validate("opts", opts, "table", true)
  ---@type rhai.Config
  local merged = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  validate(merged)
  current = merged
  return current
end

--- The active configuration.
---@return rhai.Config
function M.get()
  return current
end

return M
