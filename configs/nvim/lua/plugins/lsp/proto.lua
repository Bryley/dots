vim.lsp.config("protols", {
    cmd = { "protols", "-i", vim.fn.expand("~/go/src") },
    capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable("protols")
