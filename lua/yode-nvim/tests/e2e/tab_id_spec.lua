local h = require('yode-nvim.helper')

local eq = assert.are.same

describe('tab id', function()
    it('should be set after startup for first tab', function()
        eq(1, h.getTabId(0))
    end)

    it('should work with closed and new tabs', function()
        vim.cmd('tabnew')
        vim.cmd('tabnew')
        vim.cmd('tabnew')
        eq(4, h.getTabId(0))
        eq(1, h.getTabId(1))
        eq(2, h.getTabId(2))
        eq(3, h.getTabId(3))
        eq(4, h.getTabId(4))

        vim.cmd('tabclose')
        eq(3, h.getTabId(0))
        eq(1, h.getTabId(1))
        eq(2, h.getTabId(2))
        eq(3, h.getTabId(3))

        vim.cmd('tabfirst')
        vim.cmd('tabclose')
        eq(2, h.getTabId(0))
        eq(2, h.getTabId(1))
        eq(3, h.getTabId(2))
    end)
end)
