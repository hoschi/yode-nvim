local defaultConfig = require('yode-nvim.defaultConfig')
local logging = require('yode-nvim.logging')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local createSeditor = require('yode-nvim.createSeditor')
local changeSyncing = require('yode-nvim.changeSyncing')

local M = {
    config = {},
}

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

    local bufId = vim.fn.bufnr('%')
    local text = vim.api.nvim_buf_get_lines(bufId, firstline - 1, lastline, true)
    createSeditor({
        fileBufferId = bufId,
        text = text,
        windowY = 0,
        windowHeight = #text,
        startLine = firstline - 1,
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

    local bufId = vim.fn.bufnr('%')
    local text = vim.api.nvim_buf_get_lines(bufId, firstline - 1, lastline, true)
    local seditorBufferId, name = createSeditor({
        fileBufferId = bufId,
        text = text,
        windowY = 0,
        windowHeight = #text,
        startLine = firstline - 1,
        dontFloat = true,
    })

    vim.cmd('b ' .. seditorBufferId)
    vim.cmd('file ' .. name)
    changeSyncing.subscribeToBuffer()
end

M.yodeArgsLogger = function(...)
    local log = logging.create('yodeArgsLogger')
    log.debug(...)
end

M.yodeNeomakeGetSeditorInfo = function(bufId)
    local log = logging.create('yodeNeomakeGetSeditorInfo')
    local win = seditors.selectors.getSeditorById(bufId)
    log.debug(bufId, win)
    return win
end

M.yodeRedux = function()
    local log = logging.create('yodeRedux')
    log.debug('Redux Test --------------------')
    log.debug('inital state:', store.getState())
    seditors.actions.initSeditor({
        seditorBufferId = 105,
        data = {
            fileBufferId = 205,
            visible = true,
            startLine = 11,
            indentCount = 4,
        },
    })
    seditors.actions.changeStartLine({ seditorBufferId = 105, amount = 6 })
    log.debug('selector', seditors.selectors.getSeditorById(105))
    log.debug('End ---------------------------')
end

return M
