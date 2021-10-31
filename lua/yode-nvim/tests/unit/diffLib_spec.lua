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

describe('diffLib -', function()
    it('excerpt', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        local diffData = diffLib.diff(file, seditor)
        eq(371, #diffData.diffTokens)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(86, #blocks[1].tokens)
        eq(text1, blocks[1].text)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)
    end)

    it('rename in seditor', function()
        local file, seditor = readFiles('./testData/diff/renameInSeditor')

        local diffData = diffLib.diff(file, seditor)
        eq(381, #diffData.diffTokens)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(86, #blocks[1].tokens)
        eq(text1, blocks[1].text)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)
    end)

    it('rename in seditor', function()
        local file, seditor = readFiles('./testData/diff/renameAtEnd')

        local diffData = diffLib.diff(file, seditor)
        eq(379, #diffData.diffTokens)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(90, #blocks[1].tokens)
        eq(text1, blocks[1].text)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)
    end)

    --it('rename in seditor at start and end', function()
    --local file, seditor = readFiles('./testData/diff/renameAtStartAndEnd')

    --local diffData = diffLib.diff(file, seditor)
    --eq(381, #diffData.diffTokens)

    --local blocks = diffLib.findConnectedBlocks(diffData)
    --eq(1, #blocks)
    --eq(80, #blocks[1].tokens)
    --eq(text1, blocks[1].text)

    --local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
    --eq(text1, seditorData.text)
    --eq(10, seditorData.startLine)
    --end)

    -- FIXME test with zero diffTokens
end)
