return {
  cmd = { 'zls' },
  filetypes = { 'zig', 'zon' },
  root_markers = { 'build.zig', 'build.zig.zon', 'zls.json', '.git' },
  settings = {
    zls = {
      semantic_tokens = 'partial',
      enable_snippets = true,
      enable_argument_placeholders = true,
      completion_label_details = true,
      warn_style = true,
      enable_autofix = true,
    },
  },
}
