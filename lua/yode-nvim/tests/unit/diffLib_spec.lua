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

local text2 = [[
    plugin.registerCommand(
        'YodeCreateSeditor',
        async () => {
            await createSeditor(nvim, '1111', 0, 20 == 50)

            await createSeditor(nvim, '2222', 21, 10)
            await createSeditor(nvim, '3333', 32, 15)
        },
        { sync: false }
    )]]

local text3 = [[
        relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
]]

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

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1 .. '\n', seditorData.text)
        eq(10, seditorData.startLine)
    end)

    it('leading new lines', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = '\n\n' .. seditor
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq('}\n\n' .. text1, blocks[1].text)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq('}\n\n' .. text1, seditorData.text)
        eq(8, seditorData.startLine)
    end)

    it('trailing white space', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = seditor .. '    '
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text1, blocks[1].text)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text1, seditorData.text)
        eq(10, seditorData.startLine)
    end)

    it('leading white space', function()
        local file, seditor = readFiles('./testData/diff/excerpt')

        seditor = '    ' .. seditor
        local diffData = diffLib.diff(file, seditor)

        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq('}\n\n' .. text1, blocks[1].text)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq('}\n\n' .. text1, seditorData.text)
        eq(8, seditorData.startLine)
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

    it('indentation', function()
        local file, seditor = readFiles('./testData/diff/indentation')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        eq(text2, blocks[1].text)
        eq(59, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(text2, seditorData.text)
        eq(48, seditorData.startLine)

        eq(373, #diffData.diffTokens)
    end)

    it('change in small js', function()
        local file, seditor = readFiles('./testData/diff/changeInSmallJs')
        -- TODO make the matching algorithm better to find text3 instead!
        local foundText = [[

    return {
        relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',]]

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(2, #blocks)
        eq(foundText, blocks[1].text)
        eq(21, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        eq(foundText, seditorData.text)
        eq(7, seditorData.startLine)

        eq(81, #diffData.diffTokens)
    end)
end)
