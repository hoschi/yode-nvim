local R = require('yode-nvim.deps.lamda.dist.lamda')
local createReducer = require('yode-nvim.redux.createReducer')
local h = require('yode-nvim.helper')

local M = { actions = {}, selectors = {} }

local INIT_SEDITOR = 'INIT_SEDITOR'
M.actions.initSeditor = R.pipe(R.pick({ 'seditorBufferId', 'data' }), R.assoc('type', INIT_SEDITOR))

local CHANGE_START_LINE = 'CHANGE_START_LINE'
M.actions.changeStartLine = R.pipe(
    R.pick({ 'seditorBufferId', 'amount' }),
    R.assoc('type', CHANGE_START_LINE)
)

local CHANGE_DATA = 'CHANGE_DATA'
M.actions.changeData = R.pipe(R.pick({ 'seditorBufferId', 'data' }), R.assoc('type', CHANGE_DATA))

local REMOVE_SEDITOR = 'REMOVE_SEDITOR'
M.actions.removeSeditor = R.pipe(R.pick({ 'seditorBufferId' }), R.assoc('type', REMOVE_SEDITOR))

M.selectors.getSeditorById = function(id, state)
    return R.prop(id, state)
end
M.selectors.getSeditorsConnected = function(fileBufferId, state)
    return R.pipe(R.filter(R.propEq('fileBufferId', fileBufferId)))(state)
end

local reducerFunctions = {
    [INIT_SEDITOR] = function(state, a)
        return R.assoc(
            a.seditorBufferId,
            R.mergeDeepRight({
                seditorBufferId = a.seditorBufferId,
                -- zero based index, decrease line number you see in vim number
                -- column by one. Same logic as `nvim_buf_get_lines`.
                startLine = nil,
                fileBufferId = nil,
                indentCount = nil,
            }, a.data),
            state
        )
    end,
    [CHANGE_DATA] = function(state, a)
        return h.over(h.lensProp(a.seditorBufferId), R.mergeDeepLeft(a.data), state)
    end,
    [CHANGE_START_LINE] = function(state, a)
        return h.over(h.lensPath({ a.seditorBufferId, 'startLine' }), R.add(a.amount), state)
    end,
    [REMOVE_SEDITOR] = function(state, a)
        return R.dissoc(a.seditorBufferId, state)
    end,
}
M.reducer = createReducer({}, reducerFunctions)

return M
