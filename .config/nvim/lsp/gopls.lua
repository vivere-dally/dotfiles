return {
  settings = {
    gopls = {
      buildFlags = { '-tags=dev' }, -- Panomics specific
      gofumpt = true,
      staticcheck = true,
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        useany = true,
        nilness = true,
        -- shadow is owned by golangci-lint (govet shadow + err exclusion in
        -- per-repo .golangci.yml): gopls can't scope it per-variable, and
        -- idiomatic err shadowing should not be flagged.
        shadow = false,
      },
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
      codelenses = {
        gc_details = true,
        generate = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
      },
      semanticTokens = true,
      usePlaceholders = true,
      completeUnimported = true,
    },
  },
}
