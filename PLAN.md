
# Plan

Here are plans and TODOs of upcomming things I want to explore/work on:

- [ ] Shared pi sessions - Already setup webDAV server on Tailscale for Obsidian but
   also can be used to share the sessions. Need to figure out a one way sync
   for computers I don't want to hook up to Tailscale.
- [ ] Pi harness pipelines - Want to explore and play around with a way to better
   my pi harness experience. A way to introduce a sub-agent like workflow so
   that the AI can decide to spawn mini agents to do certain tasks with fresh
   contexts. Then build out an extension that makes this easy to manage and
   view. Certain pipelines will be predefined, like building out prototypes or
   tests. Some might require dynamic pipelines like "plan my birthday" or
   researching or something. With this change I was also thinking about a folder
   structure like in my AGENTS md file I can instruct it to use `./.scratchpad`
   to put files like `TODO.md` or `PIPELINE.md` or any generated files like
   scripts, data dumping and more.
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
- [ ] Add a pi plugin that displays the time it took for a response
