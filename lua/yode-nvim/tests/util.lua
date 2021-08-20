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

M.typeKeyCombo = function(text)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(text, true, false, true), 'n', true)
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
    return R.zipObj(
        bufIds,
        h.map(function(bufId)
            return vim.fn.bufname(bufId)
        end, bufIds)
    )
end

return M
