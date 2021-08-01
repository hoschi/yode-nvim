--[[ this module exposes the interface of lua functions:
define here the lua functions that activate the plugin ]]

local M = {}
local main = require("yode-nvim.main")
local config = require("yode-nvim.config")

M.yodeNvim = function ()
    print('Hello World')
end

return M
