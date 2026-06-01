return {
    {
        -- Better UI for Neovim lua functions like vim.ui.input()
        "stevearc/dressing.nvim",
        config = true,
    },
    {
        -- Uses "yazi" file manager within Neovim
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        dependencies = {
            { "nvim-lua/plenary.nvim", lazy = true },
        },
        keys = {
            {
                "<leader>-",
                mode = { "n", "v" },
                "<cmd>Yazi<cr>",
                desc = "Yazi file manager on file",
            },
            {
                "<leader>=",
                "<cmd>Yazi cwd<cr>",
                desc = "Yazi file manager on project",
            },
        },
        opts = {
            -- if you want to open yazi instead of netrw, see below for more info
            open_for_directories = true,
            keymaps = {
                show_help = "<f1>",
            },
        },
    },
    {
        -- Integration between harpoon and bufferline
        "BourbonBidet/Barpoon",
        dependencies = {
            {
                "ThePrimeagen/harpoon",
                branch = "harpoon2",
            },

            -- NOTE: Pick one
            { "akinsho/bufferline.nvim" },
        },
        opts = {
            key_labels = "12345678",
        }, -- Config here
    },
    {
        -- Shows buffers at the top of the screen
        "akinsho/bufferline.nvim",
        lazy = false,
        version = "*",
        dependencies = "nvim-tree/nvim-web-devicons",
        -- keys = {
        --     { "<A-h>", "<cmd>bprev<cr>",  mode = "n", desc = "Prev Buffer" },
        --     { "<A-l>", "<cmd>bnext<cr>",  mode = "n", desc = "Next Buffer" },
        --     { "<A-c>", "<cmd>BufDel<cr>", mode = "n", desc = "Close Buffer" },
        --     { "<A-h>", "<cmd>bprev<cr>",  mode = "i", desc = "Prev Buffer" },
        --     { "<A-l>", "<cmd>bnext<cr>",  mode = "i", desc = "Next Buffer" },
        --     { "<A-c>", "<cmd>BufDel<cr>", mode = "i", desc = "Close Buffer" },
        -- },
        opts = {
            options = {
                close_command = "BufDel! %d",
                right_mouse_command = "",
                offsets = {
                    {
                        filetype = "neo-tree",
                        text = "File Explorer",
                        text_align = "center",
                        separator = true,
                    },
                },
                diagnostics = "nvim_lsp",
                separator_style = "slant",
                hover = {
                    enabled = true,
                    delay = 200,
                    reveal = { "close" },
                },
                -- Doesn't work, todo fix it
                -- custom_filter = function(buf_number)
                --     -- Example logic to only show buffers of the current tabpage
                --     return vim.fn.tabpagenr() == vim.fn.bufwinnr(buf_number)
                -- end,
            },
        },
    },
    {
        -- Status line plugin
        "nvim-lualine/lualine.nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
            "SmiteshP/nvim-navic",
            "SmiteshP/nvim-navbuddy",
        },
        config = function()
            local navic = require("nvim-navic")

            require("lualine").setup({
                options = {
                    component_separators = "|",
                    section_separators = { left = "", right = "" },
                },
                sections = {
                    lualine_c = { { "filename", path = 1 } },
                },
                inactive_sections = {
                    lualine_c = { { "filename", path = 1 } },
                },
                winbar = {
                    lualine_c = {
                        {
                            function()
                                return navic.get_location()
                            end,
                            cond = function()
                                return navic.is_available()
                            end,
                        },
                    },
                },
            })
        end,
    },
    {
        -- Database Client in Neovim
        "kndndrj/nvim-dbee",
        dependencies = {
            "MunifTanjim/nui.nvim",
        },
        build = function()
            -- Install tries to automatically detect the install method.
            -- if it fails, try calling it with one of these parameters:
            --    "curl", "wget", "bitsadmin", "go"
            require("dbee").install()
        end,
        config = function()
            require("dbee").setup( --[[optional config]])
        end,
    },
    {
        -- Adds terminal window easily
        "akinsho/toggleterm.nvim",
        version = "*",
        keys = {
            { "<F4>", "<cmd>ToggleTerm<cr>", desc = "Toggle Terminal" },
        },
        config = true,
    },
    {
        -- Startup Page configuration
        "goolord/alpha-nvim",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")

            dashboard.section.header.val = {
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                     ]],
                [[       ████ ██████           █████      ██                     ]],
                [[      ███████████             █████                             ]],
                [[      █████████ ███████████████████ ███   ███████████   ]],
                [[     █████████  ███    █████████████ █████ ██████████████   ]],
                [[    █████████ ██████████ █████████ █████ █████ ████ █████   ]],
                [[  ███████████ ███    ███ █████████ █████ █████ ████ █████   ]],
                [[ ██████  █████████████████████ ████ █████ █████ ████ ██████ ]],
                [[                                                                       ]],
                [[                                                                       ]],
                [[                                                                       ]],
            }
            dashboard.section.header.opts = {
                hl = "Function",
                position = "center",
            }

            dashboard.section.buttons.val = {
                dashboard.button("<F1>", "Last Session"),
                dashboard.button("SPC =", "Open File Explorer"),
                dashboard.button("e", "New file", "<cmd>ene <CR>"),
                dashboard.button("SPC f f", "Find file"),
                dashboard.button("SPC f g", "Grep search"),
            }
            _Gopts = {
                position = "center",
                hl = "Type",
                -- wrap = "overflow";
            }

            local function footer()
                local quotes = {
                    "Programming is an art of patience not talent",
                    "Don't comment bad code, rewrite it - Brian Kernighan",
                    "Bad programmers worry about the code. Good programmers worry about data structures and their relationships - Linus Torvalds",
                    "Any fool can write code that a computer can understand. Good programmers write code that humans can understand - Martin Fowler",
                    "One of my most productive days was throwing away 1000 lines of code - Ken Thompson",
                }
                return quotes[math.random(#quotes)]
            end

            dashboard.section.footer.val = footer()

            dashboard.opts.opts.noautocmd = true
            alpha.setup(dashboard.opts)
        end,
    },
    {
        -- UI for vim dadbod which is a SQL TUI in Neovim
        "kristijanhusak/vim-dadbod-ui",
        dependencies = {
            { "tpope/vim-dadbod",                     lazy = true },
            { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true }, -- Optional
            { "pbogut/vim-dadbod-ssh" },                                                      -- For ssh support
        },
        cmd = {
            "DBUI",
            "DBUIToggle",
            "DBUIAddConnection",
            "DBUIFindBuffer",
        },
        init = function()
            vim.g.db_ui_use_nerd_fonts = 1
            vim.g.db_ui_table_helpers = {
                mysql = {
                    List = "SELECT * FROM `{dbname}`.`{table}` LIMIT 200;",
                },
            }
        end,
    },
    {
        -- Advanced Color highlighter and picker
        "uga-rosa/ccc.nvim",
        lazy = false,
        config = function()
            vim.opt.termguicolors = true

            local ccc = require("ccc")

            ccc.setup({
                -- Your preferred settings
                -- Example: enable highlighter
                highlighter = {
                    auto_enable = true,
                    lsp = true,
                },
                inputs = {
                    ccc.input.rgb,
                    ccc.input.hsl,
                    ccc.input.oklch,
                },
                outputs = {
                    ccc.output.hex,
                    ccc.output.hex_short,
                    ccc.output.css_rgb,
                    ccc.output.css_hsl,
                    ccc.output.css_oklch,
                },
                convert = {
                    { ccc.picker.hex,       ccc.output.css_rgb },
                    { ccc.picker.css_rgb,   ccc.output.css_oklch },
                    { ccc.picker.css_oklch, ccc.output.hex },
                },
            })
        end,
    },
    {
        -- Basic speed typing inside Neovim
        "nvzone/typr",
        dependencies = "nvzone/volt",
        opts = {},
        cmd = { "Typr", "TyprStats" },
    },
    {
        -- Render markdown while editing
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            html = {
                comment = {
                    conceal = false, -- <- this is the key bit
                },
            },
        },
    },
    {
        -- Measures typing speed quietly in the background
        "JakobSachs/typing-metrics.nvim",
        lazy = false,
        opts = {},
    },
    {
        -- Shows marks in the gutter for easier marks
        "chentoast/marks.nvim",
        event = "VeryLazy",
        opts = {},
    },
    {
        "mistweaverco/kulala.nvim",
        -- keys = {
        --     { "<leader>Rs", desc = "Send request" },
        --     { "<leader>Ra", desc = "Send all requests" },
        --     { "<leader>Rb", desc = "Open scratchpad" },
        -- },
        ft = { "http", "rest" },
        opts = {
            global_keymaps = true,
            global_keymaps_prefix = "<leader>R",
            -- kulala_keymaps_prefix = "",
        },
    },
    -- Lua
    {
        "f-person/auto-dark-mode.nvim",
        opts = {
            set_dark_mode = function()
                vim.cmd.colorscheme("onedark")
            end,
            set_light_mode = function()
                vim.cmd.colorscheme("base16-one-light")
            end,
            update_interval = 1000,
            fallback = "dark",
        },
    },
}
