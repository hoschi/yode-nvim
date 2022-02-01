local logging = require('yode-nvim.logging')
local layoutMap = require('yode-nvim.layout.layoutMap')
local layoutReducer = require('yode-nvim.redux.layoutReducer')
local log

local layoutStateToNeovim = function(store)
    return function(nextDispatch)
        return function(action)
            local layout, tabStateNeovim, tabState, status, err
            local normalRet = nextDispatch(action)
            local state = store.getState()
            if not log then
                log = logging.create('layoutStateToNeovim')
            end

            if action.syncToNeovim == true then
                log.trace('trying it with state', state)
                tabState = state.layout.tabs[action.tabId]
                if tabState == nil then
                    log.trace('no valid tab state, aborting')
                    return normalRet
                end

                if
                    action.type == layoutReducer.actionNames.SYNC_TAB_LAYOUT_TO_NEOVIM
                    and tabState.isDirty == false
                then
                    log.trace("tab isn't dirty, aborting")
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
                return nextDispatch(layoutReducer.actions.updateTabState({
                    data = tabStateNeovim,
                    tabId = action.tabId,
                }))
            end

            log.trace('not for me')
            return normalRet
        end
    end
end

return layoutStateToNeovim
