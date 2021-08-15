local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local tabs = storeBundle.tabs
local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = {}

M.checkIndentCount = function(win)
    local log = logging.create('checkIndentCount')
    local currentLines = vim.api.nvim_buf_get_lines(win.seditorBufferId, 0, -1, true)
    local seditorIndentCount = h.getIndentCount(currentLines)
    log.trace(win.seditorBufferId, 'new count:', seditorIndentCount)
    if seditorIndentCount <= 0 then
        return
    end

    local indentCount = seditorIndentCount + win.indentCount
    log.debug(win.seditorBufferId, 'changed:', {
        newIndentCount = indentCount,
        savedIndentCount = win.indentCount,
        seditorIndentCount = seditorIndentCount,
    })
    tabs.actions.changeWinData(
        R.merge(R.pick({ 'tabId', 'winId' }, win), { data = { indentCount = indentCount } })
    )
    local changedLines = h.map(R.drop(seditorIndentCount), currentLines)
    vim.api.nvim_buf_set_lines(win.seditorBufferId, 0, -1, true, changedLines)
end

M.checkLineDataIndentCount = function(win, lineData)
    local log = logging.create('checkLineDataIndentCount')

    local indentCount = h.getIndentCount(lineData)
    if indentCount >= win.indentCount then
        return win.indentCount
    end

    log.debug(
        '----',
        win.seditorBufferId,
        'detected indent decrease',
        { before = win.indentCount, after = indentCount }
    )
    tabs.actions.changeWinData(
        R.merge(R.pick({ 'tabId', 'winId' }, win), { data = { indentCount = indentCount } })
    )
    local currentLines = vim.api.nvim_buf_get_lines(win.seditorBufferId, 0, -1, true)
    local changedLines = h.map(
        R.concat(h.createWhiteSpace(win.indentCount - indentCount)),
        currentLines
    )

    vim.schedule(function()
        vim.api.nvim_buf_set_lines(win.seditorBufferId, 0, -1, true, changedLines)
    end)
    return indentCount
end

M.writeSeditor = function()
    local log = logging.create('writeSeditor')

    local bufId = vim.fn.bufnr('%')
    local win = tabs.selectors.getSwindowBySeditorBufferId(bufId)

    if win == nil then
        log.error("can't find window for buffer id " .. bufId)
    end

    log.debug(bufId, ', writing changes to file buffer ' .. win.fileBufferId)
    vim.api.nvim_buf_call(win.fileBufferId, function()
        vim.cmd('write')
    end)
    vim.bo[bufId].modified = false
end

return M
