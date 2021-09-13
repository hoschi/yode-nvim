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
    --testSetup.setup2()
end

M.yodeTesting = function()
    local log = logging.create('yodeTesting')
    local n = h.getIndentCount({ 'foo', '    bar' })
    log.debug(n)
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

M.onWindowClosed = function(winId)
    local log = logging.create('onWindowClosed')
    log.debug(winId)
    layout.actions.onWindowClosed({
        tabId = vim.api.nvim_tabpage_get_number(0),
        winId = winId,
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
