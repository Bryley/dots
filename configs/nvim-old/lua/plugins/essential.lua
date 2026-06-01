return {
    {
        -- Onedark colorscheme
        "navarasu/onedark.nvim",
        config = function()
            require("onedark").setup({
                style = "darker",
                -- style='deep',
                transparent = false,
                toggle_style_key = "<leader>ts", -- nil to disable or set it to a string, for example "<leader>ts"
                toggle_style_list = { "deep", "light" },
            })

            require("onedark").load()
            -- config()
        end,
    },
    {
        "Shatur/neovim-session-manager",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        lazy = false,
        config = function()
            require("session_manager").setup({
                autoload_mode = require("session_manager.config").AutoloadMode.Disabled,
            })
        end,
    },

    -- {
    --     "declancm/cinnamon.nvim",
    --     opts = {
    --         -- change default options here
    --         keymaps = {
    --             basic = true,
    --             extra = false,
    --         },
    --     },
    -- },
    {
        -- Smooth scrolling for neovim
        "karb94/neoscroll.nvim",
        config = function()
            require("neoscroll").setup({})
        end,
    },
    {
        -- Ability to change surrounding characters on text objects.
        "kylechui/nvim-surround",
        config = true,
    },
    {
        -- Better commenting using the `gc<motion>` keybinding
        "numToStr/Comment.nvim",
        config = true,
        lazy = false,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        lazy = true,
        config = true,
    },
    {
        -- TODO maybe consider not using this
        -- Adds lots of base16 colorschemes
        "RRethy/nvim-base16",
    },
    {
        -- Toggles background transparency
        "xiyaowong/transparent.nvim",
    },
    {
        -- GUI for quickly selecting from a list of things
        "nvim-telescope/telescope.nvim",
        tag = "0.1.4",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    -- works for pickers that list files (find_files, git_files, etc.)
                    file_ignore_patterns = { [[(^|/)vendor(/|$)]], [[%.lock$]] }, -- Lua pattern
                    -- make ripgrep-based pickers (live_grep, grep_string) skip vendor too
                    vimgrep_arguments = (function()
                        local vga = {
                            "rg",
                            "--color=never",
                            "--no-heading",
                            "--with-filename",
                            "--line-number",
                            "--column",
                            "--smart-case",
                        }
                        -- exclude vendor anywhere in the path
                        vim.list_extend(vga, { "--glob", "!vendor/**", "--glob", "!**/*.lock" })
                        return vga
                    end)(),
                },
                pickers = {
                    colorscheme = {
                        enable_preview = true,
                    },
                    find_files = {
                        find_command = {
                            "fd",
                            "--type",
                            "f",
                            "--strip-cwd-prefix",
                            "--exclude",
                            "vendor",
                            "--exclude",
                            "*.lock",
                        },
                    },
                },
            })
        end,
    },
    {
        -- Adds :BufDel command for a more intuitive buffer delete (binded to Alt-C)
        "ojroques/nvim-bufdel",
        opts = {
            -- Custom next function to go to the last visited buffer
            next = function()
                local buf = vim.api.nvim_get_current_buf()
                local jumplist = vim.fn.getjumplist()[1]

                local size = #jumplist

                for index, _ in ipairs(jumplist) do
                    local element = jumplist[size - index + 1]
                    local next_buf = element["bufnr"]

                    if next_buf ~= buf then
                        return next_buf
                    end
                end

                return 0
            end,
        },
    },
    {
        -- Better Quickfix window with previews and fuzzy file search
        "kevinhwang91/nvim-bqf",
    },
    {
        -- Change text to snake_case, camelCase, PascalCase, kebab-case and more
        "johmsalas/text-case.nvim",
        lazy = false,
        config = function()
            require("textcase").setup({})
        end,
    },
    {
        -- Plugin for better file navigation
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        lazy = false,
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local harpoon = require("harpoon")

            harpoon:setup()

            -- All these are setup in the whichkey configuration

            -- vim.keymap.set("n", "<leader>ha", function()
            --     harpoon:list():add()
            -- end)
            -- vim.keymap.set("n", "<leader>hh", function()
            --     harpoon.ui:toggle_quick_menu(harpoon:list())
            -- end)
            --
            -- vim.keymap.set("n", "<leader>1", function()
            --     harpoon:list():select(1)
            -- end)
            -- vim.keymap.set("n", "<leader>2", function()
            --     harpoon:list():select(2)
            -- end)
            -- vim.keymap.set("n", "<leader>3", function()
            --     harpoon:list():select(3)
            -- end)
            -- vim.keymap.set("n", "<leader>4", function()
            --     harpoon:list():select(4)
            -- end)

            -- Toggle previous & next buffers stored within Harpoon list
            vim.keymap.set("n", "<A-h>", function()
                harpoon:list():prev()
            end)
            vim.keymap.set("n", "<A-l>", function()
                harpoon:list():next()
            end)
        end,
    },
    {
        "m4xshen/hardtime.nvim",
        lazy = false,
        dependencies = { "MunifTanjim/nui.nvim" },
        opts = {
            disabled_keys = {
                -- Enabling as they have been bind to resizing the window
                ["<Up>"] = false,
                ["<Down>"] = false,
                ["<Left>"] = false,
                ["<Right>"] = false,
            },
            resetting_keys = {
                ["<C-N>"] = { "n" },
                ["<C-P>"] = { "n" },
            },
        },
    },
    -- TODO Terminal and Tmux integration
}
