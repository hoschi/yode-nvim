local R = require('yode-nvim.deps.lamda.dist.lamda')

local M = { actions = {}, actionNames = {} }

M.actionNames.CREATE_FLOATING_WINDOW = 'CREATE_FLOATING_WINDOW'
M.actions.createFloatingWindow = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'bufId', 'data' }),
    R.assoc('type', M.actionNames.CREATE_FLOATING_WINDOW)
)

M.actionNames.REMOVE_FLOATING_WINDOW = 'REMOVE_FLOATING_WINDOW'
M.actions.removeFloatingWindow = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.REMOVE_FLOATING_WINDOW)
)

M.actionNames.CONTENT_CHANGED = 'CONTENT_CHANGED'
M.actions.contentChanged = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.CONTENT_CHANGED)
)

M.actionNames.ON_VIM_RESIZED = 'ON_VIM_RESIZED'
M.actions.onVimResized = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId' }),
    R.assoc('type', M.actionNames.ON_VIM_RESIZED)
)

return M
