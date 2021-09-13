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

return M
