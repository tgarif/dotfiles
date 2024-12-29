return {
  "mfussenegger/nvim-lint",
  lazy = true,
  event = { "BufReadPre", "BufNewFile" }, -- to disable, comment this out
  config = function()
    local lint = require("lint")

    local eslint_d = lint.linters.eslint_d
    eslint_d.args = {
      "--no-warn-ignored",
      "--format",
      "json",
      "--stdin",
      "--stdin-filename",
      function()
        return vim.api.nvim_buf_get_name(0)
      end,
    }
    eslint_d.cwd = function()
      return vim.fn.getcwd() -- Use the current working directory
    end

    -- Custom definition for golangci-lint
    lint.linters.golangci_lint = {
      name = "golangci_lint", -- Required name field
      cmd = "golangci-lint",
      args = { "run", "--out-format", "json" },
      stdin = false,
      stream = "stdout",
      ignore_exitcode = true,
      parser = function(output)
        local diagnostics = {}
        local results = vim.fn.json_decode(output)
        if results and results.Issues then
          for _, issue in ipairs(results.Issues) do
            -- Check if 'line' and 'column' fields are present
            if issue.Line and issue.Column then
              table.insert(diagnostics, {
                lnum = issue.Line - 1, -- 0-based line number
                col = issue.Column - 1, -- 0-based column number
                source = issue.Link,
                message = issue.Text,
                severity = issue.Severity == "error" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
              })
            end
          end
        end
        return diagnostics
      end,
    }

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      svelte = { "eslint_d" },
      go = { "golangci_lint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
