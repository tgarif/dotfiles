return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  build = ":Copilot auth",
  event = "BufReadPost",
  opts = {
    suggestion = {
      enabled = true,
      auto_trigger = true,
      accept = false,
    },
    panel = { enabled = true, auto_refresh = true },
    filetypes = {
      markdown = true,
      help = true,
    },
  },
}
