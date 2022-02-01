local async = require('plenary.async')
async.tests.add_to_env()
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tutil = require('yode-nvim.tests.util')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

describe('float to main window -', function()
    local fileBufferId = 1
    local mainWin = 1000
    local seditor1 = 2
    local seditor2 = 4
    local seditor1Win = 1002
    local seditor2Win = 1004

    it('setup', function()
        vim.cmd('e ./testData/basic.js')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq(mainWin, vim.fn.win_getid())

        vim.cmd('3,9YodeCreateSeditorFloating')
        eq(seditor1, vim.fn.bufnr('%'))

        vim.cmd('wincmd h')

        vim.cmd('11,25YodeCreateSeditorFloating')
        eq(seditor2, vim.fn.bufnr('%'))

        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                {
                    y = 1,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    data = { visible = true },
                },
                {
                    y = 17,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)

    it('ignore try to move main window itself', function()
        vim.cmd('wincmd h')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq(mainWin, vim.fn.win_getid())

        vim.cmd('YodeFloatToMainWindow')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq(mainWin, vim.fn.win_getid())
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                {
                    y = 1,
                    height = 15,
                    id = seditor2Win,
                    bufId = seditor2,
                    data = { visible = true },
                },
                {
                    y = 17,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)

    a.it('move seditor2 to main window', function()
        vim.cmd('wincmd w')
        eq(seditor2, vim.fn.bufnr('%'))
        eq(seditor2Win, vim.fn.win_getid())

        vim.cmd('YodeFloatToMainWindow')
        async.util.scheduler()
        eq(mainWin, vim.fn.win_getid())
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                {
                    y = 1,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)

    it('ignore try to move seditor in main window', function()
        eq(seditor2, vim.fn.bufnr('%'))
        eq(mainWin, vim.fn.win_getid())

        vim.cmd('YodeFloatToMainWindow')
        eq({
            [fileBufferId] = './testData/basic.js',
            [seditor1] = 'yode://./testData/basic.js:2.js',
            [seditor2] = 'yode://./testData/basic.js:4.js',
        }, tutil.getHumanBufferList())
        eq(
            {
                {
                    y = 1,
                    height = 7,
                    id = seditor1Win,
                    bufId = seditor1,
                    data = { visible = true },
                },
            },
            h.map(
                R.pick({ 'id', 'data', 'height', 'y', 'bufId' }),
                store.getState().layout.tabs[1].windows
            )
        )
    end)
end)
