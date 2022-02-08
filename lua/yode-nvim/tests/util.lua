local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')

local M = {}

local eq = assert.are.same

M.assertEmptyBuffer = function(bufIdParam)
    local bufId = bufIdParam or vim.fn.bufnr('%')
    local currentLines = vim.api.nvim_buf_get_lines(bufId, 0, -1, true)
    eq({ '' }, currentLines)
end

M.assertBufferContentString = function(content, bufIdParam)
    local bufId = bufIdParam or vim.fn.bufnr('%')
    local currentLines = vim.api.nvim_buf_get_lines(bufId, 0, -1, true)
    eq(content, R.join('\n', currentLines))
end

M.assertAccessorMap = function(accessor, expected)
    local keys = R.keys(expected)
    return eq(
        expected,
        R.zipObj(
            keys,
            h.map(function(key)
                return accessor[key]
            end, keys)
        )
    )
end

M.getHumanBufferList = function(showHidden)
    local bufIds = h.getBuffers(showHidden)
    -- R.reject returns an array instead of a map, if the buffer ids look like array keys ...
    return R.reduce(function (obj, id)
        local name = vim.fn.bufname(id)
        if R.isEmpty(name) then
            return obj
        else
            return R.assoc(id, name, obj)
        end
    end, {}, bufIds)
end

M.getBuffersModifiedState = function(showHidden)
    local bufIds = h.getBuffers(showHidden)
    -- R.reject returns an array instead of a map, if the buffer ids look like array keys ...
    return R.reduce(function (obj, id)
        return R.assoc(id, vim.bo[id].modified, obj)
    end, {}, bufIds)
end

return M
