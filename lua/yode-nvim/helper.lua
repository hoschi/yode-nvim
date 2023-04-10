local R = require('yode-nvim.deps.lamda.dist.lamda')
local M = {}

M.map = R.curry2(function(fn, data)
    if vim.tbl_islist(data) then
        return R.map(fn, data)
    end

    return R.zipObj(R.keys(data), R.map(fn, data))
end)

local mapWithArrayIndex = function(fn, data)
    return R.reduce(function(acc, cur)
        return R.append(fn(cur, #acc + 1, data), acc)
    end, {}, data)
end

local mapWithObjectKey = function(fn, data)
    return R.reduce(function(acc, key)
        return R.assoc(key, fn(data[key], key, data), acc)
    end, {}, M.keysSorted(data))
end

M.mapWithIndex = R.curry2(function(fn, data)
    if vim.tbl_islist(data) then
        return mapWithArrayIndex(fn, data)
    end

    return mapWithObjectKey(fn, data)
end)

M.keysSorted = R.pipe(R.keys, R.sort(R.lt))

M.maxPositiveNumber = math.pow(2, 1024)
--M.maxNegative = M.maxPositiveNumber * -1

M.noop = function() end
M.isNotNil = R.complement(R.isNil)

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
    R.ifElse(R.isEmpty, R.always(0), R.reduce(R.min, M.maxPositiveNumber))
)
M.BUF_LINES_OP_ADD = 'BUF_LINES_OP_ADD'
M.BUF_LINES_OP_CHANGE = 'BUF_LINES_OP_CHANGE'
M.BUF_LINES_OP_CHANGE_ADD = 'BUF_LINES_OP_CHANGE_ADD'
M.BUF_LINES_OP_DELETE = 'BUF_LINES_OP_DELETE'
M.getOperationOfBufLinesEvent = function(first, last, data)
    if first == last then
        -- e.g. paste one yanked line in normal mode
        return M.BUF_LINES_OP_ADD, #data
    elseif R.isEmpty(data) then
        return M.BUF_LINES_OP_DELETE, last - first
    elseif #data == (last - first) then
        -- single line changes as well is visual block changes
        return M.BUF_LINES_OP_CHANGE, #data
    else
        -- NOTICE this is also the case for new lines entered in insert mode
        return M.BUF_LINES_OP_CHANGE_ADD, #data
    end
end

M.getBuffers = function(showHidden)
    local bufIds = vim.api.nvim_list_bufs()
    return showHidden and bufIds or R.filter(vim.api.nvim_buf_is_loaded, bufIds)
end

M.showBufferInFloatingWindow = function(bufId, winConfig)
    local id = vim.api.nvim_open_win(bufId, true, winConfig)
    vim.wo.wrap = false
    return id
end

M.nextIndex = function(idx, data)
    if data == nil or #data <= 0 then
        return nil
    end

    return idx + 1 <= #data and idx + 1 or 1
end

M.prevIndex = function(idx, data)
    if data == nil or #data <= 0 then
        return nil
    end

    return idx - 1 >= 1 and idx - 1 or #data
end

M.readFile = function(file)
    local f = assert(io.open(file, 'rb'))
    local content = f:read('*all')
    f:close()
    return content
end

M.makeVimTable = function(data)
    return R.reduce(function(acc, key)
        return R.assoc(R.toString(key), data[key], acc)
    end, {}, R.keys(data or {}))
end

return M
