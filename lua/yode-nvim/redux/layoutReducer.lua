local R = require('yode-nvim.deps.lamda.dist.lamda')
local logging = require('yode-nvim.logging')
local layoutMap = require('yode-nvim.layout.layoutMap')
local h = require('yode-nvim.helper')
local sharedActions = require('yode-nvim.layout.sharedActions')

local M = { actions = {}, actionNames = {}, selectors = {} }

local initialState = {
    tabs = {},
}

M.actionNames.SYNC_TAB_LAYOUT_TO_NEOVIM = 'SYNC_TAB_LAYOUT_TO_NEOVIM'
M.actions.syncTabLayoutToNeovim = function()
    return {
        type = M.actionNames.SYNC_TAB_LAYOUT_TO_NEOVIM,
        syncToNeovim = true,
        tabId = vim.api.nvim_get_current_tabpage(),
    }
end

local ON_TAB_CLOSED = 'ON_TAB_CLOSED'
M.actions.onTabClosed = R.pipe(
    R.merge({ syncToNeovim = false }),
    R.pick({ 'syncToNeovim', 'tabId' }),
    R.assoc('type', ON_TAB_CLOSED)
)

local UPDATE_TAB_STATE = 'UPDATE_TAB_STATE'
M.actions.updateTabState = R.pipe(
    R.merge({ syncToNeovim = false }),
    R.pick({ 'syncToNeovim', 'tabId', 'data' }),
    R.assoc('type', UPDATE_TAB_STATE)
)

local MULTI_TAB_REMOVE_SEDITOR = 'MULTI_TAB_REMOVE_SEDITOR'
M.actions.multiTabRemoveSeditor = R.pipe(
    -- NOTICE floating windows in current tab get removed, because window close
    -- triggers removal as well. This way we don't need a `tabId` and
    -- `syncToNeovim=true` for the multi action.
    R.merge({ syncToNeovim = false }),
    R.pick({ 'syncToNeovim', 'winId', 'bufId' }),
    R.assoc('type', MULTI_TAB_REMOVE_SEDITOR)
)

local MULTI_TAB_ON_VIM_RESIZED = 'MULTI_TAB_ON_VIM_RESIZED'
M.actions.multiTabOnVimResized = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId' }),
    R.assoc('type', MULTI_TAB_ON_VIM_RESIZED)
)

local MULTI_TAB_CONTENT_CHANGED = 'MULTI_TAB_CONTENT_CHANGED'
M.actions.multiTabContentChanged = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', MULTI_TAB_CONTENT_CHANGED)
)

local multiTabActionMap = {
    [MULTI_TAB_REMOVE_SEDITOR] = R.pipe(
        R.omit({ 'type', 'syncToNeovim' }),
        sharedActions.actions.removeFloatingWindow
    ),
    [MULTI_TAB_ON_VIM_RESIZED] = R.pipe(
        R.omit({ 'type', 'syncToNeovim' }),
        sharedActions.actions.onVimResized
    ),
    [MULTI_TAB_CONTENT_CHANGED] = R.pipe(
        R.omit({ 'type', 'syncToNeovim' }),
        sharedActions.actions.contentChanged
    ),
}

local createTabState = function(id, name)
    return {
        id = id,
        name = name,
        -- TODO: track here for example "align=right|left, columnWidthMin=30,
        -- columnWidthMax=50%" for Mosaic
        config = {},
        -- TODO place for layout reducer to store data not tied to window, probably not needed?!
        data = {},
        windows = {},
        isDirty = false,
    }
end

M.selectors = R.reduce(function(selectors, selectorName)
    local selector = function(tabId, selectorArgs, state)
        if tabId == false then
            return R.chain(function(tabState)
                local layoutSelector = R.path(
                    { tabState.name, 'selectors', selectorName },
                    layoutMap
                ) or R.always({})
                return layoutSelector(tabState.id, selectorArgs, tabState)
            end, state.tabs)
        else
            local tabState = state.tabs[tabId] or {}
            local layoutSelector = R.path({ tabState.name, 'selectors', selectorName }, layoutMap)
                or h.noop
            return layoutSelector(tabId, selectorArgs, tabState)
        end
    end
    return R.assoc(selectorName, selector, selectors)
end, {}, {
    'getWindowBySomeId',
})

local reducerFunctions = {
    [UPDATE_TAB_STATE] = function(state, a)
        return R.assocPath({ 'tabs', a.tabId }, a.data, state)
    end,
    [ON_TAB_CLOSED] = function(state, a)
        return R.dissocPath({ 'tabs', a.tabId }, state)
    end,
}

local reduceSingleTab = function(state, action)
    local log = logging.create('reduceSingleTab')
    local tabState = state.tabs[action.tabId] or createTabState(action.tabId, 'mosaic')
    local layout = layoutMap[tabState.name]
    local tabStateData = layout.reducer(tabState, action)

    if tabStateData == nil then
        log.warn(string.format("layout %s can't handle action ", tabState.name or 'mosaic'), action)
        return state
    end

    return R.assocPath({ 'tabs', action.tabId }, tabStateData, state)
end

M.reducer = function(stateParam, action)
    local tabIds, singleTabActionCreator
    local log = logging.create('reducer')
    local state = stateParam or initialState

    if action.type == M.actionNames.SYNC_TAB_LAYOUT_TO_NEOVIM then
        return state
    end

    if reducerFunctions[action.type] then
        return reducerFunctions[action.type](state, action)
    end

    singleTabActionCreator = multiTabActionMap[action.type]
    if singleTabActionCreator then
        tabIds = R.keys(state.tabs)
        log.trace(
            string.format('mapping multi tab action %s to single tab action: ', action.type),
            tabIds
        )
        return R.reduce(function(prevState, tabId)
            log.trace('reducing tabId', tabId)
            return reduceSingleTab(
                prevState,
                singleTabActionCreator(R.assoc('tabId', tabId, action))
            )
        end, state, tabIds)
    end

    if action.tabId then
        return reduceSingleTab(state, action)
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
