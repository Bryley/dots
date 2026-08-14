vim.lsp.config("bashls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable("bashls")
