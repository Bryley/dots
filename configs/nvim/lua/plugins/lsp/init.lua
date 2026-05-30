local enabled = true
local functions = require("plugins.lsp.functions")
local settings = require("plugins.lsp.settings")

-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md
local LSP_SERVERS = {
    -- Rust (handled using `rustaceanvim` plugin)
    function()
        vim.g.rustaceanvim = {
            tools = {},
            server = {
                on_attach = functions.default_on_attach,
                default_settings = settings.settings(),
            },
            dap = {
                adapter = {
                    type = "server",
                    host = "127.0.0.1",
                    port = "${port}",
                    executable = {
                        command = vim.env.HOME .. "/.local/opt/codelldb/extension/adapter/codelldb",
                        args = { "--port", "${port}" },
                    },
                    name = "codelldb",
                },
            },
        }
    end,
    "lua_ls",    -- Lua
    "basedpyright", -- Python
    "htmx",      -- HTMX
    "jsonls",    -- JSON
    "yamlls",    -- YAML
    "helm_ls",   -- Helm
    "elmls",     -- ELM
    -- "denols", -- Deno
    "tailwindcss", -- Tailwind
    "nushell",   -- Nushell
    "nixd",      -- Nix
    "qmlls",     -- QML language
    -- "vtsls", -- Typescript
    "ltex",      -- Latex and markdown
    "gopls",     -- Golang lsp
    "taplo",    -- TOML
    "emmet_ls",  -- HTML expanding things like 'ul>li.item$*5'
    "harper_ls", -- Language checking
    "tinymist",  -- Typst LSP
    "ts_ls",     -- Typescript
    "svelte",    -- Svelte
    "slangd",    -- Slang shader programming
    "wgsl_analyzer", -- WGSL shader programming
}

-- https://github.com/nvimtools/none-ls.nvim/blob/main/doc/BUILTINS.md
local LINTERS = {
    code_actions = {
        "statix", -- Nix
    },
    completion = {
        "luasnip", -- Lua
    },
    diagnostics = {
        "statix", -- Nix
        "djlint", -- HTML templates
    },
    formatting = {
        -- "nixpkgs_fmt", -- Nix
        "nixfmt", -- Nix
        "biome", -- Javascript and Typescript
        "black", -- Python
        "elm_format", -- Elm
        "just", -- Justfile
        "mdformat", -- Markdown
        "prettier", -- HTML, JS and more
        "stylua", -- Lua
        "dxfmt", -- Dioxus formatting for rsx macros
        "djlint", -- HTML templates
    },
    hover = {
        "printenv", -- Prints env under cursor
    },
}

