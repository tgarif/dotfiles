local set = vim.opt_local

-- Godot's editor and gdformat indent GDScript with tabs; mixing in spaces is a parse error
set.tabstop = 4
set.shiftwidth = 4
set.softtabstop = 0
set.expandtab = false
