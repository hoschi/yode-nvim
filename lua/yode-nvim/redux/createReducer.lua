local createReducer = function(initialState, reducerFunctions)
    return function(stateParam, action)
        local state = stateParam or initialState
        return reducerFunctions[action.type] and reducerFunctions[action.type](state, action)
            or state
    end
end

return createReducer
