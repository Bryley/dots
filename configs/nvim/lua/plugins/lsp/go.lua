vim.lsp.config("gopls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {},
})
vim.lsp.enable("gopls")
