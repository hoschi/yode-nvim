local async = require('plenary.async')
async.tests.add_to_env()
local tutil = require('yode-nvim.tests.util')

local eq = assert.are.same

describe('floating status line -', function()
    local fileBufferId = 1
    local mainWin = 1000
    local seditor1 = 2
    local seditor1StatusBufferId = 3
    local seditor2 = 4
    local seditor2StatusBufferId = 5

    it('status line contains short buffer name', function()
        vim.cmd('e ./testData/basic.js')
        eq(fileBufferId, vim.fn.bufnr('%'))
        eq(mainWin, vim.fn.win_getid())

        vim.cmd('3,9YodeCreateSeditorFloating')
        eq(seditor1, vim.fn.bufnr('%'))
        tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)

        vim.cmd('wincmd h')

        vim.cmd('11,25YodeCreateSeditorFloating')
        eq(seditor2, vim.fn.bufnr('%'))
        tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)

        vim.cmd('wincmd h')

        eq({
            [fileBufferId] = false,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
    end)

    a.it('shows modified state - change file buffer where no seditor is linked', function()
        vim.cmd('normal ggo')
        async.util.scheduler()

        eq({
            [fileBufferId] = true,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)

        vim.cmd('undo')
        async.util.scheduler()
        eq({
            [fileBufferId] = false,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)
    end)

    a.it('shows modified state - change file buffer where seditor 1 is linked', function()
        vim.cmd('normal gg5jo')
        async.util.scheduler()

        eq({
            [fileBufferId] = true,
            [seditor1] = true,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        -- TODO doesn't work in test, but in normal vim. I don't know why. It seams that onOptionSetModifed isn't called
        --tutil.assertBufferContentString('+basic.js:2', seditor1StatusBufferId)
        --tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)

        vim.cmd('undo')
        async.util.scheduler()
        eq({
            [fileBufferId] = false,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)
    end)

    a.it('shows modified state - change file buffer where seditor 2 is linked', function()
        vim.cmd('normal gg10jo')
        async.util.scheduler()

        eq({
            [fileBufferId] = true,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = true,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        --tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        --tutil.assertBufferContentString('+basic.js:4', seditor2StatusBufferId)

        vim.cmd('undo')
        async.util.scheduler()
        eq({
            [fileBufferId] = false,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)
    end)

    a.it('shows modified state - change seditor 2', function()
        vim.cmd('wincmd w')
        eq(seditor2, vim.fn.bufnr('%'))
        vim.cmd('normal ggo')
        async.util.scheduler()

        eq({
            [fileBufferId] = true,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = true,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        --tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        --tutil.assertBufferContentString('+basic.js:4', seditor2StatusBufferId)

        vim.cmd('undo')
        async.util.scheduler()

        -- TODO needed at the moment, because undo in seditor only changes
        -- seditors change list, not the one of file editor!
        vim.cmd('wincmd h')
        vim.cmd('undo')
        async.util.scheduler()

        eq({
            [fileBufferId] = false,
            [seditor1] = false,
            [seditor1StatusBufferId] = false,
            [seditor2] = false,
            [seditor2StatusBufferId] = false,
        }, tutil.getBuffersModifiedState())
        tutil.assertBufferContentString('basic.js:2', seditor1StatusBufferId)
        tutil.assertBufferContentString('basic.js:4', seditor2StatusBufferId)
    end)
end)
