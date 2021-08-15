local R = require('yode-nvim.deps.lamda.dist.lamda')
local M = {}

M.map = R.curry2(function(fn, data)
    if vim.tbl_islist(data) then
        return R.map(fn, data)
    end

    return R.zipObj(R.keys(data), R.map(fn, data))
end)

M.maxPositiveNumber = math.pow(2, 1024)
--M.maxNegative = M.maxPositiveNumber * -1

M.noop = function() end

M.lensPath = R.identity
M.lensProp = R.of
M.lensIndex = R.of

M.view = R.path
M.set = R.assocPath
M.over = R.curry3(function(lens, fn, data)
    return R.pipe(M.view(lens), fn, R.assocPath(lens, R.__, data))(data)
end)

M.multiLineTextToArray = R.pipe(R.split('\n'), R.init)
M.createWhiteSpace = R.pipe(R.repeat_(' '), R.join(''))
M.getIndentCount = R.pipe(
    -- remove empty lines first, they are never indented
    R.reject(R.isEmpty),
    -- NOTICE M.map(R.pipe(R.match("^%s"), R.head, R.length)) didn't work because "^" doesn't work with R.match
    M.map(function(s)
        return #s:match('^%s*')
    end),
    R.reduce(R.min, M.maxPositiveNumber)
)
M.BUF_LINES_OP_ADD = 'BUF_LINES_OP_ADD'
M.BUF_LINES_OP_CHANGE = 'BUF_LINES_OP_CHANGE'
M.BUF_LINES_OP_CHANGE_ADD = 'BUF_LINES_OP_CHANGE_ADD'
M.BUF_LINES_OP_DELETE = 'BUF_LINES_OP_DELETE'
M.getOperationOfBufLinesEvent = function(first, last, data)
    if first == last then
        -- e.g. paste one yanked line in normal mode
        return M.BUF_LINES_OP_ADD
    elseif R.isEmpty(data) then
        return M.BUF_LINES_OP_DELETE
    elseif #data == (last - first) then
        -- single line changes as well is visual block changes
        return M.BUF_LINES_OP_CHANGE
    else
        -- NOTICE this is also the case for new lines entered in insert mode
        return M.BUF_LINES_OP_CHANGE_ADD
    end
end

return M
