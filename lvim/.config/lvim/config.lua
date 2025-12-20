-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Example configs: https://github.com/LunarVim/starter.lvim
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny
vim.opt.number = true
vim.opt.relativenumber = true

-- Change directory to the first argument if it's a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local arg0 = vim.fn.argv(0)
    if arg0 == "" then return end

    local p = vim.fn.fnamemodify(arg0, ":p")
    if vim.fn.isdirectory(p) == 1 then
      vim.cmd("cd " .. vim.fn.fnameescape(p))
    end
  end
})