vim.lsp.config("rust_analyzer", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        ["rust-analyzer"] = {
            check = {
                command = "clippy",
            },
        },
    },
})
vim.lsp.enable("rust_analyzer")
