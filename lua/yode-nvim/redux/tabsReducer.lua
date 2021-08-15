local R = require('yode-nvim.deps.lamda.dist.lamda')
local createReducer = require('yode-nvim.redux.createReducer')
local h = require('yode-nvim.helper')

local M = { actions = {}, selectors = {} }

local INIT_NEW_TAB = 'INIT_NEW_TAB'
M.actions.initNewTab = R.pipe(R.pick({ 'tabId' }), R.assoc('type', INIT_NEW_TAB))

local INIT_NEW_SWINDOW = 'INIT_NEW_SWINDOW'
M.actions.initNewSwindow = R.pipe(
    R.pick({ 'tabId', 'winId', 'data' }),
    R.assoc('type', INIT_NEW_SWINDOW)
)

local CHANGE_WIN_POSITION = 'CHANGE_WIN_POSITION'
M.actions.changeWinPosition = R.pipe(
    R.pick({ 'tabId', 'winId', 'amount' }),
    R.assoc('type', CHANGE_WIN_POSITION)
)

local CHANGE_WIN_DATA = 'CHANGE_WIN_DATA'
M.actions.changeWinData = R.pipe(
    R.pick({ 'tabId', 'winId', 'data' }),
    R.assoc('type', CHANGE_WIN_DATA)
)

local REMOVE_SWINDOW = 'REMOVE_SWINDOW'
M.actions.removeSwindow = R.pipe(R.pick({ 'tabId', 'winId' }), R.assoc('type', REMOVE_SWINDOW))

M.selectors.getSwindowById = function(tabId, winId, state)
    return R.path({ tostring(tabId), 'swindows', tostring(winId) }, state)
end
M.selectors.getAllSwindows = R.pipe(R.values, R.pluck('swindows'), R.chain(R.values))
M.selectors.getSwindowBySeditorBufferId = function(seditorBufferId, state)
    return R.pipe(
        M.selectors.getAllSwindows,
        R.filter(R.propEq('seditorBufferId', seditorBufferId)),
        R.head
    )(state)
end
M.selectors.getSeditorsConnected = function(fileBufferId, state)
    return R.pipe(M.selectors.getAllSwindows, R.filter(R.propEq('fileBufferId', fileBufferId)))(
        state
    )
end

local reducerFunctions = {
    [INIT_NEW_TAB] = function(state, a)
        return R.assocPath({ tostring(a.tabId), 'swindows' }, {}, state)
    end,
    [INIT_NEW_SWINDOW] = function(state, a)
        return R.assocPath(
            { tostring(a.tabId), 'swindows', tostring(a.winId) },
            R.mergeDeepRight({
                winId = a.winId,
                tabId = a.tabId,
                -- same number vim shows you as row in number column
                startLine = nil,
                visible = nil,
                fileBufferId = nil,
                seditorBufferId = nil,
                indentCount = nil,
            }, a.data),
            state
        )
    end,
    [CHANGE_WIN_DATA] = function(state, a)
        return h.over(
            h.lensPath({ tostring(a.tabId), 'swindows', tostring(a.winId) }),
            R.mergeDeepLeft(a.data),
            state
        )
    end,
    [CHANGE_WIN_POSITION] = function(state, a)
        return h.over(
            h.lensPath({ tostring(a.tabId), 'swindows', tostring(a.winId), 'startLine' }),
            R.add(a.amount),
            state
        )
    end,
    [REMOVE_SWINDOW] = function(state, a)
        return R.dissocPath({ tostring(a.tabId), 'swindows', tostring(a.winId) }, state)
    end,
}
M.reducer = createReducer({}, reducerFunctions)

return M
