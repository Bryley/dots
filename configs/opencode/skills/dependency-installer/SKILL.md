---
name: dependency-installer
description: Install missing dependencies safely using mise for CLI tools and system package managers for low-level packages
---

# Dependency Installer

Use this skill when another agent needs a dependency that is missing from the environment.

## Use this when
- A required command is not on PATH.
- A task fails due to a missing package or library.
- You need a consistent install flow with explicit user confirmation.

## Do not use this when
- The dependency is already available.
- The task can proceed with a temporary workaround and no install.

## Required inputs from caller
- `requested_name`: tool or package name.
- `executable_name` (optional): expected binary name for PATH checks.
- `requested_version` (optional): explicit version, otherwise use latest.
- `type_hint`: `cli`, `system`, or `unknown`.
- `tool_description`: short description of what it does.
- `why_needed`: short reason tied to the current task.

## Workflow
1. Check if already installed.
   - Use `command -v <executable_name or requested_name>`.
   - If found, return `already_present` and stop.
2. Classify dependency type.
   - `cli`: install with mise.
   - `system`: install with system package flow.
   - `unknown`: ask user whether this is a CLI tool or system package/library.
3. Ask for explicit confirmation before any install command.
4. Install and verify.
5. Return structured result with status and attempted commands.

## CLI tool install path (mise)

Always ask user to choose scope with a selection prompt.

Prompt content must include:
- What the tool does (`tool_description`).
- Why it is needed now (`why_needed`).
- The exact command that will run for each option.

Options:
- `Local (recommended)`: `mise use <requested_name>@<version-or-latest>`
- `Global`: `mise use -g <requested_name>@<version-or-latest>`
- `Cancel`

Rules:
- Local means project-scoped and recorded in project `mise.toml`.
- Global means user-level mise config.
- Do not install if user cancels.

## System dependency install path

### NixOS behavior
For NixOS system dependencies, do not use imperative apt/pacman style commands.

Instead:
1. Locate package lists in current project Nix files by searching for:
   - `environment.systemPackages`
   - `environment.packages`
2. Add the package to the most appropriate shared package list (prefer existing shared module location, e.g. `modules/software.nix`, unless context requires a host-specific file).
3. Ask for explicit confirmation before editing files.
4. Validate with the smallest meaningful check when possible:
   - `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
   - or targeted `nix build` when requested.

### Non-NixOS behavior
Auto-run installs only after explicit confirmation.

Manager detection order:
- `apt-get`
- `dnf`
- `yum`
- `pacman`
- `brew`

Command templates:
- apt: `sudo apt-get update && sudo apt-get install -y <pkg>`
- dnf: `sudo dnf install -y <pkg>`
- yum: `sudo yum install -y <pkg>`
- pacman: `sudo pacman -Sy --noconfirm <pkg>`
- brew: `brew install <pkg>`

## Failure handling
- Never loop installs.
- On unknown mapping, return `needs_mapping` with candidate names and stop.
- On permission issues, return `permission_denied` with next-step guidance.
- On network/repo issues, return `offline_or_repo_unreachable`.
- On failed verification after install, return `verification_failed`.

## Output contract
Return:
- `status`: one of `already_present`, `installed_local`, `installed_global`, `installed_system`, `cancelled_by_user`, `needs_mapping`, `permission_denied`, `offline_or_repo_unreachable`, `install_failed`, `verification_failed`.
- `classification`: `cli`, `system`, or `unknown`.
- `install_scope`: `local`, `global`, `system`, or `none`.
- `manager`: `mise`, `apt`, `dnf`, `yum`, `pacman`, `brew`, `nixos-config`, or `none`.
- `commands_attempted`: ordered list.
- `next_action`: short recommendation for caller.
