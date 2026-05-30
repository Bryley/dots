return {
    {
        -- Parser for many languages that provides better highlighting
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            "nvim-treesitter/nvim-treesitter-textobjects",
            -- -- NOTE: additional parser
            -- { "nushell/tree-sitter-nu", build = ":TSUpdate nu" },
        },
        build = ":TSUpdate",
        lazy = false,
        config = function()
            -- Setup treesitter to setup folds
            vim.opt.foldmethod = "expr"
            vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.opt.foldlevelstart = 99
            vim.opt.foldnestmax = 1

            vim.opt.foldtext = 'getline(v:foldstart) . " … " . (v:foldend - v:foldstart + 1) . " lines"'

            ---@diagnostic disable: missing-fields
            require("nvim-treesitter.configs").setup({
                ensure_installed = "all",
                ignore_install = { "smali", "ipkg" },
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = true,
                },
                indent = {
                    enable = true,
                },
                textobjects = {
                    select = {
                        enable = true,
                        keymaps = {
                            ["ia"] = "@parameter.inner",
                            ["aa"] = "@parameter.outer",
                            ["if"] = "@function.inner",
                            ["af"] = "@function.outer",
                        },
                    },
                },
            })
        end,
    },
    {
        -- Treesitter for surrealdb SQL
        "dariuscorvus/tree-sitter-surrealdb.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        build = ":TSUpdate surrealdb",
        config = function()
            -- setup step
            require("tree-sitter-surrealdb").setup()
        end,
    },
}
