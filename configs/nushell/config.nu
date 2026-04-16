# Nushell Config File
#
# version = "0.88.1"

# For more information on defining custom themes, see
# https://www.nushell.sh/book/coloring_and_theming.html
# And here is the theme collection
# https://github.com/nushell/nu_scripts/tree/main/themes
let dark_theme = {
    # color for nushell primitives
    separator: white
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'light_cyan' } else { 'light_gray' } }
    bool: light_cyan
    int: white
    filesize: cyan
    duration: white
    date: purple
    range: white
    float: white
    string: white
    nothing: white
    binary: white
    cell-path: white
    row_index: green_bold
    record: white
    list: white
    block: white
    hints: light_gray_dimmed
    search_result: {bg: red fg: white}
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_yellow_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
}

let light_theme = {
    # color for nushell primitives
    separator: dark_gray
    leading_trailing_space_bg: { attr: n } # no fg, no bg, attr none effectively turns this off
    header: green_bold
    empty: blue
    # Closures can be used to choose colors for specific values.
    # The value (in this case, a bool) is piped into the closure.
    # eg) {|| if $in { 'dark_cyan' } else { 'dark_gray' } }
    bool: dark_cyan
    int: dark_gray
    filesize: cyan_bold
    duration: dark_gray
    date: purple
    range: dark_gray
    float: dark_gray
    string: dark_gray
    nothing: dark_gray
    binary: dark_gray
    cell-path: dark_gray
    row_index: green_bold
    record: dark_gray
    list: dark_gray
    block: dark_gray
    hints: dark_gray
    search_result: {fg: white bg: red}
    shape_and: purple_bold
    shape_binary: purple_bold
    shape_block: blue_bold
    shape_bool: light_cyan
    shape_closure: green_bold
    shape_custom: green
    shape_datetime: cyan_bold
    shape_directory: cyan
    shape_external: cyan
    shape_externalarg: green_bold
    shape_external_resolved: light_purple_bold
    shape_filepath: cyan
    shape_flag: blue_bold
    shape_float: purple_bold
    # shapes are used to change the cli syntax highlighting
    shape_garbage: { fg: white bg: red attr: b}
    shape_globpattern: cyan_bold
    shape_int: purple_bold
    shape_internalcall: cyan_bold
    shape_keyword: cyan_bold
    shape_list: cyan_bold
    shape_literal: blue
    shape_match_pattern: green
    shape_matching_brackets: { attr: u }
    shape_nothing: light_cyan
    shape_operator: yellow
    shape_or: purple_bold
    shape_pipe: purple_bold
    shape_range: yellow_bold
    shape_record: cyan_bold
    shape_redirection: purple_bold
    shape_signature: green_bold
    shape_string: green
    shape_string_interpolation: cyan_bold
    shape_table: blue_bold
    shape_variable: purple
    shape_vardecl: purple
}

let carapace_completer = {|spans|
    carapace $spans.0 nushell ...$spans | from json
}

# The default config record. This is where much of your global configuration is setup.
$env.config = {
    show_banner: false # true or false to enable or disable the welcome banner at startup

    ls: {
        use_ls_colors: true # use the LS_COLORS environment variable to colorize output
        clickable_links: true # enable or disable clickable links. Your terminal has to support links.
    }

    rm: {
        always_trash: true
    }

    history: {
        max_size: 100_000 # Session has to be reloaded for this to take effect
        sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
        file_format: "plaintext" # "sqlite" or "plaintext"
        isolation: false # only available with sqlite file_format. true enables history isolation, false disables it. true will allow the history to be isolated to the current session using up/down arrows. false will allow the history to be shared across all sessions.
        # TODO when nushell 0.112.0 comes out then re-enable this:
        # path: ($env.XDG_STATE_HOME | path join "nushell" "history.txt")
    }

    completions: {
        case_sensitive: false # set to true to enable case-sensitive completions
        quick: true    # set this to false to prevent auto-selecting completions when only one remains
        partial: true    # set this to false to prevent partial filling of the prompt
        algorithm: "fuzzy"    # prefix or fuzzy
        external: {
            enable: true # set to false to prevent nushell looking into $env.PATH to find more suggestions, `false` recommended for WSL users as this look up may be very slow
            max_results: 15 # setting it lower can improve completion performance at the cost of omitting some options
            completer: $carapace_completer
        }
    } cursor_shape: {
        emacs: line
        vi_insert: line
        vi_normal: block
    }

    color_config: $dark_theme # if you want a more interesting theme, you can replace the empty record with `$dark_theme`, `$light_theme` or another custom record
    edit_mode: vi
    hooks: {
        pre_prompt: [{ ||
            # Force a darker blue for directories because the default/light theme
            # made dir names too low-contrast and hard to read in Ghostty.
            let ls_colors = ($env.LS_COLORS? | default "")
            let ls_colors = ($ls_colors
                | split row ":"
                | where {|it| ($it | is-not-empty) and not ($it | str starts-with "di=") })
            $env.LS_COLORS = ($ls_colors | append "di=0;34" | str join ":")

            # Direnv hook
            if (which direnv | is-empty) {
                return
            }

            direnv export json | from json | default {} | load-env
        }]
    }
}

