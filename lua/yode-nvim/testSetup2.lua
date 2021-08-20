local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local createSeditor = require('yode-nvim.createSeditor')

local textTopLevelNode = h.multiLineTextToArray([[
export default async function () {
    return {
        relative:
            'editor' +
            'fooooooooooooooooooo' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar' +
            'baaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaar',
    }
}
]])

local testSetup2 = function()
    local log = logging.create('testSetup2')
    vim.cmd('e ./testData/small.js')
    local fileBufferId = vim.fn.bufnr('%')

    createSeditor({
        fileBufferId = fileBufferId,
        text = textTopLevelNode,
        windowY = 0,
        windowHeight = #textTopLevelNode,
        startLine = 3,
    })

    log.debug('state:', store.getState())
end

return testSetup2