return {
    {
        -- Provides preconfigured lsp configs for lots of languages
        "neovim/nvim-lspconfig",
        cond = enabled,
        keys = {
            { "gd",    "<cmd>lua vim.lsp.buf.definition()<CR>",     desc = "goto definition" },
            { "gD",    "<cmd>lua vim.lsp.buf.declaration()<CR>",    desc = "goto declaration" },
            { "gr",    "<cmd>lua vim.lsp.buf.references()<CR>",     desc = "goto references" },
            { "gi",    "<cmd>lua vim.lsp.buf.implementation()<CR>", desc = "goto implementations" },
            { "K",     functions.show_documentation,                desc = "show docs" },
            { "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", desc = "Show signature" },
            { "<C-p>", "<cmd>lua vim.diagnostic.goto_prev()<CR>",   desc = "goto prev diagnostic" },
            { "<C-n>", "<cmd>lua vim.diagnostic.goto_next()<CR>",   desc = "goto next diagnostic" },
        },
        dependencies = {
            "hrsh7th/nvim-cmp", -- Completion engine
            "b0o/schemastore.nvim", -- Includes JSON & YAML schemas
            "towolf/vim-helm", -- For Helm charts
        },
        config = function()
            functions.setup_diagnostics()

            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- Setup LSP clients
            for _, value in pairs(LSP_SERVERS) do
                if type(value) == "string" then
                    vim.lsp.config(value, {
                        on_attach = functions.default_on_attach,
                        capabilities = capabilities,
                        settings = settings.settings(),
                        filetypes = settings.filetypes[value],
                        init_options = settings.init_options[value],
                        cmd = settings.cmds[value],
                    })
                    vim.lsp.enable(value)
                else
                    value()
                end
            end
        end,
    },
    {
        -- Completion engine for the LSP
        "hrsh7th/nvim-cmp",
        cond = enabled,
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",        -- Enables LSP auto completion
            "hrsh7th/cmp-buffer",          -- Enables buffer completions
            "hrsh7th/cmp-path",            -- Path completions
            "hrsh7th/cmp-cmdline",         -- Enables cmdline completions
            "hrsh7th/cmp-nvim-lua",        -- Enables nvim lua autocompletions
            "saadparwaiz1/cmp_luasnip",    -- Enables snippet autocompletions
            "folke/neodev.nvim",           -- Better LSP docs support for Neovim Lua code
            "onsails/lspkind.nvim",        -- Adds pictograms to dropdown
            "L3MON4D3/LuaSnip",            -- Snippet engine
            "kristijanhusak/vim-dadbod-completion", -- SQL dadbod completions
        },
        config = functions.cmp_config,
    },
    {
        -- Adds ability to use formatters and linters with LSP
        "nvimtools/none-ls.nvim",
        cond = enabled,
        config = function()
            local null_ls = require("null-ls")
            local sources = {}
            for section_name, values in pairs(LINTERS) do
                local section = null_ls.builtins[section_name]
                if section == nil then
                    vim.notify("Section '" + section_name + "' doesn't exist", vim.logs.levels.WARN)
                    goto section_continue
                end
                for _, name in pairs(values) do
                    local val = section[name]
                    if val == nil then
                        vim.notify(
                            "Linter value '" + section_name + "." + name("' doesn't exist"),
                            vim.logs.levels.WARN
                        )
                        goto continue
                    end
                    table.insert(sources, val)
                    ::continue::
                end
                ::section_continue::
            end
            null_ls.setup({
                sources = sources,
            })
        end,
    },
    {
        -- Adds snippets to NeoVim
        "L3MON4D3/LuaSnip",
        cond = enabled,
        version = "v2.*",
        dependencies = {
            "rafamadriz/friendly-snippets", -- Collection of snippets
        },
        config = function()
            require("luasnip.loaders.from_vscode").lazy_load()

            -- Keybinds
            local ls = require("luasnip")
            ls.config.set_config({
                history = true,
                updateevents = "TextChanged,TextChangedI",
                enable_autosnippets = true,
            })

            -- Add my own snippets
            require("plugins.lsp.snippets")

            vim.keymap.set({ "i" }, "<C-K>", function()
                ls.expand()
            end, { silent = true })
            vim.keymap.set({ "i", "s" }, "<C-L>", function()
                ls.jump(1)
            end, { silent = true })
            vim.keymap.set({ "i", "s" }, "<C-J>", function()
                ls.jump(-1)
            end, { silent = true })

            vim.keymap.set({ "i", "s" }, "<C-E>", function()
                if ls.choice_active() then
                    ls.change_choice(1)
                end
            end, { silent = true })
        end,
    },
    {
        -- Breadcrumbs at top
        "SmiteshP/nvim-navic",
        cond = enabled,
        dependencies = {
            "neovim/nvim-lspconfig",
        },
        lazy = false,
        opts = {
            highlight = true,
            click = true,
        },
    },
    {
        -- Breadcrumbs GUI menu
        "SmiteshP/nvim-navbuddy",
        cond = enabled,
        dependencies = {
            "neovim/nvim-lspconfig",
            "SmiteshP/nvim-navic",
            "MunifTanjim/nui.nvim",
        },
        opts = {
            lsp = { auto_attach = true },
        },
    },
    {
        -- Adds LSP progress in bottom right corner as virtual text
        "j-hui/fidget.nvim",
        cond = enabled,
        opts = {},
    },
    {
        -- Rust LSP plugin for managing crate dependencies and features
        "saecki/crates.nvim",
        cond = enabled,
        event = { "BufRead Cargo.toml" },
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            require("crates").setup({
                null_ls = {
                    enabled = true,
                    name = "crates.nvim",
                },
            })
        end,
    },
    {
        "mrcjkb/rustaceanvim",
        cond = enabled,
        version = '^8', -- Recommended
        ft = { "rust" },
    },
    {
        -- Special formatter for maud Rust templates
        "eboody/maud-fmt.nvim",
        config = function()
            require("maud-fmt").setup({
                indent_size = 4,
                keymaps = {},
            })
        end,
        ft = "rust",
    },
}
