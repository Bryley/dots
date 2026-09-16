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

local custom_schemas = {
    {
        path = vim.fn.stdpath("config") .. "/schemas/yoink-v0.20.10.schema.json",
        files = { "yoink*.yaml", "yoink*.yml" },
    },
    {
        path = vim.fn.expand("~/Documents/schemas/evalt.schema.json"),
        files = { "*.eval.yaml", "*.eval.yml" },
    },
}

for _, schema in ipairs(custom_schemas) do
    if vim.uv.fs_stat(schema.path) then
        yaml_schemas[vim.uri_from_fname(schema.path)] = schema.files
    end
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
