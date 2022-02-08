local logging = require('yode-nvim.logging')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local updateFloatStatusLineText = function(seditorBufferId, statusBufId)
    local log = logging.create('updateFloatStatusLineText')
    local seditorBufName = vim.fn.bufname(seditorBufferId)
    local text = R.pipe(
        R.takeLastWhile(R.complement(R.equals('/'))),
        R.dropLastWhile(R.complement(R.equals('.'))),
        R.init
    )(seditorBufName)

    if vim.bo[seditorBufferId].modified then
        text = '+' .. text
    end
    vim.api.nvim_buf_set_lines(statusBufId, 0, -1, false, { text })

    log.debug(statusBufId, text)
end

return updateFloatStatusLineText
