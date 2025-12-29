return {
  filetypes = {
    "html",
    "css",
    "scss",
    "sass",
    "less",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact", -- Add this
    "vue",
    "svelte",
  },
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
          { "cx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)" },
        },
      },
    },
  },
}
