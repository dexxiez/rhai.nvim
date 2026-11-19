---@mod rhai.install Install the Rhai language server with cargo

local M = {}

M.repo = "https://github.com/rhaiscript/lsp"
--- Pinned server revision (the latest upstream commit, known to build on current Rust).
M.revision = "2f1fcd73f43b909d1d5e96123516e599b9aaaa88"

---@type vim.SystemObj?
local running = nil

--- The cargo command that installs the server.
---@param force boolean Reinstall even if already installed.
---@return string[]
function M.command(force)
  local cmd = { "cargo", "install", "--git", M.repo, "--rev", M.revision, "--locked" }
  if force then
    table.insert(cmd, "--force")
  end
  table.insert(cmd, "rhai-cli")
  return cmd
end

---@param msg string
---@param level? integer
local function notify(msg, level)
  vim.schedule(function()
    vim.notify("rhai.nvim: " .. msg, level or vim.log.levels.INFO)
  end)
end

--- Last few non-empty lines of `text`, for error messages.
---@param text string
---@param n integer
---@return string
local function tail(text, n)
  local lines = vim.tbl_filter(function(l)
    return l ~= ""
  end, vim.split(text, "\n", { plain = true }))
  return table.concat(vim.list_slice(lines, math.max(1, #lines - n + 1)), "\n")
end

--- Install (or with `force`, reinstall) the `rhai` language server.
--- Runs in the background and reports progress with `vim.notify`.
---@param force? boolean
function M.install(force)
  if running then
    notify("an install is already running", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("cargo") ~= 1 then
    notify("`cargo` not found. Install Rust from https://rustup.rs, then try again.", vim.log.levels.ERROR)
    return
  end

  local cmd = M.command(force == true)
  notify("installing the Rhai language server (this takes a few minutes)...\n" .. table.concat(cmd, " "))

  running = vim.system(cmd, { text = true }, function(result)
    running = nil
    if result.code == 0 then
      notify("language server installed. Reopen your .rhai files (:edit) to start it.")
    else
      notify(
        ("install failed (exit %d):\n%s"):format(result.code, tail(result.stderr or "", 15)),
        vim.log.levels.ERROR
      )
    end
  end)
end

return M
