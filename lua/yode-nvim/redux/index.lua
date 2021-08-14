local createStore = require('yode-nvim.deps.redux-lua.src.createStore')
local applyMiddleware = require('yode-nvim.deps.redux-lua.src.applyMiddleware')
local combineReducers = require('yode-nvim.deps.redux-lua.src.combineReducers')
local tabsReducer = require('yode-nvim.redux.tabsReducer')
local stateLogger = require('yode-nvim.redux.stateLogger')
local ReduxEnv = require 'yode-nvim.deps.redux-lua.src.env'
ReduxEnv.setDebug(false)

local M = {}

local reducers = combineReducers({ tabs = tabsReducer.reducer })

M.store = createStore(reducers, applyMiddleware(stateLogger))
M.tabs = {
    actions = tabsReducer.actions,
}

return M
