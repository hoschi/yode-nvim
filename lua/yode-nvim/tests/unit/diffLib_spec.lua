local tutil = require('yode-nvim.tests.util')
local diffLib = require('yode-nvim.diffLib')
local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

local readFiles = function(path)
    local file = h.readFile(path .. '/file.txt')
    local seditor = h.readFile(path .. '/seditor.txt')
    return R.trim(file), R.trim(seditor)
end

local text1 = [[
async function createSeditor(nvim, text, row, height) {
    const buffer = await nvim.createBuffer(false, false)

    const foo = 'bar'
    const width = await getSeditorWidth(nvim)
    const window = await nvim.openWindow(buffer, true, {
        relative: 'editor',
        row,
        col: width,
        width,
        height: height,
        focusable: true,
    })
    return window
}]]

-- FIXME ways to improve:
-- FIXME try tree thingy of current lib if this is better than the plain getEditDistance function I am using atm
-- FIXME try fuzzy finding lib, but increase max char limit of 1024?! https://github.com/swarn/fzy-lua/blob/main/src/fzy_lua.lua
-- FIXME checkout how DFM calculates that a pattern is too long and take the maximum of new tokens an pattern to locate it in group again
-- FIXME read the site and implement a better algorithm https://en.wikipedia.org/wiki/Edit_distance
describe('diffLib -', function()
    it('excerpt', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(371, #diffData.diffTokens)
    end)

    it('rename in seditor', function()
        local file, seditor = readFiles('./testData/diff/renameInSeditor')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(381, #diffData.diffTokens)
    end)

    it('rename in seditor at end', function()
        local file, seditor = readFiles('./testData/diff/renameAtEnd')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)

        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(376, #diffData.diffTokens)
    end)

    it('rename in seditor at start', function()
        local file, seditor = readFiles('./testData/diff/renameAtStart')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)

        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(373, #diffData.diffTokens)
    end)

    it('rename in seditor at start and end', function()
        local file, seditor = readFiles('./testData/diff/renameAtStartAndEnd')

        local diffData = diffLib.diff(file, seditor)
        eq(377, #diffData.diffTokens)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)
    end)

    it('object collapse', function()
        local file, seditor = readFiles('./testData/diff/objectCollapse')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(387, #diffData.diffTokens)
    end)

    it('trailing new lines', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = seditor .. '\n\n'
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1 .. '\n', blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1 .. '\n', seditorData.text)
        eq(10, seditorData.startLine)

        eq(373, #diffData.diffTokens)
    end)

    it('leading new lines', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = '\n\n' .. seditor
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq('\n\n' .. text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq('\n\n' .. text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(372, #diffData.diffTokens)
    end)

    it('trailing white space', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = seditor .. '    '
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(374, #diffData.diffTokens)
    end)

    it('leading white space', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = '    ' .. seditor
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq('\n' .. text1, blocks[1].text)
        eq(87, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq('\n' .. text1, seditorData.text)
        eq(10, seditorData.startLine)

        eq(373, #diffData.diffTokens)
    end)

    it('removed', function()
        local file, seditor = readFiles('./testData/diff/removed')

        local diffData = diffLib.diff(file, seditor)
        eq(325, #diffData.diffTokens)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(0, #blocks)
        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(nil, seditorData)
    end)
end)
