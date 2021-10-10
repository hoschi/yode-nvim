-- https://github.com/nvim-lua/plenary.nvim/blob/80c9e00a6d7632fdebd959a18452604b862a6ebf/lua/plenary/log.lua#L9
local isDebug = vim.fn.getenv('DEBUG_YODE')
if isDebug == vim.NIL then
    isDebug = false
end

return isDebug
