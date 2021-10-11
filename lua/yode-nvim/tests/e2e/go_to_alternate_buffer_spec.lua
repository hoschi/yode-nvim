local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('go to alternate buffer -', function()
    local fileBufferId = 1
    local seditorBufferId = 2
    local smallBufId = 3

    it('from seditor in full view to file buffer', function()
        vim.cmd('e ./testData/basic.js')
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('3,9YodeCreateSeditorReplace')
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
    end)
end)
