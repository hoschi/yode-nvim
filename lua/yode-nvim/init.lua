local defaultConfig = require('yode-nvim.defaultConfig')
local logging = require('yode-nvim.logging')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda')

local M = {
    config = {},
}
local count = 1

-- FIXME remove from here
local bigTable = {
    foo = 'foo',
    bar = 'bar',
    list = { 1, 2, 111, 333, 555, 66, 77, 88 },
    listB = { 20000, 1, 2, 111, 333, 555, 66, 77, 88 },
}
local s = { bar = 'eins', foo = 'test' }
-- FIXME to here

M.setup = function(options)
    M.config = vim.tbl_deep_extend('force', defaultConfig, options or {})
    logging.setup(M.config.log)
end

M.yodeNvim = function()
    local log = logging.create('yodeNvim')
    print('Hello World: ' .. count .. ' --- ' .. M.config.log.level)
    local cp = h.map(function(v)
        return v .. '???'
    end, s)
    log.debug('my stuff', cp)
    count = count + 1
end

return M
