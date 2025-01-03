return {
  "stevearc/oil.nvim",
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    keymaps = {
      ["<Tab>"] = "actions.select",
    },
    view_options = {
      show_hidden = true,
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)

    -- Automatically change the working directory when opening a directory in oil.nvim
    vim.api.nvim_create_autocmd("BufEnter", {
      callback = function()
        local oil = require("oil")
        if vim.bo.filetype == "oil" then -- Check if the current buffer is an oil.nvim buffer
          local dir = oil.get_current_dir()
          if dir and #dir > 0 then
            vim.cmd("cd " .. vim.fn.fnameescape(dir))
          end
        end
      end,
    })
  end,
}
