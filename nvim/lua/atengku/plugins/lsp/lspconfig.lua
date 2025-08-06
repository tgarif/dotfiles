return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")
    local util = require("lspconfig.util")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

        if ev.name == "rust_analyzer" then
          if ev.server_capabilities.documentFormattingProvider then
            vim.api.nvim_command([[augroup Format]])
            vim.api.nvim_command([[autocmd! * <buffer>]])
            vim.api.nvim_command([[autocmd BufWritePre <buffer> lua vim.lsp.buf.format({ async = false })]])
            vim.api.nvim_command([[augroup END]])
          end
        end
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    vim.diagnostic.config({
      virtual_text = true, -- Show diagnostics as inline text
      underline = true, -- Underline text with errors
      update_in_insert = false, -- Don't update diagnostics in insert mode
      severity_sort = true, -- Sort diagnostics by severity
      signs = {
        text = {
          [vim.diagnostic.severity.ERROR] = signs.Error,
          [vim.diagnostic.severity.WARN] = signs.Warn,
          [vim.diagnostic.severity.HINT] = signs.Hint,
          [vim.diagnostic.severity.INFO] = signs.Info,
        },
      },
    })

    -- Setup LSP servers individually
    -- TypeScript/JavaScript
    lspconfig["ts_ls"].setup({
      capabilities = capabilities,
    })

    -- Svelte
    lspconfig["svelte"].setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.js", "*.ts" },
          callback = function(ctx)
            -- Here use ctx.file for the file URI
            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.file })
          end,
        })
      end,
    })

    -- GraphQL
    lspconfig["graphql"].setup({
      capabilities = capabilities,
      filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
    })

    -- Emmet
    lspconfig["emmet_ls"].setup({
      capabilities = capabilities,
      filetypes = {
        "html",
        "htmlangular",
        "typescriptreact",
        "javascriptreact",
        "css",
        "sass",
        "scss",
        "less",
        "svelte",
      },
    })

    -- Lua
    lspconfig["lua_ls"].setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          -- make the language server recognize "vim" global
          diagnostics = {
            globals = { "vim" },
          },
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    })

    -- C/C++
    lspconfig["clangd"].setup({
      capabilities = capabilities,
      filetypes = { "c", "cpp" },
    })

    -- Go
    lspconfig["gopls"].setup({
      capabilities = capabilities,
      cmd = { "gopls" },
      filetypes = { "go", "gomod", "gowork", "gotmpl" },
      root_dir = util.root_pattern("go.work", "go.mod", ".git"),
      settings = {
        gopls = {
          completeUnimported = true,
          usePlaceholders = true,
          analyses = {
            unusedparams = true,
          },
        },
      },
    })

    -- Go linter
    lspconfig["golangci_lint_ls"].setup({
      capabilities = capabilities,
      filetypes = { "go" },
    })

    -- Docker
    lspconfig["dockerls"].setup({
      capabilities = capabilities,
      filetypes = { "Dockerfile", "dockerfile" },
      root_dir = util.root_pattern("Dockerfile"),
    })

    -- Docker Compose
    lspconfig["docker_compose_language_service"].setup({
      capabilities = capabilities,
      filetypes = { "yaml" },
      root_dir = util.root_pattern("docker-compose.yml"),
    })

    -- ESLint
    lspconfig["eslint"].setup({
      capabilities = capabilities,
      filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "vue",
        "svelte",
        "astro",
        "html",
        "htmlangular",
      },
      root_dir = util.root_pattern(
        "eslint.config.js",
        "eslint.config.mjs",
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.fix.json",
        ".eslintrc.json",
        ".eslintrc.cjs",
        "package.json"
      ),
      settings = {
        eslint = {
          workingDirectories = { mode = "auto" },
          experimental = {
            useFlatConfig = true,
          },
          validate = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "vue",
            "svelte",
            "astro",
            "html",
            "htmlangular",
          },
        },
      },
    })

    -- HTML
    lspconfig["html"].setup({
      capabilities = capabilities,
      filetypes = { "html", "htmlangular" },
      init_options = {
        configurationSection = { "html", "css", "javascript" },
        embeddedLanguages = {
          css = true,
          javascript = true,
        },
        provideFormatter = true,
      },
    })

    -- CSS
    lspconfig["cssls"].setup({
      capabilities = capabilities,
    })

    -- Tailwind CSS
    lspconfig["tailwindcss"].setup({
      capabilities = capabilities,
    })

    -- Prisma
    lspconfig["prismals"].setup({
      capabilities = capabilities,
    })

    -- Rust
    lspconfig["rust_analyzer"].setup({
      capabilities = capabilities,
    })
  end,
}
