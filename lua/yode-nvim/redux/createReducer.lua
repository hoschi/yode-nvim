local createReducer = function(initalState, reducerFunctions)
    return function(stateParam, action)
        local state = stateParam or initalState
        return reducerFunctions[action.type] and reducerFunctions[action.type](state, action)
            or state
    end
end

return createReducer
