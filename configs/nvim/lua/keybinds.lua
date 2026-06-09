vim.keymap.set("n", "<C-n>", function()
    vim.diagnostic.jump({
        count = 1,
        float = true,
    })
end, {
    desc = "Next diagnostic",
})

vim.keymap.set("n", "<C-p>", function()
    vim.diagnostic.jump({
        count = -1,
        float = true,
    })
end, {
    desc = "Previous diagnostic",
})

vim.keymap.set("n", "<leader>r", function()
    vim.cmd.restart({
        args = { [[lua require("persistence").load()]] },
    })
end, {
    desc = "Restart Neovim and restore current directory session"
})

local quickfix_toggle_cmd =
"<cmd>if empty(filter(getwininfo(), 'v:val.quickfix')) | botright copen | else | cclose | endif<CR>"

vim.keymap.set("n", "<leader>qk", "<cmd>cprev<CR>zz", { desc = "Prev Quickfix" })
vim.keymap.set("n", "<leader>qj", "<cmd>cnext<CR>zz", { desc = "Next Quickfix" })
vim.keymap.set("n", "<leader>qq", quickfix_toggle_cmd, { desc = "Toggle Quickfix" })


vim.keymap.set("n", "<F3>", "<cmd>noh<CR>", { desc = "No highlight" })

vim.keymap.set("n", "<leader>yf", function()
    local filepath = vim.fn.expand("%:.")
    vim.fn.setreg('"', filepath)
    vim.fn.setreg("+", filepath)
end, { desc = "Yank relative file path" })
