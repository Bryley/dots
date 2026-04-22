# dots

This is the repo containing my dotfiles and configurations for my computers,
both local, and remote.

## Installing

1. Clone the repo with `git clone https://github.com/Bryley/dots.git`
2. `cd dots` into the directory and then run `sudo ./install.sh`
3. The script will:
   - detect distro and run the matching script in `scripts/distros/` for packages only
   - run shared user setup (dotfiles, mise, shell)
   - ask whether to run VPS setup (`scripts/vps.sh`)
4. Optional (from your host machine): run `scripts/bootstrap-remote-ssh.sh user@host`
   - adds your local public key to remote `authorized_keys`
   - hardens OpenSSH (disable password auth + root SSH login)
5. Update the remote of the dots repo.
6. Clone additional notes and setup anything else you might need.

## VPS setup

My VPS setup is using the following:

- Use Kamal for deploying different services
- Tailscale for easy private connections between machines.
- Cloudflare for easy domains (point `*.mydomain.com` to my homelab Tailscale IP).
- Cloudflare Zero Trust for public subdomains.
- Setting up the `bryley` user with all the CLI/TUI tools I use so I can SSH
  into the VPS home directory and do work on the go.
- Setting up the `deployer` user for use with deploying with Kamal.
