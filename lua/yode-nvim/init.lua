local defaultConfig = require('yode-nvim.defaultConfig')
local logging = require('yode-nvim.logging')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local tabs = storeBundle.tabs

local M = {
    config = {},
}
local count = 1

M.setup = function(options)
    M.config = vim.tbl_deep_extend('force', defaultConfig, options or {})
    logging.setup(M.config.log)
end

M.yodeNvim = function()
    local log = logging.create('yodeNvim')
    require('yode-nvim.testSetup1')()
    --require('yode-nvim.testSetup2')()
end

M.yodeTesting = function()
    local log = logging.create('yodeTesting')
    local n = h.getIndentCount({ 'foo', '    bar' })
    log.debug(n)
end

M.yodeArgsLogger = function(...)
    local log = logging.create('yodeArgsLogger')
    log.debug(...)
end

M.yodeNeomakeGetSeditorInfo = function(bufId)
    local log = logging.create('yodeNeomakeGetSeditorInfo')
    local win = tabs.selectors.getSwindowBySeditorBufferId(bufId)
    log.debug(bufId, win)
    return win
end

M.yodeRedux = function()
    local log = logging.create('yodeRedux')
    log.debug('Redux Test --------------------')
    log.debug('inital state:', store.getState())
    tabs.actions.initNewTab({ tabId = 5 })
    tabs.actions.initNewSwindow({
        tabId = 5,
        winId = 100,
        data = {
            seditorBufferId = 105,
            fileBufferId = 205,
            visible = true,
            startLine = 11,
            indentCount = 4,
        },
    })
    tabs.actions.changeWinPosition({ tabId = 5, winId = 100, amount = 6 })
    log.debug('selector', tabs.selectors.getSwindowById(5, 100))
    log.debug('End ---------------------------')
end

return M
