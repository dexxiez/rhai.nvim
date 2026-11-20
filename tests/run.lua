-- Headless test runner: `nvim -l tests/run.lua`
--
-- Optional environment variables:
--   RHAI_LSP_BIN     path to the `rhai` binary (default: `rhai` on PATH)
--   RHAI_PARSER_DIR  directory containing `parser/rhai.so` for tree-sitter tests

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
local parser_dir = os.getenv("RHAI_PARSER_DIR")
if parser_dir and parser_dir ~= "" then
  vim.opt.rtp:append(parser_dir)
end
vim.cmd("runtime! plugin/rhai.lua")
vim.cmd("runtime! ftdetect/*.lua")
vim.cmd("filetype plugin on")

local lsp_bin = os.getenv("RHAI_LSP_BIN")
if not lsp_bin or lsp_bin == "" then
  lsp_bin = "rhai"
end
local has_lsp = vim.fn.executable(lsp_bin) == 1

---@class rhai.test.Case
---@field name string
---@field fn fun()
---@field skip? string Reason to skip, if any.

---@type rhai.test.Case[]
local cases = {}

---@param name string
---@param fn fun()
---@param skip? string|false
local function test(name, fn, skip)
  table.insert(cases, { name = name, fn = fn, skip = skip or nil })
end

---@generic T
---@param actual T
---@param expected T
---@param msg? string
local function eq(actual, expected, msg)
  if not vim.deep_equal(actual, expected) then
    error(
      ("%sexpected %s, got %s"):format(
        msg and (msg .. ": ") or "",
        vim.inspect(expected),
        vim.inspect(actual)
      ),
      2
    )
  end
end

---@param cond any
---@param msg string
local function ok(cond, msg)
  if not cond then
    error(msg, 2)
  end
end

--- Fresh buffer state between tests.
local function reset()
  for _, client in ipairs(vim.lsp.get_clients()) do
    client:stop(true)
  end
  vim.wait(2000, function()
    return #vim.lsp.get_clients() == 0
  end)
  vim.cmd("silent! %bwipeout!")
end

---@param path string
---@return integer bufnr
local function open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

---@param bufnr integer
---@return vim.lsp.Client
local function wait_for_client(bufnr)
  local attached = vim.wait(15000, function()
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rhai" })
    return #clients > 0 and clients[1].initialized == true
  end, 50)
  ok(attached, "rhai LSP client did not attach")
  return vim.lsp.get_clients({ bufnr = bufnr, name = "rhai" })[1]
end

local fixture = root .. "/tests/fixtures/sample.rhai"
local lsp_skip = not has_lsp and ("`" .. lsp_bin .. "` not found") or false
local lsp_cmd = { lsp_bin, "lsp", "stdio" }

-- ── config ────────────────────────────────────────────────────────────────

test("config: defaults", function()
  local cfg = require("rhai.config").set()
  eq(cfg.format_on_save, false)
  eq(cfg.treesitter, true)
  eq(cfg.lsp.cmd, { "rhai", "lsp", "stdio" })
  eq(cfg.lsp.root_markers, { "Rhai.toml", ".git" })
end)

test("config: user options override defaults, lists are replaced", function()
  local cfg = require("rhai.config").set({ format_on_save = true, lsp = { cmd = { "/opt/rhai" } } })
  eq(cfg.format_on_save, true)
  eq(cfg.lsp.cmd, { "/opt/rhai" })
  eq(cfg.lsp.enabled, true)
end)

test("config: rejects bad types", function()
  local config = require("rhai.config")
  -- These options are deliberately the wrong type.
  ---@diagnostic disable-next-line: assign-type-mismatch
  ok(not pcall(config.set, { format_on_save = "yes" }), "string format_on_save accepted")
  ok(not pcall(config.set, { lsp = { cmd = {} } }), "empty cmd accepted")
  ---@diagnostic disable-next-line: assign-type-mismatch
  ok(not pcall(config.set, { lsp = { cmd = { 1 } } }), "non-string cmd accepted")
  config.set()
end)

-- ── filetype ──────────────────────────────────────────────────────────────

test("filetype: .rhai is detected", function()
  eq(vim.filetype.match({ filename = "script.rhai" }), "rhai")
end)

test("ftplugin: comment settings", function()
  reset()
  local bufnr = open(fixture)
  eq(vim.bo[bufnr].filetype, "rhai")
  eq(vim.bo[bufnr].commentstring, "// %s")
end)

-- ── setup ─────────────────────────────────────────────────────────────────

test("setup: works without nvim-treesitter", function()
  require("rhai").setup({ lsp = { cmd = lsp_cmd } })
end)

