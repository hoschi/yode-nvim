local tutil = require('yode-nvim.tests.util')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store

local eq = assert.are.same

describe('buffer delete', function()
    local smallBufId = 1
    local fileBufferId = 2
    local seditor1 = 3
    local seditor2 = 5

    it('1', function()
        vim.cmd('e ./testData/small.js')
        eq(smallBufId, vim.fn.bufnr('%'))

        vim.cmd('e ./testData/basic.js')
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('3,9YodeCreateSeditorFloating')
        eq(seditor1, vim.fn.bufnr('%'))

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('11,25YodeCreateSeditorFloating')
        eq(seditor2, vim.fn.bufnr('%'))

        eq({
            [smallBufId] = './testData/small.js',
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:3.js',
            [seditor2] = 'yode://./testData/basic.js:5.js',
        }, tutil.getHumanBufferList())
        eq(2, #store.getState().layout.tabs[1].windows)

        vim.cmd('YodeBufferDelete')
        eq({
            [smallBufId] = './testData/small.js',
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:3.js',
        }, tutil.getHumanBufferList())
        eq(1, #store.getState().layout.tabs[1].windows)
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('b ' .. seditor1)

        vim.cmd('YodeBufferDelete')
        eq({
            [smallBufId] = './testData/small.js',
            [fileBufferId] = './testData/basic.js',
        }, tutil.getHumanBufferList())
        eq(0, #store.getState().layout.tabs[1].windows)
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('YodeBufferDelete')
        eq({
            [smallBufId] = './testData/small.js',
        }, tutil.getHumanBufferList())
        eq(0, #store.getState().layout.tabs[1].windows)
        eq(smallBufId, vim.fn.bufnr('%'))
    end)
end)
