local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('clone current into float', function()
    local fileBufferId = 1
    local seditorBufferId = 2
    local mainWin = 1000
    local floatWin = 1002

    it("can't float normal buffer", function()
        eq(mainWin, vim.fn.win_getid())
        vim.cmd('e ./testData/basic.js')
        vim.cmd('YodeCloneCurrentIntoFloat')
        eq(0, #store.getState().layout.tabs)
    end)

    it('from file editor', function()
        vim.cmd('3,9YodeCreateSeditorReplace')
        eq(seditorBufferId, vim.fn.bufnr('%'))
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq(0, #store.getState().layout.tabs)

        vim.cmd('YodeCloneCurrentIntoFloat')
        eq(mainWin, vim.fn.win_getid())
        eq(seditorBufferId, vim.fn.bufnr('%'))
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq(1, #store.getState().layout.tabs[1].windows)

        vim.cmd('YodeCloneCurrentIntoFloat')
        eq(mainWin, vim.fn.win_getid())
        eq(seditorBufferId, vim.fn.bufnr('%'))
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        -- can't float already floating window again
        eq(1, #store.getState().layout.tabs[1].windows)

        eq(floatWin, store.getState().layout.tabs[1].windows[1].id)
        eq(seditorBufferId, vim.api.nvim_win_get_buf(floatWin))
        vim.cmd('b ' .. fileBufferId)
        eq(fileBufferId, vim.api.nvim_win_get_buf(0))
        eq(seditorBufferId, vim.api.nvim_win_get_buf(floatWin))

        vim.cmd('wincmd w')
        eq(floatWin, vim.fn.win_getid())
        eq(seditorBufferId, vim.api.nvim_win_get_buf(0))
        eq(fileBufferId, vim.api.nvim_win_get_buf(mainWin))
    end)

    it('from already floating window, it does nothing', function()
        vim.cmd('YodeCloneCurrentIntoFloat')
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq(seditorBufferId, vim.api.nvim_win_get_buf(0))
        eq(fileBufferId, vim.api.nvim_win_get_buf(mainWin))
    end)
end)
