local R = require('yode-nvim.deps.lamda.dist.lamda')
local logging = require('yode-nvim.logging')
local createReducer = require('yode-nvim.redux.createReducer')
local layoutMap = require('yode-nvim.layout.layoutMap')
local h = require('yode-nvim.helper')
local sharedActions = require('yode-nvim.layout.sharedActions')

local M = { actions = {}, selectors = {} }

initialState = {
    tabs = {},
}

local createTabState = function(name)
    return {
        name = name,
        -- FIXME: track here for example "align=right|left, columnWidthMin=30,
        -- columnWidthMax=50%" for Mosaic
        config = {},
        -- FIXME place for layout reducer to store data not tied to window, probably not needed?!
        data = {},
        windows = {},
    }
end

M.selectors = R.reduce(function(selectors, selectorName)
    local selector = function(tabId, selectorArgs, state)
        local tabState = state.tabs[tabId] or {}
        local layoutSelector = R.path({ tabState.name, 'selectors', selectorName }, layoutMap)
            or h.noop
        return layoutSelector(tabId, selectorArgs, tabState)
    end
    return R.assoc(selectorName, selector, selectors)
end, {}, {
    'getWindowBySomeId',
})

local reducerFunctions = {
    -- FIXME do better
    me = function(state, a)
        return R.assocPath({ 'tabs', a.tabId }, a.data, state)
    end,
    [sharedActions.actionNames.ON_TAB_CLOSED] = function(state, a)
        return R.dissocPath({ 'tabs', a.tabId }, state)
    end,
}

M.reducer = function(stateParam, action)
    local tabState, tabStateData, tabStateNeovim, layout
    local log = logging.create('reducer')
    local state = stateParam or initialState
    if reducerFunctions[action.type] then
        return reducerFunctions[action.type](state, action)
    end

    if action.tabId then
        tabState = state.tabs[action.tabId] or createTabState('mosaic')
        layout = layoutMap[tabState.name]
        tabStateData = layout.reducer(tabState, action)

        if tabStateData == nil then
            log.warn(
                string.format("layout %s can't handle action ", tabState.name or 'mosaic'),
                action
            )
            return state
        end

        return R.assocPath({ 'tabs', action.tabId }, tabStateData, state)
    end

    return state
end

--[[
TODO:
* this logic must be already in SOME plugin in the internet!
    * how to find windows to ignore? E.g. location/quickfix list window panel at bottom?
    * what special things do we need to ignore?
        * height: tab row (if visible)
        * width: nerdtree, gundo, ...
    * check https://github.com/beauwilliams/focus.nvim
]]

return M
