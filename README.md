# dots

This is the repo containing my dotfiles and configurations for my computers,
both local, and remote.

## Installing

1. Clone the repo with `git clone https://github.com/Bryley/dots.git`
2. Run `sudo ./install.sh` script inside the directory.
3. It will print out a public key, put that on your GitHub account.
4. Update the remote of the dots repo.
5. Clone additional notes and setup anything else you might need.

## VPS setup

My VPS setup is using the following:

- Dokploy for deploying applications/cronjobs etc.
- Tailscale for easy private connections between machines.
- Cloudflare for easy domains (point `*.mydomain.com` to my homelab Tailscale IP).
- Cloudflare Zero Trust for public subdomains.
- Setting up the `bryley` user with all the CLI/TUI tools I use so I can SSH
  into the VPS home directory and do work on the go.
- OpenCode server running on `/home/bryley/` to have strong AI on the go.
- OpenChamber instance is hosted in Dokploy that points to the OpenCode for
  better web interface
