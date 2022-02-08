local PlenaryLog = require('plenary.log')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local M = {}
local isDebug = require('yode-nvim.isDebug')

-- https://github.com/nvim-lua/plenary.nvim/blob/80c9e00a6d7632fdebd959a18452604b862a6ebf/lua/plenary/log.lua#L14

local base
local modes = { 'trace', 'debug', 'info', 'warn', 'error', 'fatal' }

M.setup = function(options)
    local conf = vim.tbl_deep_extend('force', options, {
        plugin = 'yode-nvim',
        level = isDebug and isDebug or 'warn',
    })
    base = PlenaryLog.new(conf)
end

M.create = function(name)
    local prefix = name .. ':'
    return R.reduce(function(obj, mode)
        return R.assoc(mode, function(...)
            return base[mode]('\n', '🔹' .. prefix, ...)
        end, obj)
    end, base, modes)
end

return M
