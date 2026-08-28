# Experiments

Projects created with heavy AI use and used to experiment with scripts, plugins, and programs that assist this machine and workflow.

- [`herdr-agents.nvim`](./herdr-agents.nvim/) — Neovim integration for Herdr-managed agents; loaded by `configs/nvim/lua/plugins/init.lua`.
- [`jump-ease.nvim`](./jump-ease.nvim/) — relative line-number movement aid; loaded by `configs/nvim/lua/plugins/init.lua`.
- [`subagent`](./subagent/) — Herdr-managed subagent command; its `bin/subagent` command is exposed automatically by Nushell, with profiles in `configs/subagent/`.

Nushell adds every `experiments/*/bin` directory to `PATH` at startup. Put executable commands in an experiment's `bin/` directory to expose them.

