local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = { actions = {}, actionNames = {} }

M.actionNames.CREATE_FLOATING_WINDOW = 'CREATE_FLOATING_WINDOW'
M.actions.createFloatingWindow = R.pipe(
    R.pick({ 'tabId', 'bufId', 'data' }),
    R.assoc('type', M.actionNames.CREATE_FLOATING_WINDOW)
)

-- FIXME doesn't need command, but autocmd subscription
M.actionNames.CLOSE_WINDOW = 'CLOSE_WINDOW'
M.actions.closeWindow = R.pipe(
    R.pick({ 'tabId', 'winId' }),
    R.assoc('type', M.actionNames.CLOSE_WINDOW)
)

return M
