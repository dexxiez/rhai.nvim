---@mod rhai.lsp Language server setup

local M = {}

local warned = false

--- Warn once (on the first `rhai` buffer) if the server binary is missing.
---@param cmd string
local function warn_if_missing(cmd)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "rhai",
    once = true,
    desc = "rhai.nvim: check that the language server is installed",
    callback = function()
      if warned or vim.fn.executable(cmd) == 1 then
        return
      end
      warned = true
      vim.notify(
        ("rhai.nvim: language server `%s` not found. Run :RhaiInstall to install it."):format(cmd),
        vim.log.levels.WARN
      )
    end,
  })
end

---@param opts rhai.LspOpts
function M.setup(opts)
  if not opts.enabled then
    vim.lsp.enable("rhai", false)
    return
  end
  vim.lsp.config("rhai", {
    cmd = opts.cmd,
    root_markers = opts.root_markers,
    settings = opts.settings,
  })
  vim.lsp.enable("rhai")
  warn_if_missing(opts.cmd[1])
end

return M
