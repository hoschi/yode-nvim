local tutil = require('yode-nvim.tests.util')
local diffLib = require('yode-nvim.diffLib')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

describe('diffLib -', function()
    it('excerpt', function()
        local file = [[
/**
 * My super function!
 */
export default async function () {
    return {
        relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
    }
}

//
//
//
//
//
//
//
//
//
//
//

// foo]]

        local seditor = [[
export default async function () {
    return {
        relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
    }
}]]

        local diffData = diffLib.diff(file, seditor)
        eq(75, #diffData)

        local sameText = R.pipe(
            h.map(function(record)
                return record[2] ~= 'same' and '' or record[1]
            end),
            R.join('')
        )(diffData)

        eq(seditor, sameText)
    end)
end)
