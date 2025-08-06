return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    cmd = "CopilotChat",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = function()
      local user = vim.env.USER or "User"
      user = user:sub(1, 1):upper() .. user:sub(2)
      return {
        model = "gpt-4o",
        auto_insert_mode = true,
        question_header = "  " .. user .. " ",
        answer_header = "  Copilot ",
        window = {
          width = 0.4,
        },
      }
    end,
    keys = {
      { "<leader>zc", ":CopilotChat<CR>", mode = "n", desc = "Chat with Copilot" },
      { "<leader>ze", ":CopilotChatExplain<CR>", mode = "v", desc = "Explain Code" },
      { "<leader>zr", ":CopilotChatReview<CR>", mode = "v", desc = "Review Code" },
      { "<leader>zf", ":CopilotChatFix<CR>", mode = "v", desc = "Fix Code Issues" },
      { "<leader>zo", ":CopilotChatOptimize<CR>", mode = "v", desc = "Optimize Code" },
      { "<leader>zd", ":CopilotChatDocs<CR>", mode = "v", desc = "Generate Docs" },
      { "<leader>zt", ":CopilotChatTests<CR>", mode = "v", desc = "Generate Tests" },
      { "<leader>zm", ":CopilotChatCommit<CR>", mode = "n", desc = "Generate Commit Message" },
      { "<leader>zs", ":CopilotChatCommit<CR>", mode = "v", desc = "Generate Commit for Selection" },
    },
    config = function(_, opts)
      local chat = require("CopilotChat")

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-chat",
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
        end,
      })

      chat.setup(opts)
    end,
  },
}
