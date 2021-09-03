local logging = require('yode-nvim.logging')
local layoutMap = require('yode-nvim.layout.layoutMap')
local logMemo

local layoutStateToNeovim = function(store)
    return function(nextDispatch)
        return function(action)
            local layout, tabStateNeovim
            local normalRet = nextDispatch(action)
            local state = store.getState()
            local log = logMemo and logMemo or logging.create('layoutStateToNeovim')
            -- TODO find better way to identify layout actions?
            if action.tabId and action.type ~= 'me' then
                log.trace('trying it with state', state)
                tabState = state.layout.tabs[action.tabId]
                if tabState == nil then
                    log.trace('no valid tab state, aborting')
                    return normalRet
                end

                layout = layoutMap[tabState.name]
                status, err = pcall(function()
                    tabStateNeovim = layout.stateToNeovim(tabState)
                end)
                if status == false then
                    log.error(err)
                    return normalRet
                end

                log.trace('did it! updating state now.')
                -- FIXME replace 'me'
                -- FIXME test if we can skip this when tabStateNeovim ==
                -- tabState and if it is ever true
                return nextDispatch({ type = 'me', data = tabStateNeovim, tabId = action.tabId })
            end

            log.trace('not for me')
            return normalRet
        end
    end
end

return layoutStateToNeovim
