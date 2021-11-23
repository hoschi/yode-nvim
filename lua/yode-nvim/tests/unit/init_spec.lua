local yodeNvim = require('yode-nvim.init')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store

local eq = assert.are.same

describe('yode-nvim (init.lua)', function()
    it('redux state', function()
        eq({ seditors = {}, layout = { tabs = {} } }, store.getState())
        yodeNvim.yodeRedux()
        eq({
            seditors = {
                [105] = {
                    seditorBufferId = 105,
                    fileBufferId = 205,
                    startLine = 11 + 6,
                    indentCount = 4,
                    zombie = nil,
                },
            },
            layout = { tabs = {} },
        }, store.getState())
    end)
end)
