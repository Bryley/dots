# dots

This is the repo containing my dotfiles and configurations for my computers,
both local, and remote.

## Experiments

`experiments/` contains projects created with heavy AI use and used as
experiments for scripts, plugins, and programs that assist my machine and
workflow. Each experiment is self-contained there; its configuration and
integration remain in `configs/`.

Experiments might be upgraded to their own repo and go through human review and
updates if they prove to be useful to me and potentially others.

## Installing

Boot into a Void Linux Live base glibc ISO and run these commands (you may need
internet):

 ```bash
xbps-install -Syu xbps curl ca-certificates
curl -fsSL https://raw.githubusercontent.com/Bryley/dots/main/install.sh -o /tmp/install.sh
bash /tmp/install.sh
 ```

That will take you through the automated installation process (no need to run
`void-installer`).

You will need to input root and user passwords as well as the name of the
machine, primary username and the disk to install too.

After if finishes you should be able to shutdown the computer, remove the disk
medium and then boot into the computer.


### Connecting to the WIFI

```sh
iwctl
```

While inside the IWD REPL:

```text
device list
```

You should see something like:

```text
wlan0
```

 If your device is powered off:

```text
device wlan0 set-property Powered on
adapter phy0 set-property Powered on
```

Scan connections:

```text
station wlan0 scan
```

Then list networks:

```text
station wlan0 get-networks
```

Connect:

```text
station wlan0 connect "Your WiFi Name"
```

Exit:

```text
exit
```

Now get an IP address:

 After connecting, run:

```sh
dhcpcd wlan0
```


## VPS setup

My VPS setup is using the following:

- Use Kamal for deploying different services
- Tailscale for easy private connections between machines.
- Cloudflare for easy domains (point `*.mydomain.com` to my homelab Tailscale IP).
- Cloudflare Zero Trust for public subdomains.
- Setting up the `bryley` user with all the CLI/TUI tools I use so I can SSH
  into the VPS home directory and do work on the go.
- Setting up the `deployer` user for use with deploying with Kamal.
