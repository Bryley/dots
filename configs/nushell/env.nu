# Nushell Environment Config File
#
# version = "0.88.1"

let state_home = ($env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local/state"))
let history_dir = ($state_home | path join "nushell")
if not ($history_dir | path exists) {
    mkdir $history_dir
}

$env.XDG_STATE_HOME = $state_home

def create_left_prompt [] {
    let home =  $nu.home-dir

    # Perform tilde substitution on dir
    # To determine if the prefix of the path matches the home dir, we split the current path into
    # segments, and compare those with the segments of the home dir. In cases where the current dir
    # is a parent of the home dir (e.g. `/home`, homedir is `/home/user`), this comparison will
    # also evaluate to true. Inside the condition, we attempt to str replace `$home` with `~`.
    # Inside the condition, either:
    # 1. The home prefix will be replaced
    # 2. The current dir is a parent of the home dir, so it will be uneffected by the str replace
    mut dir = (
        if ($env.PWD | path split | zip ($home | path split) | all { $in.0 == $in.1 }) {
            ($env.PWD | str replace $home "~")
        } else {
            $env.PWD
        }
    )

    # Stop paths from becomming too long keeping it at most 3 dirs long
    if ($dir | path split | length) > 3 {
        $dir = ($dir | path split | last 3 | prepend "..." | path join)
    }

    let nix_color = (ansi cyan)
    let path_color = (if (is-admin) { ansi red_bold } else { ansi blue_bold })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_blue_bold })
    let path_segment = $" ($path_color)($dir)"

    $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"

    let nixshell = if ($env.IN_NIX_SHELL? | is-empty) {""} else {$"($nix_color)󱄅 "}

    mut vcs = get_git_info
    let jj_info = get_jj_info

    if ($jj_info | is-not-empty) {
        $vcs = $jj_info
    }

    $"($nixshell)($path_segment)($vcs)"
}

def get_jj_info [] {
    let jj_exit_code = (do --ignore-errors { jj root | complete | get exit_code } | default 1)
    if ($jj_exit_code != 0) {
        return ""
    }

    mut closest_bookmark = (jj log -r '::@ & bookmarks()' -n 1 --no-graph -T 'bookmarks.map(|x| x.name())')

    if ($closest_bookmark | is-empty) {
        $closest_bookmark = "root()"
    } else {
        $closest_bookmark = $closest_bookmark | split words | get 0
    }

    let changes_ahead = (jj log -r $"($closest_bookmark)::@" --no-graph -T 'change_id ++ "\n"' | wc -l | into int) - 1

    let label = if ($changes_ahead != 0) { $"($closest_bookmark)+($changes_ahead)" } else { $closest_bookmark }

    # Turn into binary before attempting to decode as sometimes `jj diff` will
    # print special chars and nushell thinks it is binary
    let wc_changes = do --ignore-errors {(jj diff | complete | get stdout | into binary | decode | str trim | is-not-empty) }
    let conflict = do --ignore-errors { jj log -r @ --no-graph -n 1 -T 'conflict' | each {|x| $x == 'true'} | get 0 }

    let wc_label = if ($wc_changes) { $"(ansi yellow)*(ansi green)" } else { "" }
    let conflict_label = if ($conflict) { $"(ansi red_bold)*(ansi green)" } else { "" }

    $" (ansi green) ($conflict_label)($wc_label)($label)(ansi reset)"

}

def get_git_info [] {
    # let status = do --ignore-errors {git --no-optional-locks status --porcelain=2 --branch | lines}
    let status = do --ignore-errors {git --no-optional-locks status --porcelain=2 --branch | complete | get stdout | lines}

    if ($status | is-empty) {
        return ""
    }
    
    let branch = $status
        | where ($it | str starts-with "# branch.head")
        | split column ' ' _ _ branch
        | get branch
        | first

    let has_unstaged = (if ($status
        | where ($it | str starts-with '1') or ($it | str starts-with '2')
        | is-empty) {
        false
    } else {
        true
    })
    let color = (if $has_unstaged { ansi light_red } else {ansi green })

    $" ($color) ($branch)(ansi reset)"
}

def create_separator [] {
    let color = (if ($env.LAST_EXIT_CODE == 0) { ansi light_green } else { ansi light_red })
    $" ($color)❯(ansi reset) "
}

def create_right_prompt [] {
    # Right prompt is the time elapsed for the last command nicely formatted
    mut secs = ($env.CMD_DURATION_MS | into int) / 1000 | math round
    mut mins = 0
    mut hours = 0
    
    $mins = $secs // 60
    $secs = $secs mod 60

    $hours = $mins // 60
    $mins = $mins mod 60

    mut parts = []

    if $hours > 0 {
        $parts = ($parts | append $"($hours)h")
    }
    if $mins > 0 {
        $parts = ($parts | append $"($mins)m")
    }
    if $secs > 0 {
        $parts = ($parts | append $"($secs)s")
    }

    $"(ansi yellow)($parts | str join (char space))(ansi reset)"
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
# FIXME: This default is not implemented in rust code as of 2023-09-08.
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| create_separator }
$env.PROMPT_INDICATOR_VI_INSERT = {|| create_separator }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| " > " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `🚀`.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
$env.TRANSIENT_PROMPT_COMMAND = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# Colored man pages
$env.MANPAGER = "sh -c 'col -bx | bat -l man -p'"
$env.MANROFFOPT = "-c"

$env.EDITOR = "nvim"

$env.CARAPACE_BRIDGES = "bash"

# mise activation cache for config.nu
let mise_data_dir = $nu.data-dir
if not ($mise_data_dir | path exists) {
    mkdir $mise_data_dir
}

let mise_path = $mise_data_dir | path join "mise.nu"
if ( (which mise | is-not-empty) and not ($mise_path | path exists) ) {
    ^mise activate nu | save --force $mise_path
}
# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
$env.PATH = ($env.PATH | append '~/.config/nushell/bin')
$env.PATH = ($env.PATH | append '~/.config/hypr/wallpapers/')
$env.PATH = ($env.PATH | append '~/.cargo/bin')
$env.PATH = ($env.PATH | append '~/go/bin')
$env.PATH = ($env.PATH | append "/opt/homebrew/bin")
$env.PATH = ($env.PATH | append '/opt/homebrew/opt/mysql/bin')


# Direnv integration
$env.config = {
  hooks: {
    pre_prompt: [{ ||
      if (which direnv | is-empty) {
        return
      }

      direnv export json | from json | default {} | load-env
      if 'ENV_CONVERSIONS' in $env and 'PATH' in $env.ENV_CONVERSIONS {
        $env.PATH = do $env.ENV_CONVERSIONS.PATH.from_string $env.PATH
      }
    }]
  }
}
