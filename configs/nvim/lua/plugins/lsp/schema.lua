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

-- gitlab-ci-includes stores CI templates under names the catalog's fileMatch
-- never hits (modules/build-containers.yaml, golang.yml). Extend the existing
-- gitlab-ci entry rather than reassigning it, which would drop .gitlab-ci.yml.
-- Copied first: schemastore hands back the same inner fileMatch list on every
-- call, so extending it in place would mutate the plugin's own catalog and
-- duplicate these globs each time this file is sourced.
local gitlab_ci = "https://gitlab.com/gitlab-org/gitlab-foss/-/raw/master/app/assets/javascripts/editor/schema/ci.json"
local gitlab_ci_patterns = vim.deepcopy(yaml_schemas[gitlab_ci] or {})
vim.list_extend(gitlab_ci_patterns, {
    "**/gitlab-ci-includes/**/*.yml",
    "**/gitlab-ci-includes/**/*.yaml",
})
yaml_schemas[gitlab_ci] = gitlab_ci_patterns

vim.lsp.config("yamlls", {
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        yaml = {
            -- !reference is a GitLab CI extension, not standard YAML, so the
            -- parser rejects it as an unresolved tag unless declared here.
            customTags = { "!reference sequence" },
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
