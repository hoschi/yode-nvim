local logging = require('yode-nvim.logging')

local M = {}

local currentTabId = 1

M.onBufEnter = function()
    local log = logging.create('onBufEnter')
    if vim.t.tabId then
        log.trace('tabId already there', vim.t.tabId)
        return
    end

    vim.t.tabId = currentTabId
    log.trace('setting tabId', vim.t.tabId)
    currentTabId = currentTabId + 1
end

M.onTabNew = function()
    vim.t.tabId = currentTabId
    currentTabId = currentTabId + 1
end

return M
