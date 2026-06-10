local schemastore = require("schemastore")

vim.lsp.config("jsonls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        json = {
            schemas = schemastore.json.schemas(),
            validate = { enable = true, },
        }
    },
})
vim.lsp.enable("jsonls")

local yaml_schemas = schemastore.yaml.schemas()

local path = vim.fn.expand("~/Documents/schemas/evalt.schema.json")
if vim.uv.fs_stat(path) then
    yaml_schemas["file://" .. path] = { "*.eval.yaml", "*.eval.yml" }
end

vim.lsp.config("yamlls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        yaml = {
            schemaStore = {
                enable = false,
                url = "",
            },
            schemas = yaml_schemas,
        }
    },
})
vim.lsp.enable("yamlls")

vim.lsp.config("tombi", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
})
vim.lsp.enable("tombi")
