local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')
local layout = storeBundle.layout

local eq = assert.are.same

describe('basic mosaic layout', function()
    local fileBufferId = 1
    local seditor1 = 2
    local seditor2 = 3
    local seditor3 = 4
    local seditor1Win = 1002
    local seditor2Win = 1003
    local seditor3Win = 1004

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
            {
                {
                    y = 0,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))

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
                {
                    y = 0,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 16,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )

        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))

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
                {
                    y = 0,
                    height = 10,
                    id = seditor3Win,
                    bufId = seditor3,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 11,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 27,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)

    it('selecting window by some id works', function()
        eq(
            {
                id = seditor1Win,
                bufId = seditor1,
            },
            R.pick(
                { 'id', 'bufId' },
                layout.selectors.getWindowBySomeId(vim.api.nvim_tabpage_get_number(0), {
                    bufId = seditor1,
                })
            )
        )

        eq(
            {
                id = seditor1Win,
                bufId = seditor1,
            },
            R.pick(
                { 'id', 'bufId' },
                layout.selectors.getWindowBySomeId(vim.api.nvim_tabpage_get_number(0), {
                    winId = seditor1Win,
                })
            )
        )
    end)

    it("can't switch buffer to non seditor buffer in floating window", function()
        eq(seditor3Win, vim.fn.win_getid())
        eq(seditor3, vim.fn.bufnr('%'))

        vim.cmd('b ' .. fileBufferId)
        eq(seditor3Win, vim.fn.win_getid())
        eq(seditor3, vim.fn.bufnr('%'))
    end)

    it('shifting windows', function()
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 11,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 27,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinDown')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 16,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 27,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinDown')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 16,
                height = 7,
                id = seditor1Win,
            },
            {
                y = 24,
                height = 10,
                id = seditor3Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinTop')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 11,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 27,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinBottom')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 16,
                height = 7,
                id = seditor1Win,
            },
            {
                y = 24,
                height = 10,
                id = seditor3Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinUp')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 16,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 27,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinUp')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 11,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 27,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinUp')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 16,
                height = 7,
                id = seditor1Win,
            },
            {
                y = 24,
                height = 10,
                id = seditor3Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))

        vim.cmd('YodeLayoutShiftWinDown')
        eq(seditor3Win, vim.fn.win_getid())
        eq({
            {
                y = 0,
                height = 10,
                id = seditor3Win,
            },
            {
                y = 11,
                height = 15,
                id = seditor2Win,
            },
            {
                y = 27,
                height = 7,
                id = seditor1Win,
            },
        }, h.map(
            R.pick({ 'y', 'height', 'id' }),
            store.getState().layout.tabs[1].windows
        ))
    end)

    it('changing content height, changes layout', function()
        -- TODO not possible to test atm
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
                {
                    y = 0,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    relative = 'editor',
                    data = { visible = true },
                },
                {
                    y = 16,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    relative = 'editor',
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'relative', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)
end)
