local R = require('yode-nvim.deps.lamda')
local M = {}

M.map = function(fn, data)
    if vim.tbl_islist(data) then
        return R.map(fn, data)
    end

    return R.zipObj(R.keys(data), R.map(fn, data))
end

return M
