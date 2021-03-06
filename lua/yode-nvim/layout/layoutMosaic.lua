local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local logging = require('yode-nvim.logging')
local createReducer = require('yode-nvim.redux.createReducer')
local sharedActions = require('yode-nvim.layout.sharedActions')
local updateFloatStatusLineText = require('yode-nvim.updateFloatStatusLineText')

local M = { name = 'mosaic', actions = {}, selectors = {} }

local getSeditorWidth = function()
    local x = math.floor(vim.o.columns / 2)
    local width = vim.o.columns - x
    return x, width
end

local createWindowState = R.always({
    -- Neovim props. Provide every single one, even when some layouts treat
    -- it as static. Like "x" of Mosaic is calculated from config, rather
    -- individually.
    id = nil,
    height = nil,
    width = nil,
    relative = 'editor',
    border = nil,
    -- NOTICE: this is col/row from Neovim renamed to be feature ready when yode
    -- windows can be rendered from external GUI without a grid
    x = nil,
    y = nil,
    -- NOTICE: you can get the managed buffer from a window easily. You can't
    -- get the window of a buffer id easily as well. It is ambigous as buffers
    -- can be visible in more windows. Even when you try to focus on floating
    -- windows only, a user/plugin can show the same buffer as well in a
    -- floating window. To make things easier we save tha buffer/window
    -- relation by here.
    bufId = nil,
    -- `data` contains our props, so they can't collide with (changed in
    -- future) Neovim data props. Set by layout, or not. Mosaic tracks order
    -- in stack for example, probably not needed in Expose.
    data = {},
})

local windowsLens = h.lensProp('windows')
local yLens = h.lensProp('y')
local findWindowIndexBySomeId = function(state, a)
    return R.findIndex(
        R.anyPass(
            a.bufId == nil and R.F or R.propEq('bufId', a.bufId),
            a.winId == nil and R.F or R.propEq('id', a.winId)
        ),
        state.windows
    )
end
local createStatusBarWinConfig = R.mergeDeepRight({
    relative = 'win',
    height = 1,
    col = 0,
    focusable = false,
    style = 'minimal',
    -- keep it above main window
    zindex = 51,
})

local setDirty = function(state)
    return R.assoc('isDirty', state.id ~= vim.api.nvim_get_current_tabpage(), state)
end

