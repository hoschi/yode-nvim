local async = require('plenary.async')
async.tests.add_to_env()
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('run in file command', function()
    local fileBufferId = 1
    local seditorBufferId = 2
    local fileLinesBase = 81
    local fileLinesWithout = fileLinesBase - 1

    a.it('- delete some lines', function()
        vim.cmd('e ./testData/basic.js')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq(fileLinesBase, #vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))

        vim.cmd('11,25YodeCreateSeditorFloating')
        eq(seditorBufferId, vim.fn.bufnr('%'))
        tutil.assertBufferContentString(
            [[
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
}]],
            seditorBufferId
        )

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())

        vim.cmd('YodeRunInFile normal gg12jdd')
        async.util.scheduler()

        eq(seditorBufferId, vim.fn.bufnr('%'))
        eq(fileLinesWithout, #vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        tutil.assertBufferContentString(
            [[
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
}]],
            seditorBufferId
        )
    end)
end)
