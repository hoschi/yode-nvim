local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('recover seditor with undo', function()
    local fileBufferId = 1
    local seditorBufferId = 2
    local fileLinesBase = 81
    local fileLinesWithout = fileLinesBase - 16

    -- TODO waiting for https://github.com/nvim-lua/plenary.nvim/issues/271
    pending('- deleting seditor', function()
        vim.cmd('e ./testData/basic.js')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq(fileLinesBase, #vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))

        vim.cmd('11,25YodeCreateSeditorFloating')
        eq(seditorBufferId, vim.fn.bufnr('%'))

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq({
            [seditorBufferId] = {
                seditorBufferId = seditorBufferId,
                fileBufferId = fileBufferId,
                startLine = 10,
                indentCount = 0,
                isZombie = false,
            },
        }, store.getState().seditors)
        eq(1, #store.getState().layout.tabs[1].windows)

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))
        vim.cmd('normal gg10j16dd')
        eq(fileLinesWithout, #vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))

        --eq({
        --[fileBufferId] = './testData/basic.js',
        --}, tutil.getHumanBufferList())
        --eq({}, store.getState().seditors)
        --eq(1, #store.getState().layout.tabs[1].windows)
    end)
end)
