local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors
local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = {}

M.writeFileEditor = function()
    local log = logging.create('writeFileEditor')

    local bufId = vim.fn.bufnr('%')
    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    R.forEach(function(sed)
        vim.bo[sed.seditorBufferId].modified = false
    end, sedsConnected)
end

return M
