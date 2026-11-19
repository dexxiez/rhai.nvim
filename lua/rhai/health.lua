---@mod rhai.health :checkhealth rhai

local M = {}

local health = vim.health

function M.check()
  local config = require("rhai.config").get()

  health.start("rhai.nvim: Neovim")
  if vim.fn.has("nvim-0.11") == 1 then
    health.ok("Neovim " .. tostring(vim.version()))
  else
    health.error("Neovim 0.11+ is required, found " .. tostring(vim.version()))
  end

  health.start("rhai.nvim: language server")
  if not config.lsp.enabled then
    health.info("LSP is disabled (`lsp.enabled = false`)")
  else
    local exe = config.lsp.cmd[1]
    local path = vim.fn.exepath(exe)
    if path ~= "" then
      health.ok(("`%s` found at %s"):format(exe, path))
    else
      health.error(("`%s` not found on PATH"):format(exe), {
        "Run :RhaiInstall (needs cargo), or set `lsp.cmd` to the full path of the binary.",
        "cargo installs to ~/.cargo/bin; make sure that is on your PATH.",
      })
    end

    if vim.fn.executable("cargo") == 1 then
      health.ok("`cargo` found (needed only for :RhaiInstall)")
    else
      health.info("`cargo` not found; :RhaiInstall will not work. Get it from https://rustup.rs")
    end

    local clients = vim.lsp.get_clients({ name = "rhai" })
    if #clients > 0 then
      health.ok(("%d `rhai` LSP client(s) running"):format(#clients))
    else
      health.info("No `rhai` LSP client running (open a .rhai file to start one)")
    end
  end
  health.info("Format on save: " .. (config.format_on_save and "on" or "off"))

  health.start("rhai.nvim: tree-sitter (optional)")
  if not config.treesitter then
    health.info("tree-sitter is disabled (`treesitter = false`)")
  elseif require("rhai.treesitter").has_parser() then
    health.ok("`rhai` parser installed")
  elseif pcall(require, "nvim-treesitter") then
    health.warn("`rhai` parser not installed", { "Run :TSInstall rhai" })
  else
    health.info("No `rhai` parser. Highlighting comes from the LSP (semantic tokens) instead.")
  end
end

return M
