local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = { actions = {} }

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

local initState = {
    name = '',
    age = 0,
}

local handlers = {
    ['PROFILE_UPDATE_NAME'] = function(state, action)
        return R.assoc('name', action.name, state)
    end,

    ['PROFILE_UPDATE_AGE'] = function(state, action)
        return R.assoc('age', action.age, state)
    end,
}

M.reducer = function(state, action)
    state = state or initState
    local handler = handlers[action.type]
    if handler then
        return handler(state, action)
    end
    return state
end

return M
