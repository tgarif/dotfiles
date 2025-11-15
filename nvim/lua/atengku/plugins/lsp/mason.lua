return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "mfussenegger/nvim-lint",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      -- list of servers for mason to install
      ensure_installed = {
        "ts_ls",
        "clangd",
        "html",
        "cssls",
        "tailwindcss",
        "svelte",
        "lua_ls",
        "graphql",
        "emmet_ls",
        "prismals",
        "rust_analyzer",
        "gopls",
        "docker_compose_language_service",
        "dockerls",
        "eslint",
        "pylsp",
      },
      -- auto-install configured servers (with lspconfig)
      automatic_installation = true,
      automatic_enable = false, -- disable automatic setup
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "prettier", -- prettier formatter
        -- "eslint_d", -- eslint_d linter
        "stylua", -- lua formatter
        "gofumpt",
        "goimports",
        "golines",
        "gopls",
        -- "golangci-lint",
        "golangci-lint-langserver",
        -- "clang-format",
        "black", -- python formatter
        "ruff", -- python linter
        "mypy", -- python type checker
      },
    })
  end,
}
