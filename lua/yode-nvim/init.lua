local defaultConfig = require('yode-nvim.defaultConfig')
local logging = require('yode-nvim.logging')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local layout = storeBundle.layout
local createSeditor = require('yode-nvim.createSeditor')
local changeSyncing = require('yode-nvim.changeSyncing')
local testSetup = require('yode-nvim.testSetup')

local M = {
    config = {},
}

local lastTabId = 1

M.setup = function(options)
    M.config = vim.tbl_deep_extend('force', defaultConfig, options or {})
    logging.setup(M.config.log)
end

M.yodeNvim = function()
    local log = logging.create('yodeNvim')
    testSetup.setup1()
    --testSetup.setup2()
    --testSetup.setup3()

    vim.cmd([[
        wincmd w
        wincmd w
        normal ggjjjj
    ]])
    --vim.cmd('wincmd h')
    --vim.cmd('tabnew')
    --vim.cmd('normal G')
    --vim.cmd('normal gg10j16dd')
    --vim.cmd('normal gg48j10dd')
    --vim.cmd('normal gg15j8J')
end

M.yodeTesting = function()
    local log = logging.create('yodeTesting')
    local buf = vim.fn.bufnr('%')
    log.debug('!!!!!!!!!!', buf)
end

M.createSeditorFloating = function(firstline, lastline)
    local log = logging.create('createSeditorFloating')
    log.debug(
        string.format(
            'firstline %d to lastline %d (count: %d)',
            firstline,
            lastline,
            lastline - firstline
        )
    )

    local seditorBufferId = createSeditor({
        firstline = firstline,
        lastline = lastline,
    })
    layout.actions.createFloatingWindow({
        tabId = vim.api.nvim_get_current_tabpage(),
        bufId = seditorBufferId,
        data = {},
    })
end

M.createSeditorReplace = function(firstline, lastline)
    local log = logging.create('createSeditorReplace')
    log.debug(
        string.format(
            'firstline %d to lastline %d (count: %d)',
            firstline,
            lastline,
            lastline - firstline
        )
    )

    local seditorBufferId = createSeditor({
        firstline = firstline,
        lastline = lastline,
    })
    vim.cmd('b ' .. seditorBufferId)
end

M.goToAlternateBuffer = function(viewportFocusIndicator)
    local cursor, setCursor
    local log = logging.create('goToAlternateBuffer')
    log.debug('viewportFocusIndicator', viewportFocusIndicator)
    local bufId = vim.fn.bufnr('%')
    local sed = seditors.selectors.getSeditorById(bufId)

    if sed == nil then
        log.debug('no seditor found for ' .. bufId)
        return
    end

    cursor = vim.api.nvim_win_get_cursor(0)
    setCursor = function()
        vim.api.nvim_win_set_cursor(0, { cursor[1] + sed.startLine, cursor[2] + sed.indentCount })
    end
    -- TODO only do this when not in floating window. When in float, open file
    -- buffer in main area?!
    vim.cmd('b ' .. sed.fileBufferId)

    if viewportFocusIndicator == 'z' then
        setCursor()
        vim.cmd('normal zz')
    elseif viewportFocusIndicator == 't' then
        vim.api.nvim_win_set_cursor(0, { sed.startLine + 1, 0 })
        vim.cmd('normal zt')
        setCursor()
    elseif viewportFocusIndicator == 'b' then
        vim.api.nvim_win_set_cursor(
            0,
            { sed.startLine + #vim.api.nvim_buf_get_lines(bufId, 0, -1, true), 0 }
        )
        vim.cmd('normal zb')
        setCursor()
    end
end

M.cloneCurrentIntoFloat = function()
    local log = logging.create('cloneCurrentIntoFloat')
    local bufId = vim.fn.bufnr('%')
    local winId = vim.fn.win_getid()
    local config = vim.api.nvim_win_get_config(0)

    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { bufId = bufId }
    )
    if floatWin then
        log.warn('buffer is already visible as floating window!')
        return
    end

    local sed = seditors.selectors.getSeditorById(bufId)
    if sed == nil then
        log.debug('no seditor. Can only float seditors, aborting', winId, bufId)
        return
    end
    log.debug('cloning to float:', winId, bufId)
    layout.actions.createFloatingWindow({
        tabId = vim.api.nvim_get_current_tabpage(),
        bufId = bufId,
        data = {},
    })
    vim.fn.win_gotoid(winId)
end

M.bufferDelete = function()
    local log = logging.create('bufferDelete')
    local winId = vim.fn.win_getid()
    local bufId = vim.fn.bufnr('%')
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { winId = winId }
    )

    if floatWin then
        log.debug('deleting floating window', bufId, winId)
        vim.cmd('bd')
        return
    end

    local sed = seditors.selectors.getSeditorById(bufId)
    if sed then
        log.debug('deleting seditor buffer and show file buffer', bufId, winId, sed.fileBufferId)
        vim.cmd('YodeGoToAlternateBuffer t')
        vim.cmd('bd ' .. bufId)
        return
    end

    vim.cmd('bd')
end

M.onWindowClosed = function(winId)
    local log = logging.create('onWindowClosed')
    log.debug(winId)
    layout.actions.removeFloatingWindow({
        tabId = vim.api.nvim_get_current_tabpage(),
        winId = winId,
    })
end

M.onVimResized = function()
    layout.actions.multiTabOnVimResized({
        tabId = vim.api.nvim_get_current_tabpage(),
    })
end

