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

M.actionNames.ON_TAB_CLOSED = 'ON_TAB_CLOSED'
M.actions.onTabClosed = R.pipe(
    R.merge({ syncToNeovim = false }),
    R.pick({ 'syncToNeovim', 'tabId' }),
    R.assoc('type', M.actionNames.ON_TAB_CLOSED)
)

M.actionNames.SHIFT_WIN_DOWN = 'SHIFT_WIN_DOWN'
M.actions.shiftWinDown = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.SHIFT_WIN_DOWN)
)

M.actionNames.SHIFT_WIN_UP = 'SHIFT_WIN_UP'
M.actions.shiftWinUp = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.SHIFT_WIN_UP)
)

M.actionNames.SHIFT_WIN_BOTTOM = 'SHIFT_WIN_BOTTOM'
M.actions.shiftWinBottom = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.SHIFT_WIN_BOTTOM)
)

M.actionNames.SHIFT_WIN_TOP = 'SHIFT_WIN_TOP'
M.actions.shiftWinTop = R.pipe(
    R.merge({ syncToNeovim = true }),
    R.pick({ 'syncToNeovim', 'tabId', 'winId', 'bufId' }),
    R.assoc('type', M.actionNames.SHIFT_WIN_TOP)
)

return M
