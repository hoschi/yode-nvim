local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors
local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = {}

M.checkIndentCount = function(sed)
    local log = logging.create('checkIndentCount')
    local currentLines = vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
    local seditorIndentCount = h.getIndentCount(currentLines)
    log.trace(sed.seditorBufferId, 'new count:', seditorIndentCount)
    if seditorIndentCount <= 0 then
        return
    end

    local indentCount = seditorIndentCount + sed.indentCount
    log.debug(sed.seditorBufferId, 'changed:', {
        newIndentCount = indentCount,
        savedIndentCount = sed.indentCount,
        seditorIndentCount = seditorIndentCount,
    })
    seditors.actions.changeData({
        seditorBufferId = sed.seditorBufferId,
        data = { indentCount = indentCount },
    })
    local changedLines = h.map(R.drop(seditorIndentCount), currentLines)
    vim.api.nvim_buf_set_lines(sed.seditorBufferId, 0, -1, true, changedLines)
end

M.checkLineDataIndentCount = function(sed, lineData)
    local log = logging.create('checkLineDataIndentCount')

    local indentCount = h.getIndentCount(lineData)
    if indentCount >= sed.indentCount then
        return sed.indentCount
    end

    log.debug(
        '----',
        sed.seditorBufferId,
        'detected indent decrease',
        { before = sed.indentCount, after = indentCount }
    )
    seditors.actions.changeData({
        seditorBufferId = sed.seditorBufferId,
        data = { indentCount = indentCount },
    })
    local currentLines = vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
    local changedLines =
        h.map(R.concat(h.createWhiteSpace(sed.indentCount - indentCount)), currentLines)

    vim.schedule(function()
        vim.api.nvim_buf_set_lines(sed.seditorBufferId, 0, -1, true, changedLines)
    end)
    return indentCount
end

M.writeSeditor = function()
    local log = logging.create('writeSeditor')

    local bufId = vim.fn.bufnr('%')
    local sed = seditors.selectors.getSeditorById(bufId)

    if sed == nil then
        log.error("can't find window for buffer id " .. bufId)
    end

    log.debug(bufId, ', writing changes to file buffer ' .. sed.fileBufferId)
    vim.api.nvim_buf_call(sed.fileBufferId, function()
        vim.cmd('write')
    end)
    vim.bo[bufId].modified = false
end

return M
