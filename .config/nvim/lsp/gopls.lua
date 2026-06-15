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
        shadow = true,
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
