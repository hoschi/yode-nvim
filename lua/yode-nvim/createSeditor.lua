local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors
local R = require('yode-nvim.deps.lamda.dist.lamda')
local changeSyncing = require('yode-nvim.changeSyncing')

local M = {}

local getSeditorWidth = function()
    local x = math.floor(vim.o.columns / 2)
    local width = vim.o.columns - x
    return x, width
end

local getFileBufferName = function(fileBufferId, seditorBufferId)
    local ext = vim.fn.expand('#' .. fileBufferId .. ':e')
    if ext ~= '' then
        ext = '.' .. ext
    end
    return 'yode://' .. vim.fn.bufname(fileBufferId) .. ':' .. seditorBufferId .. ext
end

local createSeditor = function(opts)
    local log = logging.create('createSeditor')
    log.debug(opts.fileBufferId, #opts.text, opts.text[1])
    local indentCount = h.getIndentCount(opts.text)
    local cleanedText = h.map(R.drop(indentCount), opts.text)
    --vim.cmd("call neomake#log#debug('## before creating buffer " .. vim.fn.bufnr('%') .. "')")
    local seditorBufferId = vim.api.nvim_create_buf(true, false)
    seditors.actions.initSeditor({
        seditorBufferId = seditorBufferId,
        data = {
            fileBufferId = opts.fileBufferId,
            visible = true,
            startLine = opts.startLine,
            indentCount = indentCount,
        },
    })
    --vim.cmd("call neomake#log#debug('## after creating buffer " .. vim.fn.bufnr('%') .. "')")
    vim.bo[seditorBufferId].ft = vim.bo[opts.fileBufferId].ft
    vim.bo[seditorBufferId].buftype = 'acwrite'
    -- TODO workaround! it seems this isn't set by my editorconfig plugin for
    -- these buffers. seditors get inserted instead of spaces in seditors. In
    -- normal file buffers it spaces get inserted.
    vim.bo[seditorBufferId].expandtab = true

    vim.api.nvim_buf_set_lines(seditorBufferId, 0, -1, true, cleanedText)
    vim.bo[seditorBufferId].modified = false

    local windowX, width = getSeditorWidth()
    local winId = vim.api.nvim_open_win(seditorBufferId, true, {
        relative = 'editor',
        row = opts.windowY,
        col = windowX,
        width = width,
        height = opts.windowHeight,
        focusable = true,
        -- TODO activate when we implement layouting
        -- border = 'single',
    })
    vim.wo.wrap = false

    vim.cmd('file ' .. getFileBufferName(opts.fileBufferId, seditorBufferId))

    changeSyncing.subscribeToBuffer()

    return winId, seditorBufferId
end

return createSeditor
