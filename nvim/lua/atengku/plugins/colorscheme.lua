return {
  -- {
  --   "navarasu/onedark.nvim",
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     local onedark = require("onedark")
  --
  --     onedark.setup({
  --       style = "darker",
  --     })
  --
  --     -- load the colorscheme here
  --     vim.cmd([[colorscheme onedark]])
  --   end,
  -- },
  -- {
  --   "folke/tokyonight.nvim",
  --   priority = 1000, -- make sure to load this before all the other start plugins
  --   config = function()
  --     local tokyonight = require("tokyonight")
  --
  --     tokyonight.setup({
  --       style = "moon",
  --     })
  --
  --     -- load the colorscheme here
  --     vim.cmd([[colorscheme tokyonight]])
  --   end,
  -- },
  {
    "catppuccin/nvim",
    priority = 1000,
    config = function()
      local catppuccin = require("catppuccin")

      -- catppuccin.setup({
      --   color_overrides = {
      --     mocha = {
      --       base = "#000000",
      --       mantle = "#000000",
      --       crust = "#000000",
      --     },
      --   },
      -- })

      -- load the colorscheme here
      vim.cmd([[colorscheme catppuccin]])
    end,
  },
}
