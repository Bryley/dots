vim.pack.add({
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/j-hui/fidget.nvim",
})

require("fidget").setup({})

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        -- Disable color preview (nvim-highlight-colors plugin will handle it)
        vim.lsp.document_color.enable(false, { bufnr = ev.buf })

        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end

        local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, {
                buffer = ev.buf,
                desc = desc,
            })
        end

        if client:supports_method("textDocument/hover") then
            map("K", vim.lsp.buf.hover, "LSP hover")
        end

        if client:supports_method("textDocument/definition") then
            map("gd", vim.lsp.buf.definition, "Go to definition")
        end

        if client:supports_method("textDocument/codeAction") then
            map("<leader>la", vim.lsp.buf.code_action, "LSP code action")
        end

        if client:supports_method("textDocument/formatting") then
            map("<leader>lf", function()
                vim.lsp.buf.format({
                    bufnr = ev.buf,
                    timeout_ms = 3000,
                })
            end, "LSP format")
        end
    end
})

vim.diagnostic.config({
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "󰌵",
        },
    },
})


require("plugins.lsp.lua")
require("plugins.lsp.rust")
