local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local tabs = storeBundle.tabs
local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = {}

M.writeFileEditor = function()
    local log = logging.create('writeFileEditor')

    local bufId = vim.fn.bufnr('%')
    local swindowsConnected = tabs.selectors.getSeditorsConnected(bufId)
    R.forEach(function(win)
        vim.bo[win.seditorBufferId].modified = false
    end, swindowsConnected)
end

return M
