local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local logging = require('yode-nvim.logging')
local createReducer = require('yode-nvim.redux.createReducer')
local sharedActions = require('yode-nvim.layout.sharedActions')

local M = { name = 'mosaic', actions = {} }

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
    -- `data` contains our props, so they can't collide with (changed in
    -- future) Neovim data props. Set by layout, or not. Mosaic tracks order
    -- in stack for example, probably not needed in Expose.
    data = {},
})

local windowsLens = h.lensProp('windows')
local yLens = h.lensProp('y')

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

local reducerFunctions = {
    [sharedActions.actionNames.CREATE_FLOATING_WINDOW] = function(state, a)
        local text = vim.api.nvim_buf_get_lines(a.bufId, 0, -1, true)
        return h.over(
            windowsLens,
            R.pipe(
                h.map(h.over(yLens, R.add(#text + 1))),
                R.prepend(R.mergeDeepRight(createWindowState(), {
                    height = #text,
                    y = 0,
                    data = {
                        bufId = a.bufId,
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
    [sharedActions.actionNames.ON_WINDOW_CLOSED] = function(state, a)
        local log = logging.create('onWindowClosed')
        local closedWinIndex = R.findIndex(R.propEq('id', a.winId), state.windows)

        if closedWinIndex < 0 then
            log.trace('no managed window', a)
            return state
        end

        local closedWin = state.windows[closedWinIndex]
        local shiftBy = 1 + #vim.api.nvim_buf_get_lines(closedWin.seditorBufferId, 0, -1, true)
        log.trace('removing window from state:', a.winId, closedWin.id, shiftBy)
        return h.over(
            windowsLens,
            R.pipe(
                R.without({ closedWin }),
                R.splitAt(closedWinIndex),
                h.over(h.lensIndex(2), h.map(h.over(yLens, R.subtract(R.__, shiftBy)))),
                R.flatten(),
                setBorderStyle
            ),
            state
        )
    end,
    [sharedActions.actionNames.ON_VIM_RESIZED] = function(state)
        return state
    end,
}
M.reducer = createReducer(nil, reducerFunctions)

M.stateToNeovim = function(state)
    local log = logging.create('stateToNeovim')
    local x, width = getSeditorWidth()

    local windowsUpdated = h.map(function(window)
        local winConfig = R.merge({
            col = x,
            row = window.y,
            width = width,
        }, R.pick(
            { 'relative', 'height', 'border' },
            window
        ))

        if window.data.visible then
            if window.id == nil then
                id = h.showBufferInFloatingWindow(
                    window.data.bufId,
                    R.merge(window.data.initialConfig, winConfig)
                )
                log.debug('created window', id)
                return R.pipe(
                    R.assoc('id', id),
                    R.dissocPath({ 'data', 'bufId' }),
                    R.dissocPath({ 'data', 'initialConfig' })
                )(window)
            else
                log.debug('updating window', window.id)
                vim.api.nvim_win_set_config(window.id, winConfig)
                return window
            end
        else
            if window.id == nil then
                vim.api.nvim_win_hide(window.id)
                log.debug('hide window', window.id)
                return R.dissoc('id', window)
            else
                log.debug('nothing todo')
                return window
            end
        end
    end, state.windows)

    return R.assoc('windows', windowsUpdated, state)
end

return M
