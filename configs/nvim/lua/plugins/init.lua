-- Blink Completions --

vim.pack.add({
    {
        src = "https://github.com/saghen/blink.cmp",
        version = "v1",
    },
})
require("blink.cmp").setup({
    keymap = { preset = 'enter' },
    sources = {
        default = { 'lsp', 'path', 'buffer' },
    },
    completion = {
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
        }
    },
})

-- Colorscheme --

vim.pack.add({ "https://github.com/olimorris/onedarkpro.nvim" })
vim.cmd("colorscheme onedark_dark") -- Default

-- Auto change on light/dark
vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "background",
    callback = function()
        if vim.o.background == "dark" then
            vim.cmd.colorscheme("onedark_dark")
        else
            vim.cmd.colorscheme("onelight")
        end
    end,
})

-- LSP --

require("plugins.lsp")

-- Yazi.nvim --

vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" })
vim.pack.add({ "https://github.com/mikavilpas/yazi.nvim" })

vim.keymap.set("n", "<leader>=", function()
    require("yazi").yazi(nil, vim.fn.getcwd())
end, { desc = "Open yazi in project dir" })

vim.keymap.set("n", "<leader>-", function()
    require("yazi").yazi()
end, { desc = "Open yazi" })


-- Treesitter --

vim.pack.add({
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        version = "main",
    },
})

require("nvim-treesitter").setup()

-- Treesitter parsers are installed separately. Run `:TSInstall all` once,
-- or install a smaller set like `:TSInstall lua vim vimdoc query`.
if #vim.api.nvim_get_runtime_file("parser/*.so", true) == 0 then
    vim.notify("No Treesitter parsers found. Run `:TSInstall all`.", vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd("FileType", {
    callback = function()
        -- Syntax highlighting, provided by Neovim's built-in Treesitter support.
        pcall(vim.treesitter.start)

        -- Experimental Treesitter indentation, provided by nvim-treesitter.
        pcall(function()
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end)
    end,
})


-- Scroll --
vim.pack.add({ "https://github.com/karb94/neoscroll.nvim" })
require("neoscroll").setup({})

-- Picker (Snacks) --

vim.pack.add({ "https://github.com/folke/snacks.nvim" })
require("snacks").setup({
    picker = {
        enabled = true,
        layout = "ivy",
        sources = {
            files = {
                exclude = { "vendor/**" },
            },
            grep = {
                exclude = { "vendor/**" },
            },
            diagnostics = {
                filter = {
                    cwd = true,
                    filter = function(item)
                        return not item.file:find("/vendor/", 1, true)
                    end,
                },
            },
        },
    },
})

vim.keymap.set("n", "<leader>ff", function()
    Snacks.picker.files()
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>fg", function()
    Snacks.picker.grep()
end, { desc = "Grep files" })

vim.keymap.set("n", "<leader>fd", function()
    Snacks.picker.diagnostics()
end, { desc = "Find diagnostics" })

-- Sessions --

vim.pack.add({ "https://github.com/folke/persistence.nvim" })
require("persistence").setup()

vim.keymap.set("n", "<F1>", function()
    require("persistence").load({ last = true })
end, { desc = "Restore last session" })


-- Auto pairs --

vim.pack.add({
    "https://github.com/windwp/nvim-autopairs",
})

require("nvim-autopairs").setup()
