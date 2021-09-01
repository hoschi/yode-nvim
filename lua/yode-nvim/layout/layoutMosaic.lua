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

--[[
TODO actions:
* shift (possible invisible) float by index to top, others shift one down
* shift win up/down
* push master into first float (so master is free to show other buffer)

* focus other float (probably invisible) -- can be done by Neovim already, is enough for start
* close window and delete seditor
* replace master with seditor of float and close float
* swap floating and master
* move win to other tab??
]]

local createWindowState = R.always({
    -- Neovim props. Provide every single one, even when some layouts treat
    -- it as static. Like "x" of Mosaic is calculated from config, rather
    -- individually.
    id = nil,
    height = nil,
    width = nil,
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

local reducerFunctions = {
    [sharedActions.actionNames.CREATE_FLOATING_WINDOW] = function(state, a)
        local text = vim.api.nvim_buf_get_lines(a.bufId, 0, -1, true)
        -- FIXME that is not enough, must shift other windows down by editor height
        return h.over(
            windowsLens,
            R.prepend(R.mergeDeepRight(createWindowState(), {
                height = #text,
                y = 0,
                data = {
                    bufId = a.bufId,
                    visible = true,
                    initialConfig = {
                        relative = 'editor',
                        focusable = true,
                        -- TODO activate when we implement layouting
                        -- border = 'single',
                    },
                },
            })),
            state
        )
    end,
    [sharedActions.actionNames.CLOSE_WINDOW] = function(state, a)
        -- FIXME that is not enough, must change y coordinates of windows after the removed one
        return h.over(
            windowsLens,
            R.when(R.propEq('id', id), R.assocPath({ 'data', 'visible' }, false)),
            state
        )
    end,
}
M.reducer = createReducer(nil, reducerFunctions)

M.stateToNeovim = function(state)
    local log = logging.create('stateToNeovim')
    -- TODO calculate by `state.config.columnWidthMax/Min` and window width
    local x, width = getSeditorWidth()

    local windowsUpdated = h.map(function(window)
        local winConfig = R.merge({
            col = x,
            row = window.y,
            width = width,
        }, R.pick(
            { 'relative', 'height' },
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
            end
        else
            if window.id == nil then
                vim.api.nvim_win_hide(window.id)
                log.debug('removed window', window.id)
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
