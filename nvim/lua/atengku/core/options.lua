vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt -- for conciseness

-- line numbers
opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

opt.smartindent = true

-- Minimal number of screen lines to keep above and below the cursor.
opt.scrolloff = 8

-- line wrapping
opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true

-- cursor line
opt.cursorline = true

-- appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- backspace
opt.backspace = "indent,eol,start"

-- clipboard
opt.clipboard:append("unnamedplus")

-- split windows
opt.splitright = true
opt.splitbelow = true

opt.swapfile = false
opt.updatetime = 50

-- Lua-specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    local opt_local = vim.opt_local -- scoped to the current buffer
    opt_local.tabstop = 2
    opt_local.shiftwidth = 2
    opt_local.softtabstop = 2
    opt_local.expandtab = true
  end,
})
