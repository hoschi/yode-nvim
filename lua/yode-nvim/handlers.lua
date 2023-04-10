local R = require('yode-nvim.deps.lamda.dist.lamda')
local logging = require('yode-nvim.logging')
local M = { fns = {} }

M.setup = function(handlers)
    local log = logging.create('handlers')
    log.debug('args', handlers)
    M.fns = R.pick({ 'onSeditorBufCal' }, handlers)
    log.debug('computed', M.fns)
end

return M
