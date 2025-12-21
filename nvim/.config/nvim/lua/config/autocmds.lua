-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Change directory to the first argument if it's a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg0 = vim.fn.argv(0)
    if arg0 == "" then return end

    local p = vim.fn.fnamemodify(arg0, ":p")
    if vim.fn.isdirectory(p) == 1 then
      vim.cmd("cd " .. vim.fn.fnameescape(p))
    end
  end,
})
