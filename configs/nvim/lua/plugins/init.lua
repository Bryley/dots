-- Dependencies --

vim.pack.add({
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/b0o/schemastore.nvim", -- Includes JSON & YAML schemas
})

-- dbab Database --

vim.pack.add({ "https://github.com/zerochae/dbab.nvim" })
require("dbab").setup({
    connections = {
        {
            name = "UAT",
            url = "$MYSQL_UAT_URL"
        },
        -- {
        --     name = "PROD",
        --     url = "$MYSQL_PROD_URL"
        -- },
    },
    result = {
        style = "table",
        max_width = 10,
        max_height = 20,
        header_align = "fit",
    }
})

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
        default = { 'lsp', 'path', 'buffer', 'dbab' },
        providers = {
            dbab = {
                name = "dbab",
                module = "blink_dbab",
            },
        },
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

-- Built-in DiffTool --

vim.cmd.packadd("nvim.difftool")

-- vim.keymap.set("n", "<leader>dt", function()
--     local left = vim.fn.input("Diff left: ", "", "file")
--     if left == "" then
--         return
--     end
--
--     local right = vim.fn.input("Diff right: ", "", "file")
--     if right == "" then
--         return
--     end
--
--     require("difftool").open(left, right, {
--         ignore = { ".git" },
--         rename = { detect = true },
--     })
-- end, { desc = "DiffTool compare files/directories" })

-- Yazi.nvim --

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
    callback = function(args)
        -- Syntax highlighting, provided by Neovim's built-in Treesitter support.
        local has_parser = pcall(vim.treesitter.start)

        if has_parser and vim.bo[args.buf].filetype ~= "lua" then
            -- Experimental Treesitter indentation, provided by nvim-treesitter.
            -- Keep Lua on Neovim's built-in GetLuaIndent(), which currently
            -- indents more reliably than nvim-treesitter's Lua indent query.
            pcall(function()
                vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end)
        end
    end,
})

-- Markdown Preview --

vim.pack.add({ 'https://github.com/MeanderingProgrammer/render-markdown.nvim' })
require('render-markdown').setup({})

-- Snacks (Picker, Scroll) --

vim.pack.add({ "https://github.com/folke/snacks.nvim" })
require("snacks").setup({
    scroll = {
        enable = true,
    },
    input = {
        enabled = true,
        win = {
            relative = "cursor",
            row = -3,
            col = 0,
        },
    },
    picker = {
        enabled = true,
        ui_select = true,
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
        win = {
            input = {
                keys = {
                    ["<C-x>"] = { "edit_split", mode = { "i", "n" } },
                    ["<C-v>"] = { "edit_vsplit", mode = { "i", "n" } },
                    ["<C-q>"] = { "qflist", mode = { "i", "n" } },
                },
            },
            list = {
                keys = {
                    ["<C-x>"] = "edit_split",
                    ["<C-v>"] = "edit_vsplit",
                    ["<C-q>"] = "qflist",
                },
            },
        }
    },
})

-- Refresh Snacks scroll state after writes. Without this, the first scroll after
-- :write can be treated as a state reset and jump instead of animating.
vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("snacks_scroll_after_write", { clear = true }),
    callback = vim.schedule_wrap(function()
        if Snacks and Snacks.scroll then
            Snacks.scroll.disable()
            Snacks.scroll.enable()
        end
    end),
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
    require("persistence").load()
end, { desc = "Restore current directory session" })


-- Auto pairs --

vim.pack.add({
    "https://github.com/windwp/nvim-autopairs",
})

require("nvim-autopairs").setup()

-- Surround --

vim.pack.add({ "https://github.com/kylechui/nvim-surround" })
require("nvim-surround").setup()


-- Color Previews --

vim.pack.add({ "https://github.com/brenoprata10/nvim-highlight-colors" })
require("nvim-highlight-colors").setup({
    render = "virtual",
    virtual_symbol = "■",
    kirtual_symbol_position = "inline",
    enable_tailwind = true,
})

-- Navbuddy --

vim.pack.add({
    "https://github.com/hasansujon786/nvim-navbuddy",
    "https://github.com/SmiteshP/nvim-navic",
})
require("nvim-navbuddy").setup({
    lsp = {
        auto_attach = true,
    }
})

vim.keymap.set("n", "<leader>ln", function()
    require("nvim-navbuddy").open()
end, { desc = "Open navbuddy" })


-- Git Stuff --

vim.pack.add({ "https://github.com/lewis6991/gitsigns.nvim" })
require("gitsigns").setup({})

vim.keymap.set("n", "<leader>gb", "<cmd>Gitsigns blame_line<CR>", { desc = "Git blame" })

-- Crates (Rust) --

vim.pack.add({ "https://github.com/saecki/crates.nvim" })
require("crates").setup({})
