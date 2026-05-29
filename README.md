# dots

This is the repo containing my dotfiles and configurations for my computers,
both local, and remote.

## Installing

Boot into Void Linux Live ISO and run these commands:

 ```bash
xbps-install -Sy curl ca-certificates
curl -fsSL https://raw.githubusercontent.com/Bryley/dots/main/install.sh -o /tmp/install.sh
bash /tmp/install.sh

 ```

That will take you through the automated installation process (no need to run
`void-installer`).

You will need to insert root and user passwords as well as the name of the
machine and the disk to install too.

After if finishes you should be able to shutdown the computer, remove the disk
medium and then boot into the computer.

## VPS setup

My VPS setup is using the following:

- Use Kamal for deploying different services
- Tailscale for easy private connections between machines.
- Cloudflare for easy domains (point `*.mydomain.com` to my homelab Tailscale IP).
- Cloudflare Zero Trust for public subdomains.
- Setting up the `bryley` user with all the CLI/TUI tools I use so I can SSH
  into the VPS home directory and do work on the go.
- Setting up the `deployer` user for use with deploying with Kamal.
