local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('create seditor', function()
    it('floating', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())

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
            [fileBufferId] = './testData/basic.js',
            [seditorBufferId] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq({
            [seditorBufferId] = {
                seditorBufferId = seditorBufferId,
                fileBufferId = fileBufferId,
                startLine = 48,
                indentCount = 4,
            },
        }, store.getState().seditors)
        eq(1, #store.getState().layout.tabs[1].windows)
        tutil.assertAccessorMap(vim.wo, { wrap = false })

        vim.cmd('wincmd h')
        eq(vim.fn.bufnr('%'), fileBufferId)
    end)

    it('replace', function()
        local fileBufferId = vim.fn.bufnr('%')
        eq({
            [fileBufferId] = './testData/basic.js',
            [2] = 'yode://./testData/basic.js:2.js',
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
            [fileBufferId] = './testData/basic.js',
            [2] = 'yode://./testData/basic.js:2.js',
            [seditorBufferId] = 'yode://./testData/basic.js:3.js',
        }, tutil.getHumanBufferList())
        eq({
            [2] = {
                seditorBufferId = 2,
                fileBufferId = fileBufferId,
                startLine = 48,
                indentCount = 4,
            },
            [seditorBufferId] = {
                seditorBufferId = seditorBufferId,
                fileBufferId = fileBufferId,
                startLine = 2,
                indentCount = 0,
            },
        }, store.getState().seditors)
        eq(1, #store.getState().layout.tabs[1].windows)
        tutil.assertAccessorMap(vim.wo, { wrap = true })
    end)
end)
