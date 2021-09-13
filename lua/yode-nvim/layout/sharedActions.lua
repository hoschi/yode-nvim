local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = { actions = {}, actionNames = {} }

M.actionNames.CREATE_FLOATING_WINDOW = 'CREATE_FLOATING_WINDOW'
M.actions.createFloatingWindow = R.pipe(
    R.pick({ 'tabId', 'bufId', 'data' }),
    R.assoc('type', M.actionNames.CREATE_FLOATING_WINDOW)
)

M.actionNames.ON_WINDOW_CLOSED = 'ON_WINDOW_CLOSED'
M.actions.onWindowClosed = R.pipe(
    R.pick({ 'tabId', 'winId' }),
    R.assoc('type', M.actionNames.ON_WINDOW_CLOSED)
)

M.actionNames.ON_VIM_RESIZED = 'ON_VIM_RESIZED'
M.actions.onVimResized = R.pipe(R.pick({ 'tabId' }), R.assoc('type', M.actionNames.ON_VIM_RESIZED))

return M
