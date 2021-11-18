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

describe('diffLib -', function()
    it('indentation', function()
        local file, seditor = readFiles('./testData/diff/indentation')
        --local file, seditor = readFiles('./testData/diff/excerpt')

        local diffData = diffLib.diff(file, seditor)
        local blocks = diffLib.findConnectedBlocks(diffData)
        eq(1, #blocks)
        --eq(false, blocks[1])
        eq(text2, blocks[1].text)
        eq(59, #blocks[1].tokens)

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        --eq(false, seditorData)
        eq(text2, seditorData.text)
        eq(48, seditorData.startLine)

        eq(373, #diffData.diffTokens)
    end)
end)
