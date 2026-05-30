local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node

local fmt = require("luasnip.extras.fmt").fmt

local function is_mise_toml()
    return vim.fn.expand("%:t") == "mise.toml"
end

ls.add_snippets("nix", {
    s(
        "flake",
        fmt(
            [[
        {{
          description = "{}";

          inputs = {{
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
            flake-utils.url = "github:numtide/flake-utils";
          }};

          outputs = {{ self, nixpkgs, flake-utils, ... }}@inputs:
          flake-utils.lib.eachDefaultSystem (
            system:
            let
              pkgs = import nixpkgs {{ inherit system; }};
            in
            rec {{
              devShells.default = pkgs.mkShell {{
                buildInputs = with pkgs; [
                  pkg-config
                  openssl_3
                ];
              }};
            }}
          );
        }}
        ]],
            { i(1, "Basic description of flake") }
        )
    ),
    s(
        "flakerust",
        fmt(
            [[
        {{
          description = "{}";

          inputs = {{
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
            flake-utils.url = "github:numtide/flake-utils";
            rust-overlay.url = "github:oxalica/rust-overlay";
          }};

          outputs = {{ self, nixpkgs, flake-utils, rust-overlay, ... }}@inputs:
          flake-utils.lib.eachDefaultSystem (
            system:
            let
              pkgs = import nixpkgs {{
                inherit system;
                overlays = [
                  (import rust-overlay)
                  (self: super: {{ rust-toolchain = self.rust-bin.stable; }})
                ];
              }};
              # Define the Rust toolchain with rust-src included
              rust = pkgs.rust-bin.stable.latest.default.override {{
                extensions = [ "rust-src" ];
              }};
            in
            rec {{
              devShells.default = pkgs.mkShell {{
                buildInputs = with pkgs; [
                  rust
                  pkg-config
                  openssl_3
                ];
              }};
            }}
          );
        }}
        ]],
            { i(1, "Basic description of flake for rust project") }
        )
    ),
    s(
        "docker",
        fmt(
            [[
        packages.docker-image = pkgs.dockerTools.buildImage {{
          name = "{}";
          tag = {};

          # Required for "more intellegent" container
          copyToRoot = pkgs.buildEnv {{
            name = "docker-app";
            paths = with pkgs; [
              nushell  # Feature complete shell with JSON parsing, math and more
              busybox  # A bunch of useful unix commands packaged in like ping, ls and more
              cacert   # Handles creating SSL certificates, needed for proper networking in the container
            ];
          }};

          config.Cmd = [ "${{packages.default}}/bin/{}" ];
        }};
        ]],
            {
                i(1),
                i(2, "version"),
                i(3, "executable"),
            }
        )
    ),
})

ls.add_snippets("toml", {
    s(
        {
            trig = "env",
            condition = is_mise_toml,
        },
        fmt([[
            [env]
            _.file = '.env'
            RUST_BACKTRACE = "1"
        ]], {})
    ),
    s(
        {
            trig = "task",
            condition = is_mise_toml,
        },
        fmt(
            [[
            [tasks.{}]
            run = "{}"
            ]],
            {
                i(1, "build"),
                i(2, "command"),
            }
        )
    ),
    s(
        {
            trig = "taskd",
            condition = is_mise_toml,
        },
        fmt(
            [[
            [tasks.{}]
            description = "{}"
            run = "{}"
            ]],
            {
                i(1, "build"),
                i(2, "Build the project"),
                i(3, "command"),
            }
        )
    ),
})
