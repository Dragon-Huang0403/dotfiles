-- Configure Snacks.picker (LazyVim default) to show hidden files
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
          },
        },
      },
    },
  },
}
