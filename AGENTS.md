# Experiments

`experiments/` contains projects created with heavy AI use and treated as experiments for scripts, plugins, and programs that assist this machine and workflow. Keep each experiment self-contained there; keep only its configuration or integration in `configs/`.

# Portability

This configuration is shared between macOS and Linux. Solutions must work generally on both platforms; never implement a macOS-only or Linux-only approach. Avoid complex operating-system conditionals. If platform-specific branching is the only practical solution, ask the user whether they want that approach before implementing it.
