return {
  "stevearc/oil.nvim",
  -- Optional dependencies
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    keymaps = {
      ["<Tab>"] = "actions.select",
      ["<C-h>"] = false,
      ["<C-l>"] = false,
    },
    view_options = {
      show_hidden = true,
    },
  },
}
