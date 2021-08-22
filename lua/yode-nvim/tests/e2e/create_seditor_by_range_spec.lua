local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

require('yode-nvim.init').setup()
describe('create seditor', function()
    it('floating', function()
        eq({ seditors = {} }, store.getState())

        vim.cmd('e ./testData/basic.js')
        local fileBufferId = 1

        vim.cmd('49,58YodeCreateSeditorFloating')

        tutil.assertBufferContentString([[
plugin.registerCommand(
    'YodeCreateSeditor',
    async () => {
        await createSeditor(nvim, '1111', 0, 20 == 50)

        await createSeditor(nvim, '2222', 21, 10)
        await createSeditor(nvim, '3333', 32, 15)
    },
    { sync: false }
)]])
        local seditorBufferId = vim.fn.bufnr('%')

        eq({
            [fileBufferId] = 'testData/basic.js',
            [seditorBufferId] = 'yode://testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq({
            seditors = {
                [seditorBufferId] = {
                    seditorBufferId = seditorBufferId,
                    fileBufferId = fileBufferId,
                    visible = true,
                    startLine = 48,
                    indentCount = 4,
                },
            },
        }, store.getState())

        vim.cmd('wincmd h')
        eq(vim.fn.bufnr('%'), fileBufferId)
    end)

    it('replace', function()
        local fileBufferId = vim.fn.bufnr('%')
        eq({
            [fileBufferId] = 'testData/basic.js',
            [4] = 'yode://testData/basic.js:4.js',
        }, tutil.getHumanBufferList())

        vim.cmd('3,9YodeCreateSeditorReplace')

        tutil.assertBufferContentString([[
const getSeditorWidth = async (nvim) => {
    if (!mainWindowWidth) {
        mainWindowWidth = Math.floor((await nvim.getOption('columns')) / 2)
    }

    return mainWindowWidth
}]])
        local seditorBufferId = vim.fn.bufnr('%')

        eq({
            [fileBufferId] = 'testData/basic.js',
            [4] = 'yode://testData/basic.js:4.js',
            [seditorBufferId] = 'yode://testData/basic.js:5.js',
        }, tutil.getHumanBufferList())
        eq({
            seditors = {
                [4] = {
                    seditorBufferId = 4,
                    fileBufferId = fileBufferId,
                    visible = true,
                    startLine = 48,
                    indentCount = 4,
                },
                [seditorBufferId] = {
                    seditorBufferId = seditorBufferId,
                    fileBufferId = fileBufferId,
                    visible = true,
                    startLine = 2,
                    indentCount = 0,
                },
            },
        }, store.getState())
    end)
end)
