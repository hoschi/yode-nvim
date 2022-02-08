local logging = require('yode-nvim.logging')
local log

local stateLogger = function(store)
    return function(nextDispatch)
        return function(action)
            if not log then
                log = logging.create('state')
            end
            log.trace('will dispatch:', action)
            local ret = nextDispatch(action)
            log.trace('after dispatch:', store.getState())
            return ret
        end
    end
end

return stateLogger
