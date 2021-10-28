local diffLibOrig = require('yode-nvim.deps.diff.diff.lua.diff')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = {}

M.diff = function(old, new, separator)
    local diffData = diffLibOrig.diff(old, new, separator)

    local arr = {}
    for i, tokenRecord in ipairs(diffData) do
        arr = R.append(tokenRecord, arr)
    end

    return arr
end

return M
