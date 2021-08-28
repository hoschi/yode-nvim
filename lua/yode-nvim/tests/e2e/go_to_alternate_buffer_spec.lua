local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same
local eqn = assert.are_not.same

require('yode-nvim.init').setup()
describe('go to alternate buffer -', function()
    it('from seditor in full view to file buffer', function()
        vim.cmd('e ./testData/basic.js')
        local fileBufferId = 1

        vim.cmd('3,9YodeCreateSeditorReplace')
        local seditorBufferId = vim.fn.bufnr('%')

        eqn(seditorBufferId, fileBufferId)

        vim.cmd('e ./testData/small.js')
        local smallBufId = vim.fn.bufnr('%')

        eq({
            [fileBufferId] = 'testData/basic.js',
            [seditorBufferId] = 'yode://testData/basic.js:4.js',
            [smallBufId] = './testData/small.js',
        }, tutil.getHumanBufferList())

        vim.cmd('b ' .. seditorBufferId)
        vim.cmd('YodeGoToAlternateBuffer')
        eq(vim.fn.bufnr('%'), fileBufferId)
    end)
end)
