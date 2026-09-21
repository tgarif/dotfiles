return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    input = { enabled = true }, -- vim.ui.input (e.g. LSP rename prompt)
    picker = { enabled = true, ui_select = true }, -- vim.ui.select (e.g. code actions); telescope stays the main finder
  },
}
