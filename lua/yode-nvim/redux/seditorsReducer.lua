local R = require('yode-nvim.deps.lamda.dist.lamda')
local createReducer = require('yode-nvim.redux.createReducer')
local h = require('yode-nvim.helper')

local M = { actions = {}, selectors = {}, actionNames = {} }
local ZOMBIE_COUNTDOWN_VALUE = 11

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

M.actionNames.SOFTLY_KILL_SEDITOR = 'SOFTLY_KILL_SEDITOR'
M.actions.softlyKillSeditor = R.pipe(
    R.pick({ 'seditorBufferId' }),
    R.assoc('type', M.actionNames.SOFTLY_KILL_SEDITOR),
    function(action)
        return R.merge(action, {
            lines = vim.api.nvim_buf_get_lines(action.seditorBufferId, 0, -1, true),
        })
    end
)

M.actionNames.RESURRECT_SEDITOR = 'RESURRECT_SEDITOR'
M.actions.resurrectSeditor = R.pipe(
    R.pick({ 'seditorBufferId' }),
    R.assoc('type', M.actionNames.RESURRECT_SEDITOR)
)

M.selectors.getSeditorById = function(id, state)
    return R.prop(id, state)
end
M.selectors.getSeditorsConnected = function(fileBufferId, state)
    return R.pipe(
        R.values,
        R.filter(R.allPass(R.propEq('fileBufferId', fileBufferId), R.complement(R.has('zombie'))))
    )(state)
end
M.selectors.getZombieSeditorsConnected = function(fileBufferId, state)
    return R.pipe(
        R.values,
        R.filter(R.allPass(R.propEq('fileBufferId', fileBufferId), R.has('zombie')))
    )(state)
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
                zombie = nil,
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
    [M.actionNames.SOFTLY_KILL_SEDITOR] = function(state, a)
        return h.over(h.lensProp(a.seditorBufferId), function(sed)
            local text = R.pipe(
                sed.indentCount and h.map(R.concat(h.createWhiteSpace(sed.indentCount)))
                    or R.identity,
                R.join('\n')
            )(a.lines)

            return R.assoc('zombie', {
                text = text,
                countdown = ZOMBIE_COUNTDOWN_VALUE,
            }, sed)
        end, state)
    end,
    [M.actionNames.RESURRECT_SEDITOR] = function(state, a)
        return R.dissocPath({ a.seditorBufferId, 'zombie' }, state)
    end,
}
M.reducer = createReducer({}, reducerFunctions)

return M