const mise_path = ($nu.data-dir | path join "mise.nu")
const mise_source = if ($mise_path | path exists) { $mise_path } else { null }
source $mise_source

# Television shell integration
# Reference: https://alexpasmantier.github.io/television/user-guide/shell-integration#nushell
if (which tv | is-not-empty) {
    let tv_autoload_dir = ($nu.data-dir | path join "vendor/autoload")
    let tv_script = ($tv_autoload_dir | path join "tv.nu")

    if not ($tv_autoload_dir | path exists) {
        mkdir $tv_autoload_dir
    }

    ^tv init nu | save --force $tv_script
}

# Handy aliases and small shell scripts

# Find and goto dir recursively (with early exit support)
export def --env f [] {
    let fd_cmd = 'fd --type directory --exclude node_modules --exclude target --exclude vendor --exclude site-packages --exclude golang.org --exclude registry'

    let path = (
        ^fzf
            --border
            --layout=reverse
            --height=40%
            # Populate the list when fzf starts
            --bind $"start:reload:($fd_cmd)"
    )

    cd $path
}

# Parses and loads a .env file into the environment
export def load-dotenv [file: path = ".env"] {
    (
        open $file
            | lines
            | where (not ($it | str trim | str starts-with '#') and ($it | str trim) != "")
            | each {|it| $it | str replace -r "^export " ""}
            | split column -n 2 "="
            | update column1 {|it| $it.column1 | str trim}
            | update column2 {|it| $it.column2 | str trim}
            | transpose --as-record  --header-row
            | load-env
    )
}

# Activates a python virtualenv
alias activate = overlay use ./.venv/bin/activate.nu

# Sets up nix develop command to automatically alias to `nix develop --command nu`
# TODO fix this so you can use options with it
# def nix [ ...args ] {
#     if ( ($args | first 1 | to text | str trim) == "develop" ) {
#         # If the first argument is 'develop', modify the command
#         ^nix develop --command nu ($args | skip 1)
#     } else {
#         # For all other commands, pass the arguments as-is
#         ^nix $args
#     }
# }

# Opens current git repo's webpage
def gitopen [] {
    let url = (git remote get-url origin)
    let url = $url | str replace -a ':' '/'
    let url = $url | str replace -a 'git@' 'https://'
    let url = $url | str replace -a '.git' ''
    start $url
}

$env.FZF_DEFAULT_OPTS = "--layout=reverse --height=40% --border"
# Removes direnv output
$env.DIRENV_LOG_FORMAT = ""

# let nixld = (if (echo "/etc/NIXOS" | path exists) {
#     # If on NixOS then set up the nix_ld dynamic linker (note it needs to be installed)
#     (^nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')
# } else {
#     ""
# })
#
# $env.NIX_LD = $nixld

# $env.NIX_LD=$nixld

# def nvim [...$args] {
#     NIX_LD=$nixld _nvim $args
# }

const secret_file = if ('~/dots/configs/nushell/secret.nu' | path exists) {
    "~/dots/configs/nushell/secret.nu"
} else {
    null
}

source $secret_file
