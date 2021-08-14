local R = require('yode-nvim.deps.lamda.dist.lamda')
local createReducer = require('yode-nvim.redux.createReducer')

local M = { actions = {}, selectors = {} }

local initalState = {
    name = '',
    age = 0,
}

M.actions.updateName = function(name)
    return {
        type = 'PROFILE_UPDATE_NAME',
        name = name,
    }
end

M.actions.updateAge = function(age)
    return {
        type = 'PROFILE_UPDATE_AGE',
        age = age,
    }
end

M.selectors.getName = R.prop('name')
M.selectors.isKid = function(min, max, state)
    return state.age > min and state.age < max
end

local handlers = {
    ['PROFILE_UPDATE_NAME'] = function(state, action)
        return R.assoc('name', action.name, state)
    end,

    ['PROFILE_UPDATE_AGE'] = function(state, action)
        return R.assoc('age', action.age, state)
    end,
}
M.reducer = createReducer(initalState, handlers)

return M
