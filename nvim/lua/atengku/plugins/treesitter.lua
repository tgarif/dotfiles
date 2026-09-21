-- nvim-treesitter `main` branch: it only installs parsers/queries.
-- Highlighting, indent and incremental selection are started by us (below) / built into Neovim 0.12.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- main branch does not support lazy-loading
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
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
      "go",
      "python",
      -- godot
      "gdscript",
      "godot_resource",
      "gdshader",
    })

    vim.treesitter.language.register("bash", "zsh")

    -- start highlighting + indent for any filetype that has an installed parser
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not (lang and vim.treesitter.language.add(lang)) then
          return
        end
        vim.treesitter.start(ev.buf, lang)
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    -- incremental selection, using Neovim 0.12's built-in `an` (outwards) / `in` (inwards)
    vim.keymap.set("n", "<C-space>", "van", { remap = true, desc = "Start treesitter selection" })
    vim.keymap.set("x", "<C-space>", "an", { remap = true, desc = "Expand treesitter selection" })
    vim.keymap.set("x", "<bs>", "in", { remap = true, desc = "Shrink treesitter selection" })
  end,
}
