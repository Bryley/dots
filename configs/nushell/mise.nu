def "parse vars" [] {
  $in | from csv --noheaders --no-infer | rename 'op' 'name' 'value'
}

def --env "update-env" [] {
  for $var in $in {
    if $var.op == "set" {
      if ($var.name | str upcase) == 'PATH' {
        $env.PATH = ($var.value | split row (char esep))
      } else {
        load-env {($var.name): $var.value}
      }
    } else if $var.op == "hide" and $var.name in $env {
      hide-env $var.name
    }
  }
}
export-env {
  
  'set,PATH,/run/wrappers/bin:/home/bryley/.nix-profile/bin:/nix/profile/bin:/home/bryley/.local/state/nix/profile/bin:/etc/profiles/per-user/bryley/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/home/bryley/.config/nushell/bin:/home/bryley/.config/hypr/wallpapers/:/home/bryley/.cargo/bin:/home/bryley/go/bin:/opt/homebrew/bin:/opt/homebrew/opt/mysql/bin:/nix/store/7pjcjlyx7iafpgi606rczchcl980xdn6-kitty-0.45.0/bin:/nix/store/1h2q0hs7448xh93rsd8r4xajcgds8nzj-imagemagick-7.1.2-13/bin:/nix/store/f1ahhmizr4qi79k2hh0aaryrzzjivf0h-ncurses-6.6-dev/bin
hide,MISE_SHELL,
hide,__MISE_DIFF,
hide,__MISE_DIFF,' | parse vars | update-env
  $env.MISE_SHELL = "nu"
  let mise_hook = {
    condition: { "MISE_SHELL" in $env }
    code: { mise_hook }
  }
  add-hook hooks.pre_prompt $mise_hook
  add-hook hooks.env_change.PWD $mise_hook
}

def --env add-hook [field: cell-path new_hook: any] {
  let field = $field | split cell-path | update optional true | into cell-path
  let old_config = $env.config? | default {}
  let old_hooks = $old_config | get $field | default []
  $env.config = ($old_config | upsert $field ($old_hooks ++ [$new_hook]))
}

export def --env --wrapped main [command?: string, --help, ...rest: string] {
  let commands = ["deactivate", "shell", "sh"]

  if ($command == null) {
    ^"/run/current-system/sw/bin/mise"
  } else if ($command == "activate") {
    $env.MISE_SHELL = "nu"
  } else if ($command in $commands) {
    ^"/run/current-system/sw/bin/mise" $command ...$rest
    | parse vars
    | update-env
  } else {
    ^"/run/current-system/sw/bin/mise" $command ...$rest
  }
}

def --env mise_hook [] {
  ^"/run/current-system/sw/bin/mise" hook-env -s nu
    | parse vars
    | update-env
}

