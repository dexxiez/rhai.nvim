---@mod rhai.treesitter Optional tree-sitter support

local M = {}

M.url = "https://github.com/elkowar/tree-sitter-rhai"
--- Pinned grammar revision. The queries in `queries/rhai/` are written for it.
M.revision = "4ac7384d487ffcb54e746ef1569585a749370c5b"

---@type boolean
local registered = false

--- Register the parser with nvim-treesitter's `master` branch (old API).
---@param parsers table
local function register_master(parsers)
  local configs = parsers.get_parser_configs()
  configs.rhai = {
    install_info = {
      url = M.url,
      files = { "src/parser.c" },
      branch = "main",
      revision = M.revision,
    },
    filetype = "rhai",
  }
end

--- Register the parser with nvim-treesitter's `main` branch (new API).
--- The parsers table is rebuilt on `:TSUpdate`, so this re-runs on `User TSUpdate`.
local function register_main()
  local function add()
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    if ok and type(parsers) == "table" then
      parsers.rhai = {
        install_info = {
          url = M.url,
          revision = M.revision,
        },
      }
    end
  end
  add()
  vim.api.nvim_create_autocmd("User", {
    pattern = "TSUpdate",
    group = vim.api.nvim_create_augroup("rhai.treesitter", { clear = true }),
    desc = "rhai.nvim: register the rhai tree-sitter parser",
    callback = add,
  })
end

--- Tell nvim-treesitter (if installed) where to find the Rhai grammar,
--- so `:TSInstall rhai` works. Does nothing without nvim-treesitter.
function M.register()
  if registered then
    return
  end
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return
  end
  registered = true
  if type(parsers.get_parser_configs) == "function" then
    register_master(parsers)
  else
    register_main()
  end
end

--- Whether a compiled `rhai` parser can be loaded.
---@return boolean
function M.has_parser()
  local ok, loaded = pcall(vim.treesitter.language.add, "rhai")
  return ok and loaded == true
end

--- Start tree-sitter highlighting for a buffer if the parser is installed.
---@param bufnr integer
---@return boolean started
function M.start(bufnr)
  if not M.has_parser() then
    return false
  end
  local ok = pcall(vim.treesitter.start, bufnr, "rhai")
  if not ok then
    return false
  end
  -- nvim-treesitter's `main` branch provides an indentexpr that uses our indents.scm.
  local has_nvt, nvt = pcall(require, "nvim-treesitter")
  if has_nvt and type(nvt.indentexpr) == "function" then
    vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
  return true
end

return M
