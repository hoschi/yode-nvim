bit32 = require('bit')
local tutil = require('yode-nvim.tests.util')
local diffLib = require('yode-nvim.diffLib')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

local readFiles = function(path)
    local file = h.readFile(path .. '/file.txt')
    local seditor = h.readFile(path .. '/seditor.txt')
    return file, seditor
end

describe('diffLib -', function()
    it('excerpt', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        local diffData = diffLib.diff(file, seditor)
        eq(371, #diffData.diffTokens)

        local seditorFound = diffLib.findTextBlock(diffData)
        eq(seditor, seditorFound.text)
        eq(10, seditorFound.startLine)
    end)

    --it('rename in seditor', function()
        --local file, seditor = readFiles('./testData/diff/renameInSeditor')

        --local diffData = diffLib.diff(file, seditor)
        --eq(381, #diffData.diffTokens)

        --local seditorFound = diffLib.findTextBlock(diffData)
        --eq(seditor, seditorFound.text)
        --eq(10, seditorFound.startLine)
    --end)

    it('match', function()
        eq(9, diffLib.match('this is my little test', 'my little', 0))
    end)
end)
