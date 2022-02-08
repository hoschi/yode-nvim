local async = require('plenary.async')
async.tests.add_to_env()
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('seditor to file editor sync -', function()
    local fileBufferId = 1
    local seditor1 = 2
    local seditor2 = 4

    a.it('one seditor', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())
        vim.cmd('e ./testData/small.js')
        eq(fileBufferId, vim.fn.bufnr('%'))

        vim.cmd('4,12YodeCreateSeditorFloating')
        eq(seditor1, vim.fn.bufnr('%'))

        eq({
            [fileBufferId] = './testData/small.js',
            [seditor1] = 'yode://./testData/small.js:2.js',
        }, tutil.getHumanBufferList())
        eq({
            [seditor1] = {
                seditorBufferId = seditor1,
                fileBufferId = fileBufferId,
                startLine = 3,
                indentCount = 0,
                zombie = nil,
            },
        }, store.getState().seditors)

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

    a.it('add second seditor above', function()
        vim.cmd('1,2YodeCreateSeditorFloating')
        eq(seditor2, vim.fn.bufnr('%'))
        eq({
            [seditor1] = {
                seditorBufferId = seditor1,
                fileBufferId = fileBufferId,
                startLine = 3,
                indentCount = 0,
                zombie = nil,
            },
            [seditor2] = {
                seditorBufferId = seditor2,
                fileBufferId = fileBufferId,
                startLine = 0,
                indentCount = 0,
                zombie = nil,
            },
        }, store.getState().seditors)

        tutil.assertBufferContentString([[
/**
 * My super function!]])

        vim.cmd('normal O// start of file')
        async.util.scheduler()

        tutil.assertBufferContentString([[
// start of file
/**
 * My super function!]])
        eq({
            [seditor1] = {
                seditorBufferId = seditor1,
                fileBufferId = fileBufferId,
                startLine = 4,
                indentCount = 0,
                zombie = nil,
            },
            [seditor2] = {
                seditorBufferId = seditor2,
                fileBufferId = fileBufferId,
                startLine = 0,
                indentCount = 0,
                zombie = nil,
            },
        }, store.getState().seditors)
    end)
end)
