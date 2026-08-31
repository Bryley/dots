vim.lsp.config("tailwindcss", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    filetypes = { "rust", "css" },
    settings = {
        tailwindCSS = {
            includeLanguages = {
                rust = "html",
            },
            experimental = {
                classRegex = {
                    'class\\s*:\\s*"([^"]*)"',
                },
            },
        },
    },
})
vim.lsp.enable("tailwindcss")
