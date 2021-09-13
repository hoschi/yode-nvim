local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')

local eq = assert.are.same

describe('basic mosaic layout', function()
    local fileBufferId = 1
    local seditor1 = 2
    local seditor2 = 3
    local seditor3 = 4

    it('create floating seditors', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())

        vim.cmd('e ./testData/basic.js')

        -- seditor 1
        vim.cmd('3,9YodeCreateSeditorFloating')

        tutil.assertBufferContentString([[
const getSeditorWidth = async (nvim) => {
    if (!mainWindowWidth) {
        mainWindowWidth = Math.floor((await nvim.getOption('columns')) / 2)
    }

    return mainWindowWidth
}]])

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
        }, tutil.getHumanBufferList())
        eq({
            config = {},
            data = {},
            name = 'mosaic',
        }, R.omit(
            { 'windows' },
            store.getState().layout.tabs[1]
        ))
        eq(
            { { y = 0, height = 7, id = 1002, relative = 'editor', data = { visible = true } } },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y' }),
                store.getState().layout.tabs[1].windows
            )
        )

        vim.cmd('wincmd h')
        eq(vim.fn.bufnr('%'), fileBufferId)

        -- seditor 2
        vim.cmd('11,25YodeCreateSeditorFloating')

        tutil.assertBufferContentString([[
async function createSeditor(nvim, text, row, height) {
    const buffer = await nvim.createBuffer(false, false)

    const foo = 'bar'
    const width = await getSeditorWidth(nvim)
    const window = await nvim.openWindow(buffer, true, {
        relative: 'editor',
        row,
        col: width,
        width,
        height: height,
        focusable: true,
    })
    return window
}]])

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                { y = 0, height = 15, id = 1003, relative = 'editor', data = { visible = true } },
                { y = 16, height = 7, id = 1002, relative = 'editor', data = { visible = true } },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y' }),
                store.getState().layout.tabs[1].windows
            )
        )

        vim.cmd('wincmd h')
        eq(vim.fn.bufnr('%'), fileBufferId)

        -- seditor 3
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

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
            [seditor3] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                { y = 0, height = 10, id = 1004, relative = 'editor', data = { visible = true } },
                { y = 11, height = 15, id = 1003, relative = 'editor', data = { visible = true } },
                { y = 27, height = 7, id = 1002, relative = 'editor', data = { visible = true } },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)

    it('delete floating buffer', function()
        vim.cmd('bd')
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:3.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                { y = 0, height = 15, id = 1003, relative = 'editor', data = { visible = true } },
                { y = 16, height = 7, id = 1002, relative = 'editor', data = { visible = true } },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)
end)
