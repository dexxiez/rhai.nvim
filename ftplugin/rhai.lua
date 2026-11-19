if vim.b.did_ftplugin then
  return
end
vim.b.did_ftplugin = 1

local bufnr = vim.api.nvim_get_current_buf()

vim.bo[bufnr].commentstring = "// %s"
vim.bo[bufnr].comments = "s1:/*,mb:*,ex:*/,:///,://!,://"
vim.b[bufnr].undo_ftplugin = "setlocal commentstring< comments< indentexpr<"

if require("rhai.config").get().treesitter then
  require("rhai.treesitter").start(bufnr)
end
