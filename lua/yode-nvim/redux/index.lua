local createStore = require('yode-nvim.deps.redux-lua.src.createStore')
local applyMiddleware = require('yode-nvim.deps.redux-lua.src.applyMiddleware')
local combineReducers = require('yode-nvim.deps.redux-lua.src.combineReducers')
local tabsReducer = require('yode-nvim.redux.tabsReducer')
local stateLogger = require('yode-nvim.redux.stateLogger')
local ReduxEnv = require('yode-nvim.deps.redux-lua.src.env')
ReduxEnv.setDebug(false)
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = { store = {}, tabs = {} }

local STATE_PATH_TABS = { 'tabs' }
local reducerMap = R.pipe(R.assocPath(STATE_PATH_TABS, tabsReducer.reducer))({})
local reducers = combineReducers(reducerMap)

local globalizeSelectors = function(rootPath, selectors)
    return h.map(function(selector)
        return function(...)
            local state = M.store.getState()
            return selector(unpack(R.concat({ ... }, { R.path(rootPath, state) })))
        end
    end, selectors)
end

local wrapWithDispatch = h.map(function(action)
    return function(...)
        return M.store.dispatch(action(...))
    end
end)

M.store = createStore(reducers, applyMiddleware(stateLogger))
M.tabs = {
    actions = wrapWithDispatch(tabsReducer.actions),
    selectors = globalizeSelectors(STATE_PATH_TABS, tabsReducer.selectors),
}

return M