--local normalBorderStyle = { '1', '2', '3', '4', '5', '6', '7', '8' }
local normalBorderStyle = { ' ', ' ', ' ', ' ', '', '', '', ' ' }
-- WARNING you can't remove the right side only for last border style, this
-- creates an exception in Neovim. At the moment all windows have a right side
-- to come around this.
-- TODO create bug ticket
local lastBorderStyle = { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' }

local setBorderStyle = h.mapWithIndex(function(win, i, all)
    return i < #all and R.assoc('border', normalBorderStyle, win)
        or R.assoc('border', lastBorderStyle, win)
end)

local createStatusBar = function(seditorWindowId, seditorBufferId, seditorWindowConfig)
    local log = logging.create('createStatusBar')
    local winConfig = createStatusBarWinConfig({
        win = seditorWindowId,
        width = seditorWindowConfig.width + 1,
        row = seditorWindowConfig.height,
        noautocmd = true,
    })
    log.debug(winConfig)
    local statusBufId = vim.api.nvim_create_buf(false, true)

    updateFloatStatusLineText(seditorBufferId, statusBufId)
    local id = vim.api.nvim_open_win(statusBufId, false, winConfig)
    vim.wo[id].wrap = false
    vim.wo[id].winhl = 'Normal:Tabline'

    vim.cmd(
        string.format(
            "autocmd BufModifiedSet <buffer=%s> :lua require('yode-nvim.updateFloatStatusLineText')(%s, %s)",
            seditorBufferId,
            seditorBufferId,
            statusBufId
        )
    )

    return id, statusBufId
end

local shiftWinBottom = function(log, state, currentWinIndex)
    local otherWinIndex = #state.windows
    local currentWin = state.windows[currentWinIndex]
    local otherWin = state.windows[otherWinIndex]
    log.trace(currentWinIndex, currentWin, otherWin)
    return h.over(
        windowsLens,
        R.pipe(
            R.without({ currentWin }),
            h.map(h.over(yLens, R.subtract(R.__, currentWin.height + 1))),
            R.append(
                h.set(
                    yLens,
                    (otherWin.y + otherWin.height + 1) - (currentWin.height + 1),
                    currentWin
                )
            ),
            setBorderStyle
        ),
        state
    )
end

local shiftWinTop = function(log, state, currentWinIndex)
    local otherWinIndex = 1
    local currentWin = state.windows[currentWinIndex]
    local otherWin = state.windows[otherWinIndex]
    log.trace(currentWinIndex, currentWin, otherWin)
    return h.over(
        windowsLens,
        R.pipe(
            R.without({ currentWin }),
            h.map(h.over(yLens, R.add(R.__, currentWin.height + 1))),
            R.update(otherWinIndex, h.set(yLens, currentWin.height + 2, otherWin)),
            R.prepend(h.set(yLens, 1, currentWin)),
            setBorderStyle
        ),
        state
    )
end

M.selectors.getWindowBySomeId = function(_, selectorArgs, state)
    local idx = findWindowIndexBySomeId(state, selectorArgs)
    return idx ~= nil and R.path({ 'windows', idx }, state)
end

local reducerFunctions = {
    [sharedActions.actionNames.CREATE_FLOATING_WINDOW] = function(state, a)
        local text = vim.api.nvim_buf_get_lines(a.bufId, 0, -1, true)
        return h.over(
            windowsLens,
            R.pipe(
                h.map(h.over(yLens, R.add(#text + 1))),
                R.prepend(R.mergeDeepRight(createWindowState(), {
                    height = #text,
                    y = 1,
                    bufId = a.bufId,
                    data = {
                        visible = true,
                        initialConfig = {
                            focusable = true,
                        },
                    },
                })),
                setBorderStyle
            ),
            state
        )
    end,
    [sharedActions.actionNames.REMOVE_FLOATING_WINDOW] = function(state, a)
        local log = logging.create('removeFloatingWindow')
        local closedWinIndex = findWindowIndexBySomeId(state, a)

        if closedWinIndex < 0 then
            log.trace('no managed window', a)
            return state
        end

        local closedWin = state.windows[closedWinIndex]
        local shiftBy = 1 + closedWin.height
        log.trace('removing window from state:', a.winId, closedWin.id, shiftBy)
        return R.pipe(
            h.over(
                windowsLens,
                R.pipe(
                    R.without({ closedWin }),
                    R.splitAt(closedWinIndex),
                    h.over(h.lensIndex(2), h.map(h.over(yLens, R.subtract(R.__, shiftBy)))),
                    R.flatten(),
                    setBorderStyle
                )
            ),
            setDirty
        )(state)
    end,
    [sharedActions.actionNames.SHIFT_WIN_DOWN] = function(state, a)
        local log = logging.create('shiftWinDown')
        if #state.windows <= 1 then
            log.trace('not possible', #state.windows)
            return state
        end
        local currentWinIndex = findWindowIndexBySomeId(state, a)
        local otherWinIndex = currentWinIndex + 1
        if otherWinIndex > #state.windows then
            return shiftWinTop(log, state, currentWinIndex)
        end

        local currentWin = state.windows[currentWinIndex]
        local otherWin = state.windows[otherWinIndex]
        log.trace(currentWinIndex, currentWin, otherWin)
        return h.over(
            windowsLens,
            R.pipe(
                R.update(currentWinIndex, h.set(yLens, currentWin.y, otherWin)),
                R.update(
                    otherWinIndex,
                    h.set(yLens, currentWin.y + otherWin.height + 1, currentWin)
                ),
                setBorderStyle
            ),
            state
        )
    end,
    [sharedActions.actionNames.SHIFT_WIN_UP] = function(state, a)
        local log = logging.create('shiftWinUp')
        if #state.windows <= 1 then
            log.trace('not possible', #state.windows)
            return state
        end
        local currentWinIndex = findWindowIndexBySomeId(state, a)
        local otherWinIndex = currentWinIndex - 1
        if otherWinIndex < 1 then
            return shiftWinBottom(log, state, currentWinIndex)
        end
        local currentWin = state.windows[currentWinIndex]
        local otherWin = state.windows[otherWinIndex]
        log.trace(currentWinIndex, currentWin, otherWin)
        return h.over(
            windowsLens,
            R.pipe(
                R.update(otherWinIndex, h.set(yLens, otherWin.y, currentWin)),
                R.update(
                    currentWinIndex,
                    h.set(yLens, otherWin.y + currentWin.height + 1, otherWin)
                ),
                setBorderStyle
            ),
            state
        )
    end,
    [sharedActions.actionNames.SHIFT_WIN_BOTTOM] = function(state, a)
        local log = logging.create('shiftWinBottom')
        if #state.windows <= 1 then
            log.trace('not possible')
            return state
        end
        local currentWinIndex = findWindowIndexBySomeId(state, a)
        return shiftWinBottom(log, state, currentWinIndex)
    end,
    [sharedActions.actionNames.SHIFT_WIN_TOP] = function(state, a)
        local log = logging.create('shiftWinTop')
        if #state.windows <= 1 then
            log.trace('not possible')
            return state
        end
        local currentWinIndex = findWindowIndexBySomeId(state, a)
        return shiftWinTop(log, state, currentWinIndex)
    end,
    [sharedActions.actionNames.CONTENT_CHANGED] = function(state, a)
        local log = logging.create('contentChanged')
        local changedWinIndex = findWindowIndexBySomeId(state, a)
        if changedWinIndex < 0 then
            log.trace('no managed window', a)
            return state
        end

        local changedWin = state.windows[changedWinIndex]
        local bufId = vim.api.nvim_win_get_buf(changedWin.id)
        local shiftBy = #vim.api.nvim_buf_get_lines(bufId, 0, -1, true) - changedWin.height
        if shiftBy == 0 then
            log.debug('height still the same, aborting', a)
            return state
        end

        log.trace('relayouting after content change in window:', a.winId, changedWin.id, shiftBy)
        return R.pipe(
            h.over(
                windowsLens,
                R.pipe(
                    R.adjust(R.assoc('height', changedWin.height + shiftBy), changedWinIndex),
                    R.splitAt(changedWinIndex + 1),
                    h.over(h.lensIndex(2), h.map(h.over(yLens, R.add(shiftBy)))),
                    R.flatten(),
                    setBorderStyle
                )
            ),
            setDirty
        )(state)
    end,
    [sharedActions.actionNames.ON_VIM_RESIZED] = function(state)
        return setDirty(state)
    end,
}
M.reducer = createReducer(nil, reducerFunctions)

M.stateToNeovim = function(state)
    local log = logging.create('stateToNeovim')
    local x, width = getSeditorWidth()
    local currentWinId = vim.fn.win_getid()

    local windowsUpdated = h.map(function(window)
        local winConfig = R.merge({
            col = x,
            row = window.y,
            width = width,
        }, R.pick({ 'relative', 'height', 'border' }, window))

        if window.data.visible then
            if window.id == nil then
                local winConfigFinal = R.merge(window.data.initialConfig, winConfig)
                local id = h.showBufferInFloatingWindow(window.bufId, winConfigFinal)
                vim.wo[id].winhl = 'FloatBorder:Tabline'
                vim.cmd('redraw')
                local statusId, statusBufferId = createStatusBar(id, window.bufId, winConfigFinal)
                log.debug('created window', id, statusId)
                return R.pipe(
                    R.assoc('id', id),
                    R.assoc('statusId', statusId),
                    R.assoc('statusBufferId', statusBufferId),
                    R.dissocPath({ 'data', 'initialConfig' })
                )(window)
            else
                log.debug('updating window', window.id)
                if vim.api.nvim_win_is_valid(window.id) then
                    vim.api.nvim_win_set_config(window.id, winConfig)
                    vim.cmd('redraw')
                    if window.id == currentWinId then
                        -- NOTICE this is needed when a dirty tab gets visible, the
                        -- cursor is in a floating window and the height grows. As
                        -- the window is always as big as the content scrolling to
                        -- the bottom sets the very top at the first line again.
                        vim.cmd('normal zb')
                    end
                else
                    log.debug('windown not valid!', window.id)
                end

                if vim.api.nvim_win_is_valid(window.statusId) then
                    vim.api.nvim_win_set_config(
                        window.statusId,
                        createStatusBarWinConfig({
                            width = winConfig.width + 1,
                            row = winConfig.height,
                            win = window.id,
                        })
                    )
                else
                    log.debug('windown not valid!', window.statusId)
                end

                return window
            end
        else
            log.error('`visible` is not implemented yet!')
        end

        return window
    end, state.windows)

    return R.pipe(R.assoc('windows', windowsUpdated), R.assoc('isDirty', false))(state)
end

return M
