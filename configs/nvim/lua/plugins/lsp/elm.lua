vim.lsp.config("elmls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable("elmls")
