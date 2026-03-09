return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.config").setup({
      highlight = {
        enable = true,
      },
      indent = { enable = true },
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "angular",
        "css",
        "prisma",
        "markdown",
        "markdown_inline",
        "svelte",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "query",
        "rust",
        "vimdoc",
        "c",
        "glimmer",
        "php",
        "vue",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })

    vim.treesitter.language.register("bash", "zsh")
  end,
}
