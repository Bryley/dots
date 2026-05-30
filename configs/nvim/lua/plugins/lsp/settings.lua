local M = {}

M.settings = function()
    return {
        Lua = {
            diagnostics = {
                globals = {
                    "vim",
                    "describe",
                    "it",
                    "before_each",
                    "after_each",
                    "before",
                    "after",
                    "assert",
                    "spy",
                    "mock",
                    "stub",
                    "pending",
                    "teardown",
                    "setup",
                    "lazy_setup",
                    "lazy_teardown",
                },
            },
        },
        nixd = {
            nixpkgs = {
                expr = "import <nixpkgs> {  }",
            },
            formatting = {
                command = { "nixfmt" },
            },
            options = {
                nixos = {
                    expr = '(builtins.getFlake "/home/bryley/nixos-flake").nixosConfigurations.laptop.options',
                },
                home_manager = {
                    expr = '(builtins.getFlake "/home/bryley/nixos-flake").homeConfigurations.laptop.options',
                },
            },
        },
        ["rust-analyzer"] = {
            cargo = {
                features = "all",
            },
            check = {
                command = "clippy",
            },
            files = {
                excludeDirs = {
                    ".dart_tool",
                    ".direnv",
                    ".flatpak-builder",
                    ".git",
                    ".gitlab",
                    ".gitlab-ci",
                    ".gradle",
                    ".idea",
                    ".next",
                    ".project",
                    ".scannerwork",
                    ".settings",
                    ".venv",
                    "_build",
                    "archetype-resources",
                    "bin",
                    "frontend/node_modules",
                    "hooks",
                    "node_modules",
                    "po",
                    "screenshots",
                    "target",
                },
                watcherExclude = {
                    ["**/.classpath"] = true,
                    ["**/.dart_tool"] = true,
                    ["**/.direnv"] = true,
                    ["**/.factorypath"] = true,
                    ["**/.flatpak-builder"] = true,
                    ["**/.git/objects/**"] = true,
                    ["**/.git/subtree-cache/**"] = true,
                    ["**/.idea"] = true,
                    ["**/.project"] = true,
                    ["**/.scannerwork"] = true,
                    ["**/.settings"] = true,
                    ["**/.venv"] = true,
                    ["**/_build"] = true,
                    ["**/node_modules"] = true,
                },
            },
        },
        elmLS = {
            onlyUpdateDiagnosticsOnSave = true,
            elmReviewDiagnostics = "off",
            -- disableElmLSDiagnostics = true,
        },
        -- TODO: Disabled for now due to spamming :LspInfo page
        -- json = {
        --     schemas = require("schemastore").json.schemas({
        --         extra = {},
        --     }),
        --     validate = { enable = true },
        -- },
        yaml = {
            schemas = {
                kubernetes = "*.yaml",
                ["http://json.schemastore.org/chart"] = "Chart.{yml,yaml}",
                ["https://json.schemastore.org/gitlab-ci"] = "*gitlab-ci*.{yml,yaml}",
            },
            validate = { enable = true },
        },
        taplo = {
            schema = {
                associations = {
                    ["mise.toml"] = "https://mise.jdx.dev/schema/mise.json",
                    ["mise.local.toml"] = "https://mise.jdx.dev/schema/mise.json",
                    ["mise/config.toml"] = "https://mise.jdx.dev/schema/mise.json",
                    [".mise/config.toml"] = "https://mise.jdx.dev/schema/mise.json",
                },
            },
        },
        ["helm-ls"] = {
            yamlls = {
                path = "yaml-language-server",
            },
        },
        tailwindCSS = {
            includeLanguages = {
                elm = "html",
                -- rust = "html",
                html = "html",
                htmldjango = "html",
            },
            -- classAttributes = { "class", "className", "classList", "ngClass" },
            experimental = {
                -- Include regex for ELM
                classRegex = {
                    -- Maud (Rust)
                    '\\."([^"]+)"',
                    '\\bclass\\s*=\\s*"([^"]+)"',
                    -- For ELM:
                    '\\bclass[\\s(<|]+"([^"]*)"',
                    '\\bclass[\\s(]+"[^"]*"[\\s+]+"([^"]*)"',
                    '\\bclass[\\s<|]+"[^"]*"\\s*\\+{2}\\s*" ([^"]*)"',
                    '\\bclass[\\s<|]+"[^"]*"\\s*\\+{2}\\s*" [^"]*"\\s*\\+{2}\\s*" ([^"]*)"',
                    '\\bclass[\\s<|]+"[^"]*"\\s*\\+{2}\\s*" [^"]*"\\s*\\+{2}\\s*" [^"]*"\\s*\\+{2}\\s*" ([^"]*)"',
                    '\\bclassList[\\s\\[\\(]+"([^"]*)"',
                    '\\bclassList[\\s\\[\\(]+"[^"]*",\\s[^\\)]+\\)[\\s\\[\\(,]+"([^"]*)"',
                    '\\bclassList[\\s\\[\\(]+"[^"]*",\\s[^\\)]+\\)[\\s\\[\\(,]+"[^"]*",\\s[^\\)]+\\)[\\s\\[\\(,]+"([^"]*)"',
                },
                configFile = "src/tailwind.css",
            },
            -- lint = {
            --     cssConflict = "warning",
            --     invalidApply = "error",
            --     invalidConfigPath = "error",
            --     invalidScreen = "error",
            --     invalidTailwindDirective = "error",
            --     invalidVariant = "error",
            --     recommendedVariantOrder = "warning",
            -- },
            -- validate = true,
        },
        basedpyright = {
            analysis = {
                -- Enable auto-import suggestions
                autoImportCompletions = true,
                autoSearchPaths = true,
                diagnosticMode = "workspace",
            },
            -- If needed, add extra paths (adjust the Python version as appropriate)
            -- extraPaths = { ".venv/lib/python3.11/site-packages" },
        },
        ["harper-ls"] = {
            userDictPath = "~/dict.txt",
            dialect = "Australian",
        },
        svelte = {
            compilerOptions = {
                runes = true,
            },
        },
    }
end

M.filetypes = {
    tailwindcss = { "html", "htmldjango", "rust", "elm", "jsx", "tsx", "css", "svelte" },
    htmx = { "html", "htmldjango" },
    ltex = { "markdown", "txt" },
}

M.init_options = {
    configuration = {
      svelte = {
        compilerOptions = {
          runes = true,  -- force runes for LSP diagnostics
          -- modern = true, -- optional; Svelte 5 “modern AST” (not required)
        },
        -- You can also promote specific warnings:
        -- compilerWarnings = { binding_property_non_reactive = "error" },
      },
    },
    -- tailwindcss = {
    --     userLanguages = {
    --         elm = "html",
    --         rust = "html",
    --         html = "html",
    --     },
    -- },
}

M.cmds = {
    qmlls = {
        "qmlls",
        "-E",
    },
}

return M
