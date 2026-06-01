-- Set the leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "x" }, "<Space>", "<Nop>", { silent = true })

-- Enabled experimental new UI for better error message editing
require("vim._core.ui2").enable({})

vim.o.swapfile = false -- Stops the creation of swap files
vim.o.undofile = true -- Keeps undo history even on close
vim.o.updatetime = 200

vim.o.splitbelow = true
vim.o.splitright = true

vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.scrolloff = 3 -- Keep a margin of 3 lines when scrolling up and down
vim.o.sidescrolloff = 3 -- Same as above but horizontal

vim.o.cursorline = true
vim.o.colorcolumn = "80"

vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = "yes"

vim.o.confirm = true

vim.o.inccommand = "split"
vim.o.splitkeep = "screen"

-- Set tab to be 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = -1 -- Set to the same as `shiftwidth`
vim.o.expandtab = true
vim.o.autoindent = true

vim.o.pumheight = 15

vim.o.winborder = "rounded"

-- Show invisible characters
vim.o.list = true
vim.opt.listchars = {
    tab = "» ",
    trail = "·",
    nbsp = "␣",
}

-- Set tab to be 2 spaces for certain files
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "yaml",
        "yml",
        "nix",
        "html",
        "json",
        "jsonc",
    },
    callback = function()
        vim.opt_local.tabstop = 2 -- '\t' char = 2 spaces
        vim.opt_local.shiftwidth = 2 -- 1 level of indentation is 2 spaces
        vim.opt_local.softtabstop = -1 -- Tab is 2 spaces (same as `shiftwidth`) for inserting and deleting
    end,
})
