return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>a", function()
      harpoon:list():add()
    end, { desc = "Harpoon: Mark File" })
    keymap.set("n", "<C-e>", function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = "Toggle Harpoon Menu" })

    keymap.set("n", "<leader>hn", function()
      harpoon:list():next()
    end, { desc = "Go to next harpoon mark" })
    keymap.set("n", "<leader>hP", function()
      harpoon:list():prev()
    end, { desc = "Go to previous harpoon mark" })
  end,
}
