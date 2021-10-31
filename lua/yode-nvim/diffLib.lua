local diffLibOrig = require('yode-nvim.deps.diff.diff.lua.diff')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')

local M = {}

M.diff = function(old, new, separator)
    local diffData = diffLibOrig.diff(old, new, separator)

    local arr = {}
    for i, tokenRecord in ipairs(diffData) do
        arr = R.append({ index = i, token = tokenRecord[1], status = tokenRecord[2] }, arr)
    end

    local oldTokens = h.mapWithIndex(function(token, i)
        return { index = i, token = token }
    end, diffLibOrig.split(
        old,
        separator
    ))

    return { diffTokens = arr, oldTokens = oldTokens }
end

local findConnectedBlocks = function(diffData)
    -- FIXME concat tokens to lines and count ratio of "same" vs in/out per line. a block continues as long the last line has a ration above 50%. But that doesn't work if one line in between doesn't match at all.
    --
    -- FIXME OR create groups by searching for the next "same" token. add tokens to the this group till. count the continous tokens which are not "same". if count is 10, close group and search for next "same" and repeat the process. if "same" token is again reached while count is less than 10, reset counter and continue with current group.
    local seditorDiffTokenBlock = R.filter(R.propEq('status', 'same'), diffData.diffTokens)
    return R.drop(1, seditorDiffTokenBlock)
end

M.findTextBlock = function(diffData)
    local seditorDiffTokenBlock = findConnectedBlocks(diffData)
    local startLine = R.pipe(
        R.take(seditorDiffTokenBlock[1].index),
        R.pluck('token'),
        R.join(''),
        R.split('\n'),
        R.length,
        R.subtract(R.__, 1)
    )(diffData.oldTokens)

    local text = R.pipe(R.pluck('token'), R.join(''))(seditorDiffTokenBlock)

    return { text = text, startLine = startLine }
end

return M
