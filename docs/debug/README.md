# Project debug templates

Copy the applicable `.vscode` directory to the root of a project. Start Neovim from that project root.

`nvim-dap` reads `launch.json` when F5 starts a debug session. Overseer runs each task that `preLaunchTask` names.

- `go-project` debugs the Go package at the project root.
- `go-command` debugs `cmd/<project-directory-name>`.
- `odin` keeps the conditional debug build and the single-thread compiler flags.
- `zig` builds the project or the test binary before CodeLLDB starts.

The Zig project launch asks for the executable name below `zig-out/bin`. Replace the input with a fixed name for a repeated target.