M.onTabLeave = function()
    lastTabId = vim.api.nvim_get_current_tabpage()
end

M.onTabEnter = function()
    layout.actions.syncTabLayoutToNeovim()
end

M.onTabClosed = function()
    local log = logging.create('onTabClosed')
    layout.actions.onTabClosed({
        -- TODO can't find a conversion of tab number to tab id. You can
        -- get tab nr as arg when you eval <afile>, see help.
        tabId = lastTabId,
    })
end

M.onBufWinEnter = function()
    local log = logging.create('onBufWinEnter')
    local winId = vim.fn.win_getid()
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { winId = winId }
    )
    if floatWin == nil then
        return
    end

    local bufId = vim.fn.bufnr('%')
    local sed = seditors.selectors.getSeditorById(bufId)
    if sed == nil then
        log.warn('only seditors are supported in floating windows at the moment!')
        vim.cmd('e #')
        return
    end
end

M.layoutShiftWinDown = function()
    local winId = vim.fn.win_getid()
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { winId = winId }
    )
    if floatWin == nil then
        vim.cmd('wincmd r')
        return
    end

    layout.actions.shiftWinDown({
        tabId = vim.api.nvim_get_current_tabpage(),
        winId = vim.fn.win_getid(),
    })
end

M.layoutShiftWinUp = function()
    local winId = vim.fn.win_getid()
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { winId = winId }
    )
    if floatWin == nil then
        vim.cmd('wincmd R')
        return
    end

    layout.actions.shiftWinUp({
        tabId = vim.api.nvim_get_current_tabpage(),
        winId = vim.fn.win_getid(),
    })
end

M.layoutShiftWinBottom = function()
    local winId = vim.fn.win_getid()
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { winId = winId }
    )
    if floatWin == nil then
        vim.cmd('wincmd J')
        return
    end

    layout.actions.shiftWinBottom({
        tabId = vim.api.nvim_get_current_tabpage(),
        winId = vim.fn.win_getid(),
    })
end

M.layoutShiftWinTop = function()
    local winId = vim.fn.win_getid()
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { winId = winId }
    )
    if floatWin == nil then
        vim.cmd('wincmd K')
        return
    end

    layout.actions.shiftWinTop({
        tabId = vim.api.nvim_get_current_tabpage(),
        winId = vim.fn.win_getid(),
    })
end

M.runInFile = function(cmdToRun)
    local log = logging.create('runInFile')
    local bufId = vim.fn.bufnr('%')
    local sed = seditors.selectors.getSeditorById(bufId)
    if not sed then
        log.debug('nothing to do, no seditor', bufId, cmdToRun)
        return
    end
    log.debug(string.format('running command "%s" in buffer %d', cmdToRun, sed.fileBufferId))
    vim.api.nvim_buf_call(sed.fileBufferId, function()
        log.debug('subscribe to file buffer to sync changes', sed.fileBufferId)
        changeSyncing.subscribeToBuffer()
        vim.cmd(cmdToRun)
    end)
    log.debug('subscribe to seditor buffer again', bufId)
    changeSyncing.subscribeToBuffer()
end

M.floatToMainWindow = function()
    local log = logging.create('floatToMainWindow')
    local bufId = vim.fn.bufnr('%')

    local sed = seditors.selectors.getSeditorById(bufId)
    if not sed then
        log.debug('nothing to do, no seditor', bufId)
        return
    end

    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_get_current_tabpage(),
        { bufId = bufId }
    )
    if not floatWin then
        log.debug('buffer is not floating, nothing to do')
        return
    end

    log.debug('close float, move to main window and reopen buffer')
    vim.cmd('close')
    vim.cmd('wincmd t')
    vim.cmd('b ' .. bufId)
end

-----------------------
-- Neomake
-----------------------

M.yodeNeomakeGetSeditorInfo = function(bufId)
    local log = logging.create('yodeNeomakeGetSeditorInfo')
    local sed = seditors.selectors.getSeditorById(bufId)
    log.debug(bufId, sed)
    return sed
end

M.yodeNeomakeCheckIgnore = function(bufId)
    local log = logging.create('yodeNeomakeCheckIgnore')
    log.debug('checking buffer', bufId)
    local sed = seditors.selectors.getSeditorById(bufId)
    if sed then
        log.debug(
            'found seditor, Neomake should not ignore this type of buffer and proceed with checking'
        )
        return false
    end
    local bufType = vim.bo[bufId].buftype
    -- normal buffers have an empty buftype setting, ignore every non empty buftypes
    local shouldIgnore = not R.isEmpty(bufType or '')
    log.debug('no seditor, ignore logic as normal Neovim by buftype:', bufType, shouldIgnore)
    return shouldIgnore
end

-----------------------
-- Integration
-----------------------

M.yodeArgsLogger = function(...)
    local log = logging.create('yodeArgsLogger')
    log.debug(...)
end

-----------------------
-- debug stuff
-----------------------

M.yodeRedux = function()
    local log = logging.create('yodeRedux')
    log.debug('Redux Test --------------------')
    log.debug('inital state:', store.getState())
    seditors.actions.initSeditor({
        seditorBufferId = 105,
        data = {
            fileBufferId = 205,
            startLine = 11,
            indentCount = 4,
        },
    })
    seditors.actions.changeStartLine({ seditorBufferId = 105, amount = 6 })
    log.debug('selector', seditors.selectors.getSeditorById(105))
    log.debug('End ---------------------------')
end

return M
