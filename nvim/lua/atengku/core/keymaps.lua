vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness
local api = vim.api -- for conciseness

-- general keymaps

-- keymap.set("i", "jk", "<ESC>")

keymap.set("n", "<leader>nh", ":nohl<CR>")

keymap.set("n", "<leader>v", "<C-v>") -- remap for wsl specific ctrl + v to paste

-- This is only valid for using conform
-- keymap.set("n", "<S-f>e", ":FormatEnable<CR>")
-- keymap.set("n", "<S-f>d", ":FormatDisable<CR>")

-- This is to save without formatting
keymap.set("n", "<S-f>d", ":noa w<CR>")

keymap.set("n", "<leader>mk", ":MarkdownPreviewToggle<CR>") -- toggle markdown

-- keymap.set("n", "x", '"_x')

keymap.set("n", "<leader>+", "<C-a>")
keymap.set("n", "<leader>-", "<C-x>")

keymap.set("n", "<leader>sv", "<C-w>v") -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- make split windows equal width
keymap.set("n", "<leader>sx", ":close<CR>") -- close current split window

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

keymap.set("n", "-", "<CMD>Oil<CR>")