test("setup: :RhaiInstall command exists", function()
  ok(vim.api.nvim_get_commands({})["RhaiInstall"] ~= nil, ":RhaiInstall missing")
  local cmd = require("rhai.install").command(true)
  eq(cmd[1], "cargo")
  eq(cmd[#cmd], "rhai-cli")
  ok(vim.tbl_contains(cmd, "--force"), "--force missing with bang")
end)

-- ── LSP ───────────────────────────────────────────────────────────────────

test("lsp: client attaches to .rhai buffers", function()
  reset()
  require("rhai").setup({ lsp = { cmd = lsp_cmd } })
  local client = wait_for_client(open(fixture))
  ok(client:supports_method("textDocument/formatting"), "server lacks formatting")
  ok(client:supports_method("textDocument/hover"), "server lacks hover")
end, lsp_skip)

test("lsp: disabled with lsp.enabled = false", function()
  reset()
  require("rhai").setup({ lsp = { enabled = false, cmd = lsp_cmd } })
  local bufnr = open(fixture)
  vim.wait(1000)
  eq(#vim.lsp.get_clients({ bufnr = bufnr, name = "rhai" }), 0)
  require("rhai").setup({ lsp = { cmd = lsp_cmd } })
end, lsp_skip)

---@param format_on_save boolean
---@return string[] lines after :write
local function write_unformatted(format_on_save)
  reset()
  require("rhai").setup({ format_on_save = format_on_save, lsp = { cmd = lsp_cmd } })
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local path = dir .. "/messy.rhai"
  vim.fn.writefile({ "let   x=1;", "fn add(a,b){a+b}" }, path)
  local bufnr = open(path)
  -- The server formats using the buffer's indent settings.
  vim.bo[bufnr].expandtab = true
  vim.bo[bufnr].shiftwidth = 4
  wait_for_client(bufnr)
  vim.cmd("silent write")
  return vim.fn.readfile(path)
end

test("format: format_on_save formats on :write using buffer indent settings", function()
  eq(write_unformatted(true), { "let x = 1;", "fn add(a, b) {", "    a + b", "}" })
end, lsp_skip)

test("format: off by default", function()
  eq(write_unformatted(false), { "let   x=1;", "fn add(a,b){a+b}" })
end, lsp_skip)

-- ── tree-sitter ───────────────────────────────────────────────────────────

local ts_skip = not require("rhai.treesitter").has_parser() and "rhai parser not installed" or false

test("treesitter: queries are valid", function()
  for _, name in ipairs({ "highlights", "folds", "indents", "injections", "locals" }) do
    ok(vim.treesitter.query.get("rhai", name) ~= nil, name .. " query missing")
  end
end, ts_skip)

test("treesitter: fixture parses and highlighting starts", function()
  reset()
  require("rhai").setup({ lsp = { enabled = false } })
  local bufnr = open(fixture)
  local tree = vim.treesitter.get_parser(bufnr, "rhai"):parse()[1]
  ok(not tree:root():has_error(), "parse errors in fixture")
  ok(vim.treesitter.highlighter.active[bufnr] ~= nil, "highlighter not active")
end, ts_skip)

-- ── health ────────────────────────────────────────────────────────────────

---@class rhai.test.HealthCall
---@field kind "start"|"ok"|"info"|"warn"|"error"
---@field msg string

--- Run rhai's health check with `vim.health` reporters stubbed out.
--- (Calling `:checkhealth` is UI-dependent: nightly fills its buffer asynchronously.)
---@return rhai.test.HealthCall[]
local function run_health()
  ---@type rhai.test.HealthCall[]
  local calls = {}
  local kinds = { "start", "ok", "info", "warn", "error" }
  local saved = {}
  for _, kind in ipairs(kinds) do
    saved[kind] = vim.health[kind]
    vim.health[kind] = function(msg)
      table.insert(calls, { kind = kind, msg = msg })
    end
  end
  local success, err = pcall(require("rhai.health").check)
  for _, kind in ipairs(kinds) do
    vim.health[kind] = saved[kind]
  end
  if not success then
    error(err, 0)
  end
  return calls
end

test("health: check reports no errors", function()
  reset()
  require("rhai").setup({ lsp = { cmd = lsp_cmd } })
  local calls = run_health()
  local report = vim.inspect(calls)

  local function has(kind, pattern)
    for _, call in ipairs(calls) do
      if call.kind == kind and call.msg:find(pattern, 1, true) then
        return true
      end
    end
    return false
  end

  ok(has("start", "rhai.nvim: language server"), "language server section missing:\n" .. report)
  ok(has("ok", lsp_bin), "binary not reported as found:\n" .. report)
  ok(not vim.iter(calls):any(function(c)
    return c.kind == "error"
  end), "health reported errors:\n" .. report)
end, lsp_skip)

-- ── run ───────────────────────────────────────────────────────────────────

local failed, skipped = 0, 0
for _, case in ipairs(cases) do
  if case.skip then
    skipped = skipped + 1
    io.write(("SKIP  %s (%s)\n"):format(case.name, case.skip))
  else
    local success, err = pcall(case.fn)
    if success then
      io.write("PASS  " .. case.name .. "\n")
    else
      failed = failed + 1
      io.write("FAIL  " .. case.name .. "\n      " .. tostring(err):gsub("\n", "\n      ") .. "\n")
    end
  end
end
reset()
io.write(("\n%d passed, %d failed, %d skipped\n"):format(#cases - failed - skipped, failed, skipped))
os.exit(failed == 0 and 0 or 1)
