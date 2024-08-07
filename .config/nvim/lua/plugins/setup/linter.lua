local ok, lint = pcall(require, 'lint')
if not ok then
    print('lint not installed')
    return
end

lint.linters_by_ft = {
    javascript = { "eslint_d" },
    typescript = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    typescriptreact = { "eslint_d" },
    svelte = { "eslint_d" },
    python = { "pylint" },
    php = { "phpstan", "php" },
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
    callback = function()
        lint.try_lint()
    end,
})

vim.keymap.set("n", "q", function()
    lint.try_lint()
end, { desc = "lint" })
