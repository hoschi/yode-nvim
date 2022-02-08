local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local createSeditor = require('yode-nvim.createSeditor')
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('createSeditor', function()
    it('create', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())

        vim.cmd('e ./testData/small.js')
        local fileBufferId = vim.fn.bufnr('%')

        local seditorBufferId = createSeditor({
            firstline = 4,
            lastline = 12,
        })

        tutil.assertBufferContentString(
            [[
export default async function () {
    return {
        relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
    }
}]],
            seditorBufferId
        )
        eq({
            seditors = {
                [seditorBufferId] = {
                    seditorBufferId = seditorBufferId,
                    fileBufferId = fileBufferId,
                    startLine = 3,
                    indentCount = 0,
                    zombie = nil,
                },
            },
            layout = { tabs = {} },
        }, store.getState())

        eq({
            [fileBufferId] = './testData/small.js',
            [seditorBufferId] = 'yode://./testData/small.js:2.js',
        }, tutil.getHumanBufferList())

        eq(fileBufferId, vim.fn.bufnr('%'))

        tutil.assertAccessorMap(vim.bo[seditorBufferId], {
            ft = 'javascript',
            buftype = 'acwrite',
            modified = false,
        })
    end)
end)
