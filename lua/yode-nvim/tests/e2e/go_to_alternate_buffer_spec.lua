local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('go to alternate buffer -', function()
    local fileBufferId = 1
    local seditorBufferId = 2
    local smallBufId = 3

    it('from seditor in full view to file buffer', function()
        vim.cmd('e ./testData/basic.js')

        vim.cmd('YodeGoToAlternateBuffer')
        -- does nothing on file buffer
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('11,25YodeCreateSeditorReplace')
        eq(seditorBufferId, vim.fn.bufnr('%'))

        vim.cmd('e ./testData/small.js')
        eq(smallBufId, vim.fn.bufnr('%'))

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
            [smallBufId] = './testData/small.js',
        }, tutil.getHumanBufferList())

        vim.cmd('b ' .. seditorBufferId)
        vim.cmd('YodeGoToAlternateBuffer')
        eq(fileBufferId, vim.fn.bufnr('%'))
    end)

    it('change cursor on switch', function()
        vim.cmd('b ' .. fileBufferId)
        vim.api.nvim_feedkeys('G^', 'x', false)
        eq({ 81, 0 }, vim.api.nvim_win_get_cursor(0))

        vim.cmd('b ' .. smallBufId)
        vim.cmd('b ' .. seditorBufferId)

        vim.cmd('YodeGoToAlternateBuffer t')
        eq(fileBufferId, vim.fn.bufnr('%'))
        -- TODO assert for viewport when we use a test system that supports
        -- this
        eq({ 11, 0 }, vim.api.nvim_win_get_cursor(0))

        vim.cmd('b ' .. fileBufferId)
        vim.api.nvim_feedkeys('gg^', 'x', false)
        eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0))
        vim.cmd('49,58YodeCreateSeditorReplace')
        local seditorBottom = vim.fn.bufnr('%')

        vim.cmd('b ' .. smallBufId)
        vim.cmd('b ' .. seditorBottom)

        vim.cmd('YodeGoToAlternateBuffer z')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq({ 49, 4 }, vim.api.nvim_win_get_cursor(0))

        vim.cmd('b ' .. fileBufferId)
        vim.api.nvim_feedkeys('gg^', 'x', false)
        eq({ 1, 0 }, vim.api.nvim_win_get_cursor(0))

        vim.cmd('b ' .. smallBufId)
        vim.cmd('b ' .. seditorBottom)

        vim.cmd('YodeGoToAlternateBuffer b')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq({ 49, 4 }, vim.api.nvim_win_get_cursor(0))
    end)
end)
