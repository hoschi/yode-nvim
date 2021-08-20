local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local createSeditor = require('yode-nvim.createSeditor')

local textTopLevelNode = h.multiLineTextToArray([[
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
}
]])

local textFirstLevelNode = h.multiLineTextToArray([[
    plugin.registerCommand(
        'YodeCreateSeditor',
        async () => {
            await createSeditor(nvim, '1111', 0, 20 == 50)

            await createSeditor(nvim, '2222', 21, 10)
            await createSeditor(nvim, '3333', 32, 15)
        },
        { sync: false }
    )
]])

local textSecondLevelNode = h.multiLineTextToArray([[
        function namedFunction (arg0, arg1, arg2) {
            const foo = arg2 + 'foo'
            if (arg0 > 100) {
                return 'done with: ' + arg0
            }
            return {
                foo,
                bar: namedFunction(arg0 + arg1, 10, 10)
            }
        }
        return namedFunction(0, 1, 12)
]])

local testSetup1 = function()
    local log = logging.create('testSetup1')
    vim.cmd('e ./testData/basic.js')
    local fileBufferId = vim.fn.bufnr('%')

    createSeditor({
        fileBufferId = fileBufferId,
        text = textTopLevelNode,
        windowY = 0,
        windowHeight = #textTopLevelNode,
        startLine = 10,
    })
    createSeditor({
        fileBufferId = fileBufferId,
        text = textFirstLevelNode,
        windowY = #textTopLevelNode + 1,
        windowHeight = #textFirstLevelNode,
        startLine = 48,
    })
    createSeditor({
        fileBufferId = fileBufferId,
        text = textSecondLevelNode,
        windowY = #textTopLevelNode + 1 + #textFirstLevelNode + 1,
        windowHeight = #textSecondLevelNode,
        startLine = 60,
    })

    log.debug('state:', store.getState())
end

return testSetup1
