local set = vim.opt_local

-- Makefiles REQUIRE tabs for indentation
set.tabstop = 4
set.shiftwidth = 4
set.softtabstop = 0
set.expandtab = false -- This is the key: use actual tabs, not spaces
