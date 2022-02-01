local defaultConfig = require('yode-nvim.defaultConfig')
local yodeNvim = require('yode-nvim.init')

local eq = assert.are.same

describe('yode-nvim (init.lua)', function()
    before_each(function()
        yodeNvim.config = {}
    end)

    it('setup without options', function()
        yodeNvim.setup()
        eq(defaultConfig, yodeNvim.config)
    end)

    it('setup with overrides', function()
        yodeNvim.setup({ log = { level = 'debug' } })
        eq({ log = { level = 'debug' } }, yodeNvim.config)
    end)
end)
