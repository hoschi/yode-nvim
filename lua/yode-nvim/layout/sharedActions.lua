local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = { actions = {}, actionNames = {} }

M.actionNames.CREATE_FLOATING_WINDOW = 'CREATE_FLOATING_WINDOW'
M.actions.createFloatingWindow = R.pipe(
    R.pick({ 'tabId', 'bufId', 'data' }),
    R.assoc('type', M.actionNames.CREATE_FLOATING_WINDOW)
)

M.actionNames.REMOVE_FLOATING_WINDOW = 'REMOVE_FLOATING_WINDOW'
M.actions.removeFloatingWindow = R.pipe(
    R.pick({ 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.REMOVE_FLOATING_WINDOW)
)

M.actionNames.CONTENT_CHANGED = 'CONTENT_CHANGED'
M.actions.contentChanged = R.pipe(
    R.pick({ 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.CONTENT_CHANGED)
)

M.actionNames.ON_VIM_RESIZED = 'ON_VIM_RESIZED'
M.actions.onVimResized = R.pipe(R.pick({ 'tabId' }), R.assoc('type', M.actionNames.ON_VIM_RESIZED))

return M
