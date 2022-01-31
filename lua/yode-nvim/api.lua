local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors

local M = {}

M.getSeditorsConnected = function(bufId)
    local log = logging.create('getSeditorsConnected')

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    log.debug(bufId, #sedsConnected)
    return sedsConnected
end

M.getSeditorById = function(bufId)
    local log = logging.create('getSeditorById')

    local sed = seditors.selectors.getSeditorById(bufId)
    log.debug(bufId, sed)
    return sed
end

return M
