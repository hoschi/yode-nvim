local logging = require('yode-nvim.logging')
local logMemo

local stateLogger = function (store)
    return function (nextDispatch)
        return function (action)
            local log = logMemo and logMemo or logging.create('state')
            log.trace('will dispatch:', action)
            local ret = nextDispatch(action)
            log.trace('after dispatch:', store.getState())
            return ret
        end
    end
end

return stateLogger
