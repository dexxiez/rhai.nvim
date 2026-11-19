---@mod rhai.format Format-on-save using the Rhai language server

local config = require("rhai.config")

local M = {}

local group = vim.api.nvim_create_augroup("rhai.format", { clear = true })

---@param bufnr integer
---@param client vim.lsp.Client
local function attach(bufnr, client)
  vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    buffer = bufnr,
    desc = "rhai.nvim: format on save",
    callback = function()
      -- Read the option at write time so changes after setup() still apply.
      if not config.get().format_on_save then
        return
      end
      vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 2000 })
    end,
  })
end

--- Register the LspAttach handler. Safe to call more than once.
function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "rhai.nvim: set up format on save",
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client or client.name ~= "rhai" then
        return
      end
      if not client:supports_method("textDocument/formatting", args.buf) then
        return
      end
      attach(args.buf, client)
    end,
  })
end

return M
