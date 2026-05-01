
# Plan

Here are plans and TODOs of upcomming things I want to explore/work on:

- [ ] Shared pi sessions - Already setup webDAV server on Tailscale for Obsidian but
   also can be used to share the sessions. Need to figure out a one way sync
   for computers I don't want to hook up to Tailscale.
- [ ] Self-hosted Pi UI/access - I need a way to interact with pi on the go, on my
   phone or on my web browser. Will need to explore the best way to do this. Can
   either just create/hookup a telegram bot or even use AI to help me create my
   own UI, maybe using Dioxus for fun. Depends how much time I want to spend on
   it. Would love a talk/answer phone call like interaction with it for hands
   free AI discussion.
- [ ] Migrate from NixOS to Fedora - I am currently using NixOS on my personal 
   laptop and I have been planning on migrating to Fedora. Love the Nix
   ecosystem however I find I spend too much time toying around rather than getting
   actual work done just for something simple like getting a package working on
   my system. This repo is meant to be a more "distro-less" solution to what I
   like most about Nix, which is how it is very declarative. Along with this I
   also want to migrate a few of the applications I use, eg. Kitty to Ghostty and
   Zen browser to Helium.
- [X] Try out MangoWM - I currently use Niri and like it but I have been hearing
   good things about Mango window manager. Thought I would give it a try. I also
   have to use Mac for work and would love to get a setup that can closer mimics
   my AreoSpace setup over there.
- [ ] Clean up my Neovim upgrading to 0.12 - Neovim 0.12 is out and looks really
   good, it has been a while since I redid my config. This is why I want to go
   though my entire config and pruning old plugins I no longer use and swap out
   plugins with possibly more modern better performing ones. Like `nvim-cmp` to
   blink, possibly swapping out Telescope with `tv.nvim` and `television`,
   `lazy.nvim` with the native plugin manager, update the LSP configs to make
   them cleaner and so on.
- [X] Aerospace
    - [X] Look into getting rounded corners working again on Ghostty terminal
    - [X] Keybind to switch monitors
    - [X] Make each monitor have their own set of workspaces (Not supported)
- [ ] Pi updates
    - [ ] Look into creating PR for altering tool call look globally
    - [ ] Fix constant update available message
    - [ ] Finish up `delegate` tool calling (Just need to add a few small visual
       changes and add command to view details/logs for a run)
        - [X] Add token + cost count
        - [ ] Add read log command
        - [ ] Consider structured delegate task packets to keep delegation flat,
           explicit, and non-persona based, put task details in user message yet
           add extra system message with policy and how to follow the user
           message:
            ```ts
            delegate({
              id, // kebab-case task id
              power, // light | versatile | powerful model/cost class
              input: {
                goal, // concrete task to complete
                context?, // background/assumptions/design intent
                preloadedSkills?, // skills to load before starting; worker may load more
                fileHints?, // suggested files/dirs to inspect, not a hard sandbox
              },
              policy?: {
                canWrite?, // true | false (setting to false should still allows edits inside the scratchpad or within temp folders) (defaults to false)
              },
              output: {
                contract, // expected return format/evidence/summary shape
              },
            })
            ```
    - [ ] Create pipeline extension (move away from skill and make it more
       deterministic)
    - [ ] Add a pi plugin that displays the time it took for a response
