local M = {}

M.setup1 = function()
    vim.cmd([[
        e ./testData/basic.js
        3,9YodeCreateSeditorFloating
        wincmd h
        11,25YodeCreateSeditorFloating
        wincmd h
        49,58YodeCreateSeditorFloating
    ]])
end

M.setup2 = function()
    vim.cmd([[
        e ./testData/small.js
        4,12YodeCreateSeditorFloating
        wincmd h
    ]])
end

M.setup3 = function()
    local fileBuffer1, seditor1, seditor2, seditor3

    vim.cmd('e ./testData/basic.js')
    fileBuffer1 = vim.fn.bufnr('%')

    vim.cmd('3,9YodeCreateSeditorFloating')
    seditor1 = vim.fn.bufnr('%')
    vim.cmd('wincmd h')

    vim.cmd('11,25YodeCreateSeditorFloating')
    seditor2 = vim.fn.bufnr('%')
    vim.cmd('wincmd h')

    vim.cmd('49,58YodeCreateSeditorFloating')
    seditor3 = vim.fn.bufnr('%')
    vim.cmd('wincmd h')

    vim.cmd('tab split')
    vim.cmd('b ' .. seditor2)
    vim.cmd('YodeCloneCurrentIntoFloat')
    vim.cmd('b ' .. seditor1)
    vim.cmd('YodeCloneCurrentIntoFloat')
    vim.cmd('b ' .. fileBuffer1)
    vim.cmd('wincmd w')
end

return M
