-- Set leader keys to space
vim.keymap.set("", "<Space>", "<Nop>", { noremap = true, silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.backup = false -- Disable create backup files
opt.swapfile = false -- Stops creating annoying swap files
opt.mouse = "a" -- Enables mouse
opt.writebackup = false -- Can't edit file when being edited by another software
-- opt.completeopt = "menu,menuone,noselect" -- Selection options for cmp plugin
opt.undofile = true -- Keeps undo history even on close
opt.timeoutlen = 1000 -- Time to wait for mapped sequence to complete
opt.updatetime = 200 -- Have nvim update quicker

opt.splitbelow = true -- Forces new splits to open below
opt.splitright = true -- Forces new splits to open right

opt.number = true -- Enables line numbers
opt.relativenumber = true -- Enables relative linenumbers
opt.wrap = false -- Disables text wrapping
opt.scrolloff = 3 -- Keep 3 lines above and below when scrolling
opt.sidescrolloff = 3 -- Same as `scrolloff` except horizontal

opt.lazyredraw = true -- Prevents nvim from redrawing when it doesn't need too
opt.termguicolors = true -- Color support
opt.showmode = true -- Shows current mode in bottom left-hand corner
opt.cursorline = true -- Highlight current line
opt.colorcolumn = "80" -- Have line indicate 80 chars

opt.hlsearch = true -- Highlight all matches on previous search pattern
opt.ignorecase = true -- Ignores case in search patterns
opt.smartcase = true -- Ignores case unless there is an uppercase char

opt.tabstop = 4 -- '\t' char = 4 spaces
opt.shiftwidth = 4 -- 1 level of indentation is 4 spaces
opt.softtabstop = 4 -- Tab is 4 spaces for inserting and deleting
opt.expandtab = true -- Tabs should always be spaces instead
opt.autoindent = true -- Automatically indent lines as you type
opt.winborder = "rounded" -- set the default border style for *all* floating windows


-- Set textwidth for markdown and norg files
-- vim.cmd([[autocmd FileType markdown,norg,txt setlocal textwidth=80]])

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "norg", "txt" },
    callback = function()
        vim.opt_local.textwidth = 80
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact", "yaml", "nix", "html", "json", "jsonc" },
    callback = function()
        vim.opt_local.tabstop = 2 -- '\t' char = 2 spaces
        vim.opt_local.shiftwidth = 2 -- 1 level of indentation is 2 spaces
        vim.opt_local.softtabstop = 2 -- Tab is 2 spaces for inserting and deleting
    end,
})

vim.api.nvim_create_user_command("LspDebug", function()
    for _, client in ipairs(vim.lsp.get_active_clients()) do
        print(vim.inspect(client.config))
    end
end, {})

-- Change the default theme to "habamax"
vim.cmd("colorscheme habamax")
