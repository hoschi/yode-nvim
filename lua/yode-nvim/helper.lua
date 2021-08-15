local R = require('yode-nvim.deps.lamda.dist.lamda')
local M = {}

M.map = R.curry2(function(fn, data)
    if vim.tbl_islist(data) then
        return R.map(fn, data)
    end

    return R.zipObj(R.keys(data), R.map(fn, data))
end)

return M
