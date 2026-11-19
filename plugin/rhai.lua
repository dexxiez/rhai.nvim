if vim.g.loaded_rhai then
  return
end
vim.g.loaded_rhai = true

if vim.fn.has("nvim-0.11") ~= 1 then
  vim.notify("rhai.nvim requires Neovim 0.11 or newer", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("RhaiInstall", function(cmd)
  require("rhai.install").install(cmd.bang)
end, {
  bang = true,
  desc = "Install the Rhai language server with cargo (! to reinstall)",
})
