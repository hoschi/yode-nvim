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

M.setup = function(options)
    M.config = vim.tbl_deep_extend('force', defaultConfig, options or {})
    logging.setup(M.config.log)
end

M.yodeNvim = function()
    local log = logging.create('yodeNvim')
    testSetup.setup1()
    -- FIXME comment out
    --vim.cmd('wincmd h')
    --vim.api.nvim_feedkeys('ggjjjj', 'x', false)

    --testSetup.setup2()
end

M.yodeTesting = function()
    local log = logging.create('yodeTesting')
    log.debug('!!!!!!!!!!', vim.fn.bufnr('%'))
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
        tabId = vim.api.nvim_tabpage_get_number(0),
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

M.goToAlternateBuffer = function()
    local log = logging.create('goToAlternateBuffer')
    local bufId = vim.fn.bufnr('%')
    local sed = seditors.selectors.getSeditorById(bufId)

    if sed == nil then
        log.debug('no seditor found for ' .. bufId)
    end

    -- TODO only do this when not in floating window. When in float, open file
    -- buffer in main area?!
    vim.cmd('b ' .. sed.fileBufferId)
end

M.cloneCurrentIntoFloat = function()
    local log = logging.create('cloneCurrentIntoFloat')
    local bufId = vim.fn.bufnr('%')
    local winId = vim.fn.win_getid()
    local config = vim.api.nvim_win_get_config(0)

    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_tabpage_get_number(0),
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
        tabId = vim.api.nvim_tabpage_get_number(0),
        bufId = bufId,
        data = {},
    })
    vim.fn.win_gotoid(winId)
end

M.onWindowClosed = function(winId)
    local log = logging.create('onWindowClosed')
    log.debug(winId)
    layout.actions.removeFloatingWindow({
        tabId = vim.api.nvim_tabpage_get_number(0),
        winId = winId,
    })
end

M.onVimResized = function()
    layout.actions.onVimResized({
        tabId = vim.api.nvim_tabpage_get_number(0),
    })
end

M.onBufWinEnter = function()
    local log = logging.create('onBufWinEnter')
    local winId = vim.fn.win_getid()
    local floatWin = layout.selectors.getWindowBySomeId(
        vim.api.nvim_tabpage_get_number(0),
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
    layout.actions.shiftWinDown({
        tabId = vim.api.nvim_tabpage_get_number(0),
        winId = vim.fn.win_getid(),
    })
end

M.layoutShiftWinUp = function()
    layout.actions.shiftWinUp({
        tabId = vim.api.nvim_tabpage_get_number(0),
        winId = vim.fn.win_getid(),
    })
end

M.layoutShiftWinBottom = function()
    layout.actions.shiftWinBottom({
        tabId = vim.api.nvim_tabpage_get_number(0),
        winId = vim.fn.win_getid(),
    })
end

M.layoutShiftWinTop = function()
    layout.actions.shiftWinTop({
        tabId = vim.api.nvim_tabpage_get_number(0),
        winId = vim.fn.win_getid(),
    })
end

M.yodeArgsLogger = function(...)
    local log = logging.create('yodeArgsLogger')
    log.debug(...)
end

M.yodeNeomakeGetSeditorInfo = function(bufId)
    local log = logging.create('yodeNeomakeGetSeditorInfo')
    local sed = seditors.selectors.getSeditorById(bufId)
    log.debug(bufId, sed)
    return sed
end

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
