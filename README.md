# dots

This is the repo containing my dotfiles and configurations for my computers,
both local, and remote.

## Installing

A basic install script is located at `./install.sh`. Simply run that on the
computer you want to set up. It should work for both Ubuntu (VPS) and Fedora
(Local).

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
