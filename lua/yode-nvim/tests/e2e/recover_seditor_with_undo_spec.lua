local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

local seditorText = [[
async function createSeditor(nvim, text, row, height) {
    const buffer = await nvim.createBuffer(false, false)

    const foo = 'bar'
    const width = await getSeditorWidth(nvim)
    const window = await nvim.openWindow(buffer, true, {
        relative: 'editor',
        row,
        col: width,
        width,
        height: height,
        focusable: true,
    })
    return window
}]]

describe('recover seditor with undo', function()
    local fileBufferId = 1
    local seditorBufferId = 2
    local fileLinesBase = 81
    local fileLinesWithout = fileLinesBase - 16

    it('- deleting seditor', function()
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
                zombie = nil,
            },
        }, store.getState().seditors)
        eq(1, #store.getState().layout.tabs[1].windows)

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('normal gg10j16dd')
        eq(fileLinesWithout, #vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))
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
                zombie = {
                    countdown = 10,
                    text = seditorText,
                },
            },
        }, store.getState().seditors)
        eq(vim.bo[seditorBufferId].modifiable, false)

        vim.cmd('undo')
        eq(fileLinesBase, #vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))

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
                zombie = nil,
            },
        }, store.getState().seditors)
        eq(vim.bo[seditorBufferId].modifiable, true)
    end)
end)
