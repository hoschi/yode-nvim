local async = require('plenary.async')
async.tests.add_to_env()
local yodeNvim = require('yode-nvim.init')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local createSeditor = require('yode-nvim.createSeditor')
local h = require('yode-nvim.helper')
local tutil = require('yode-nvim.tests.util')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

describe('seditor sync to file editor sync', function()
    a.it('1', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())
        vim.cmd('e ./testData/small.js')
        local fileBufferId = vim.fn.bufnr('%')

        vim.cmd('4,12YodeCreateSeditorFloating')
        local seditorBufferId = vim.fn.bufnr('%')

        eq({
            [fileBufferId] = './testData/small.js',
            [seditorBufferId] = 'yode://./testData/small.js:2.js',
        }, tutil.getHumanBufferList())

        vim.cmd('normal jjItest_')
        async.util.scheduler()

        tutil.assertBufferContentString([[
export default async function () {
    return {
        test_relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
    }
}]])
        vim.cmd('wincmd h')

        eq(fileBufferId, vim.fn.bufnr('%'))
        tutil.assertBufferContentString([[
/**
 * My super function!
 */
export default async function () {
    return {
        test_relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
    }
}

//
//
//
//
//
//
//
//
//
//
//

// foo]])
    end)
end)
