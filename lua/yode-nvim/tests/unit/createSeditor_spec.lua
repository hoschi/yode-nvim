local yodeNvim = require('yode-nvim.init')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local createSeditor = require('yode-nvim.createSeditor')
local h = require('yode-nvim.helper')
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same
local textTopLevelNode = h.multiLineTextToArray([[
    export default async function () {
        return {
            relative:
                'editor' +
                'fooooooooooooooooooo' +
                'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
                'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
        }
    }
]])

describe('createSeditor', function()
    it('create', function()
        eq({ seditors = {} }, store.getState())
        local fileBufferId = vim.fn.bufnr('%')

        vim.cmd('e ./testData/small.js')

        local seditorBufferId, winId = createSeditor({
            fileBufferId = fileBufferId,
            text = textTopLevelNode,
            windowY = 0,
            windowHeight = #textTopLevelNode,
            startLine = 3,
        })

        eq({
            seditors = {
                [seditorBufferId] = {
                    seditorBufferId = seditorBufferId,
                    fileBufferId = fileBufferId,
                    visible = true,
                    startLine = 3,
                    indentCount = 4,
                },
            },
        }, store.getState())

        eq(seditorBufferId, vim.fn.bufnr('%'))
        tutil.assertAccessorMap(vim.bo, {
            ft = 'javascript',
            buftype = 'acwrite',
            modified = false,
        })
        tutil.assertAccessorMap(vim.wo[winId], { wrap = false })
        eq('yode://./testData/small.js:2.js', vim.fn.bufname('%'))
    end)
end)
