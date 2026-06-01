
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

