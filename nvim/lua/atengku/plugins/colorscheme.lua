return {
  {
    "catppuccin/nvim",
    priority = 1000,
    config = function()
      local catppuccin = require("catppuccin")

      -- load the colorscheme here
      vim.cmd([[colorscheme catppuccin]])
    end,
  },
}
