local logging = require('yode-nvim.logging')
local seditorsReducer = require('yode-nvim.redux.seditorsReducer')
local log

local generalStateToNeovim = function() -- function(store)
    return function(nextDispatch)
        return function(action)
            if not log then
                log = logging.create('generalStateToNeovim')
            end
            --local stateBefore = store.getState()
            local normalRet = nextDispatch(action)
            --local state = store.getState()

            if action.type == seditorsReducer.actionNames.SOFTLY_KILL_SEDITOR then
                log.trace(seditorsReducer.SOFTLY_KILL_SEDITOR)
                vim.bo[action.seditorBufferId].modifiable = false
            elseif action.type == seditorsReducer.actionNames.RESURRECT_SEDITOR then
                log.trace(seditorsReducer.actionNames.RESURRECT_SEDITOR)
                vim.bo[action.seditorBufferId].modifiable = true
                return normalRet
            else
                log.trace('not for me')
                return normalRet
            end
        end
    end
end

return generalStateToNeovim
