local formatter = require('formatter.format')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors
local changeSyncing = require('yode-nvim.changeSyncing')

local M = {}

local formatBuffer = function(bufId, shouldWrite, callback)
    local currentLines = vim.api.nvim_buf_get_lines(bufId, 0, -1, true)
    return formatter.format('', '', 1, #currentLines, shouldWrite, callback)
end

M.formatWrite = function()
    local log = logging.create('formatWrite')
    local bufId = vim.fn.bufnr('%')

    local sed = seditors.selectors.getSeditorById(bufId)
    if sed then
        log.debug(
            string.format(
                'formatting file buffer %d of seditor %d',
                sed.fileBufferId,
                sed.seditorBufferId
            )
        )
        local cleanup = function()
            -- NOTICE: this is needed to schedule the subscription behind all other
            -- scheduled text changig actions in `changeSyncing.lua`. Without it
            -- you get a 'onSeditorBufferLines' call of the `sed.seditorBufferId` buffer for the
            -- changes of the formatter. This is the case, because you subscribe to
            -- the seditor again, before the changes to the file buffer get
            -- applied.
            vim.schedule(function()
                log.debug('subscribe to seditor (current) buffer again', vim.fn.bufnr('%'))
                changeSyncing.subscribeToBuffer()
            end)
        end

        vim.api.nvim_buf_call(sed.fileBufferId, function()
            log.debug('subscribe to file buffer to sync changes', sed.fileBufferId)
            changeSyncing.subscribeToBuffer()
            formatBuffer(sed.fileBufferId, true, function(err, msg)
                if err then
                    log.error('formatting error:', err, bufId)
                    cleanup()
                    return
                end

                if msg == formatter.statusCodes.BUFFER_CHANGED then
                    log.info('formatting aborted, because buffer changed!', bufId)
                else
                    log.debug('formatting succeeded with msg:', msg, bufId)
                    log.info('succeeded')
                end
                -- TODO `update` call in formatter.nvim doesn't write the file, nor
                -- `write`. Also calling `update` here instead of `write` doesn't
                -- write the file. Only `write` here seems to work, but why?
                vim.cmd('write')
                cleanup()
            end)
        end)
    else
        log.debug('normal buffer')
        -- NOTICE using callback here also, to have the right point in time to
        -- call `write`, which doesn't work always.
        formatBuffer(bufId, true, function(err, msg)
            if err then
                log.error('formatting error:', err, bufId)
                return
            end

            if msg == formatter.statusCodes.BUFFER_CHANGED then
                log.info('formatting aborted, because buffer changed!', bufId)
            else
                log.debug('formatting succeeded with msg:', msg, bufId)
                log.info('succeeded')
            end
            -- TODO same problem as above
            vim.cmd('write')
        end)
    end
end

return M
