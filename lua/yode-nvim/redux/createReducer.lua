local createReducer = function(initalState, handlers)
    return function(stateParam, action)
        local state = stateParam or initalState
        return handlers[action.type] and handlers[action.type](state, action) or state
    end
end

return createReducer
