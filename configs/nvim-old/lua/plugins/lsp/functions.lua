local M = {}

--- Function is called when the "hover" effect is done to show documentation
--- It will redirect the hover effect depending on the context otherwise will
--- just use `vim.lsp.hover()`
function M.show_documentation()
    local filetype = vim.bo.filetype
    if vim.tbl_contains({ "vim", "help" }, filetype) then
        vim.cmd("h " .. vim.fn.expand("<cword>"))
    elseif vim.tbl_contains({ "man" }, filetype) then
        vim.cmd("Man " .. vim.fn.expand("<cword>"))
    elseif vim.fn.expand("%:t") == "Cargo.toml" and require("crates").popup_available() then
        require("crates").show_popup()
    else
        vim.lsp.buf.hover()
    end
end

function M.setup_diagnostics()
    --------------------------------
    -- Setup diagnostics settings --
    --------------------------------
    vim.diagnostic.config({
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = "",
                [vim.diagnostic.severity.WARN] = "",
                [vim.diagnostic.severity.HINT] = "",
                [vim.diagnostic.severity.INFO] = "",
            },
        },
        virtual_text = false,
        update_in_insert = true,
        severity_sort = true,
        float = {
            border = "rounded",
        },
    })
end

M.default_on_attach = function(client, bufnr)
    if client.server_capabilities.documentSymbolProvider then
        require("nvim-navic").attach(client, bufnr)
    end
end

M.cmp_config = function()
    local cmp = require("cmp")
    local lspkind = require("lspkind")
    -- local jira_cmp = require("plugins.lsp.cmp_jira")

    -- jira_cmp.setup({
    --     cache_ttl_ms = 300000,
    --     prewarm = true,
    --     in_progress_statuses = { "In Progress" },
    --     done_statuses = { "Done", "Closed" },
    --     done_recent_days = 3,
    --     priority_keywords = { "P1", "P2", "High" },
    --     max_results = 200,
    -- })

    cmp.setup({
        snippet = {
            expand = function(args)
                require("luasnip").lsp_expand(args.body)
            end,
        },
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
        },
        mapping = {
            ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
            ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
            ["<C-n>"] = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    fallback()
                end
            end,
            ["<C-p>"] = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else
                    fallback()
                end
            end,
        },
        sources = cmp.config.sources({
            -- { name = "jira" }, -- Disabled for now
            { name = "render-markdown" }, -- From render-markdown.nvim plugin
            { name = "nvim_lua" },
            {
                name = "nvim_lsp",
                entry_filter = function(entry)
                    -- Hide snippets from within the lsp server, Luasnip should handle them
                    return require("cmp").lsp.CompletionItemKind.Snippet ~= entry:get_kind()
                end,
            },
            { name = "path" },
            { name = "luasnip" },
            { name = "buffer",               keyword_length = 3 },
            { name = "crates" },
            { name = "vim-dadbod-completion" },
        }),
        formatting = {
            format = lspkind.cmp_format({
                mode = "symbol_text",
                maxwidth = 50,
                ellipsis_char = "...",
            }),
        },
        experimental = {
            ghost_text = true,
        },
    })
end

return M
