local yodeNvim = require('yode-nvim.init')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local createSeditor = require('yode-nvim.createSeditor')
local h = require('yode-nvim.helper')
local tutil = require('yode-nvim.tests.util')
local R = require('yode-nvim.deps.lamda.dist.lamda')

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

require('yode-nvim.init').setup()
describe('seditor sync to file editor sync', function()
    it('1', function()
        eq({ seditors = {} }, store.getState())
        local fileBufferId = vim.fn.bufnr('%')

        vim.cmd('e ./testData/small.js')

        local seditorBufferId, win = createSeditor({
            fileBufferId = fileBufferId,
            text = textTopLevelNode,
            windowY = 0,
            windowHeight = #textTopLevelNode,
            startLine = 3,
        })

        eq({
            [fileBufferId] = 'testData/small.js',
            [seditorBufferId] = 'yode://testData/small.js:4.js',
        }, tutil.getHumanBufferList())

        eq(vim.fn.bufnr('%'), seditorBufferId)
        vim.api.nvim_feedkeys('jjItest_', 'x', false)

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

        eq(vim.fn.bufnr('%'), fileBufferId)
        -- TODO doesn't work, I don't know what is the problem
        --tutil.assertBufferContentString([[
        --/**
        --* My super function!
        --*/
        --export default async function () {
        --return {
        --test_relative:
        --'editor' +
        --'fooooooooooooooooooo' +
        --'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
        --'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
        --}
        --}

        --//
        --//
        --//
        --//
        --//
        --//
        --//
        --//
        --//
        --//
        --//

        --// foo]])
    end)
end)
