local layoutMap = require('yode-nvim.layout.layoutMap')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

describe('layout', function()
    it('layoutMap', function()
        eq('mosaic', R.keys(layoutMap)[1])
        eq('table', type(layoutMap.mosaic))
    end)
end)
