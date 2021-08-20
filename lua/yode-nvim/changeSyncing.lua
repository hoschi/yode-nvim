local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local R = require('yode-nvim.deps.lamda.dist.lamda')
local seditor = require('yode-nvim.seditor')

local M = {}

local activeBuffers = {}
-- NOTICE when setting lines through "nvim_buf_set_lines" in another buffer,
-- "vim.fn.bufnr('%')" is always the same buffer as bufId in the on_lines
-- event. so we need a "current buffer" which is the "current focused by user
-- buffer"
local currentBuffer

local activateBuffer = function(editorType, bufId, onLines)
    local log = logging.create('activateBuffer')
    currentBuffer = bufId
    if activeBuffers[bufId] then
        log.debug('already subscribed to:', bufId, editorType)
        return
    end
    log.debug('subscribe to:', bufId, editorType)
    activeBuffers = R.assoc(bufId, true, activeBuffers)
    vim.api.nvim_buf_attach(bufId, false, {
        on_lines = onLines,
        on_detach = onBufferDetach,
    })
end

local deactivateBuffer = function(log, bufId)
    log.debug('UNsubscribe from buffer:', bufId)
    activeBuffers = R.dissoc(bufId, activeBuffers)
    if currentBuffer == bufId then
        currentBuffer = nil
        log.debug('Reset current buffer')
    end
end

local onBufferDetach = function(_event, bufId)
    local log = logging.create('onBufferDetach')
    deactivateBuffer(log, bufId)
end

local onSeditorBufferLines = function(_event, bufId, _tick, firstline, lastline, newLastline)
    local log = logging.create('onSeditorBufferLines')
    if currentBuffer ~= bufId then
        deactivateBuffer(log, bufId)
        return true
    end

    local linedata = vim.api.nvim_buf_get_lines(bufId, firstline, newLastline, true)
    local seditorWindow = seditors.selectors.getSeditorById(bufId)
    local lineData = seditorWindow.indentCount
            and h.map(
                R.concat(h.createWhiteSpace(seditorWindow.indentCount)),
                linedata
            )
        or linedata

    log.debug(bufId, {
        firstline = firstline,
        lastline = lastline,
        newLastline = newLastline,
        lineData = lineData,
    })
    -- NOTICE needed, because `:h textlock` is active and you get a E523 without it
    vim.schedule(function()
        vim.api.nvim_buf_set_lines(
            seditorWindow.fileBufferId,
            firstline + seditorWindow.startLine,
            lastline + seditorWindow.startLine,
            true,
            lineData
        )
        seditor.checkIndentCount(seditorWindow)
    end)
end

local onFileBufferLines = function(_event, bufId, tick, firstline, lastline, newLastline)
    local log = logging.create('onFileBufferLines')
    if currentBuffer ~= bufId then
        deactivateBuffer(log, bufId)
        return true
    end
    if tick == nil then
        return
    end

    -- TODO not implemented yet, not important at the moment
    local needsRelayout = {}

    local linedata = vim.api.nvim_buf_get_lines(bufId, firstline, newLastline, true)
    local operationType = h.getOperationOfBufLinesEvent(firstline, lastline, linedata)
    log.debug(bufId, 'lines:', operationType, firstline, lastline, newLastline, linedata)

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if R.isEmpty(sedsConnected) then
        return
    end

    R.forEach(function(sed)
        local seditorLength = #vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
        local seditorStartLine = sed.startLine
        local seditorEndLine = seditorStartLine + seditorLength

        local lineLength = lastline - firstline
        local dataLength = #linedata
        local evData = {
            startLine = firstline - seditorStartLine,
            endLine = lastline - seditorStartLine,
        }
        log.debug('-- buf:', sed.seditorBufferId, {
            seditorStartLine = seditorStartLine,
            seditorEndLine = seditorEndLine,
            seditorLength = seditorLength,
            evStartLine = evData.startLine,
            evEndLine = evData.endLine,
        })

        -- IMPORTANT. above/below cases need to be first, so following
        -- conditions can be easier
        if operationType == h.BUF_LINES_OP_DELETE then
            if lastline <= seditorStartLine then
                -- change was above sed
                --
                -- delete: shift
                log.debug('---- shift by', -lineLength)
                seditors.actions.changeStartLine({
                    seditorBufferId = sed.seditorBufferId,
                    amount = -lineLength,
                })
                return
            elseif firstline >= seditorEndLine then
                -- change was below window
                return
            elseif
                ((firstline >= seditorStartLine) and (lastline <= seditorEndLine))
                and not ((firstline == seditorStartLine) and (lastline == seditorEndLine))
            then
                -- change was in sed, but not the whole window
                --
                -- delete: apply changes and relayout
                log.debug('---- delete lines and relayout', evData)
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(
                        sed.seditorBufferId,
                        evData.startLine,
                        evData.endLine,
                        true,
                        linedata
                    )
                end)
                needsRelayout = R.append(sed, needsRelayout)
                return
            elseif
                ((lastline <= seditorEndLine) or (firstline >= seditorStartLine))
                or ((firstline <= seditorStartLine) and (lastline >= seditorEndLine))
            then
                -- the first two OR cases: changes lay "half" in seditor
                -- "half" outside, so boundary was removed
                --
                -- second third OR case: changes spans over the whole window
                --
                -- delete: remove sed, relayout
                log.debug('---- delete sed/buffer and relayout', sed.seditorBufferId)
                seditors.actions.removeSeditor({ seditorBufferId = sed.seditorBufferId })
                vim.schedule(function()
                    vim.cmd('bd! ' .. sed.seditorBufferId)
                end)
                needsRelayout = R.append(sed, needsRelayout)
                return
            end
            log.debug('########## unhandled op ##########')
        elseif operationType == h.BUF_LINES_OP_ADD then
            if firstline <= seditorStartLine then
                -- change was above sed
                --
                -- add: shift
                log.debug('---- shift by', dataLength)
                seditors.actions.changeStartLine({
                    seditorBufferId = sed.seditorBufferId,
                    amount = dataLength,
                })
                return
            elseif firstline >= seditorEndLine then
                -- change was below window
                return
            elseif (firstline > seditorStartLine) and (firstline < seditorEndLine) then
                -- change was in sed
                --
                -- add: apply changes and relayout
                local indentCount = seditor.checkLineDataIndentCount(sed, linedata)
                local lineData = h.map(R.drop(indentCount), linedata)
                log.debug('---- add lines and relayout', evData, lineData)
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(
                        sed.seditorBufferId,
                        evData.startLine,
                        evData.endLine,
                        true,
                        lineData
                    )
                end)
                needsRelayout = R.append(sed, needsRelayout)
                return
            end
            log.debug('########## unhandled op ##########')
        elseif operationType == h.BUF_LINES_OP_CHANGE_ADD then
            if lastline <= seditorStartLine then
                -- change was above sed
                --
                -- changeAdd: shift by added portion
                log.debug('---- shift by', dataLength - lineLength)
                seditors.actions.changeStartLine({
                    seditorBufferId = sed.seditorBufferId,
                    amount = dataLength - lineLength,
                })
                return
            elseif firstline >= seditorEndLine then
                -- change was below window
                return
            elseif (firstline >= seditorStartLine) and (lastline <= seditorEndLine) then
                -- change was in sed
                --
                -- changeAdd: apply changes and relayout
                local indentCount = seditor.checkLineDataIndentCount(sed, linedata)
                local lineData = h.map(R.drop(indentCount), linedata)
                log.debug('---- changeAdd lines and relayout', evData, lineData)
                needsRelayout = R.append(sed, needsRelayout)
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(
                        sed.seditorBufferId,
                        evData.startLine,
                        evData.endLine,
                        true,
                        lineData
                    )
                end)
                return
            elseif (firstline < seditorStartLine) and (lastline > seditorEndLine) then
                -- change encloses sed fully
                --
                -- // findOrRemove: check if this window was removed, if yes: remove it from state and relayout
                -- changeAdd: findOrRemove, relayout by return value
                -- TODO implement "find" logic later, just remove for now
                log.debug('---- delete sed/buffer and relayout', sed.seditorBufferId)
                seditors.actions.removeSeditor({ seditorBufferId = sed.seditorBufferId })
                vim.schedule(function()
                    vim.cmd('bd! ' .. sed.seditorBufferId)
                end)
                needsRelayout = R.append(sed, needsRelayout)
            end
            log.debug('########## unhandled op ##########')
        elseif operationType == h.BUF_LINES_OP_CHANGE then
            if lastline <= seditorStartLine then
                -- change was above sed
                return
            elseif firstline >= seditorEndLine then
                -- change was below window
                return
            elseif (firstline >= seditorStartLine) and (lastline <= seditorEndLine) then
                -- change was in sed
                --
                -- change: apply changes
                local indentCount = seditor.checkLineDataIndentCount(sed, linedata)
                local lineData = h.map(R.drop(indentCount), linedata)
                log.debug('------ change lines', evData, lineData)
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(
                        sed.seditorBufferId,
                        evData.startLine,
                        evData.endLine,
                        true,
                        lineData
                    )
                end)
                return
            elseif
                ((lastline <= seditorEndLine) or (firstline >= seditorStartLine))
                or ((firstline <= seditorStartLine) and (lastline >= seditorEndLine))
            then
                -- the first two OR cases: changes lay "half" in seditor
                -- "half" outside, so boundary was removed
                --
                -- second third OR case: changes spans over the whole window
                --
                -- change: apply changes for the lines of swindow
                local restrictedEvData = {
                    startLine = evData.startLine < 0 and 0 or evData.startLine,
                    endLine = evData.endLine > seditorLength and seditorLength or evData.endLine,
                }

                local restrictedLineData = R.pipe(
                    R.drop(evData.startLine < 0 and evData.startLine * -1 or 0),
                    R.take(restrictedEvData.endLine - restrictedEvData.startLine)
                )(linedata)

                local indentCount = seditor.checkLineDataIndentCount(sed, restrictedLineData)
                restrictedLineData = h.map(R.drop(indentCount), restrictedLineData)
                log.debug('---- change restricted lines', restrictedEvData, restrictedLineData)
                vim.schedule(function()
                    vim.api.nvim_buf_set_lines(
                        sed.seditorBufferId,
                        restrictedEvData.startLine,
                        restrictedEvData.endLine,
                        true,
                        restrictedLineData
                    )
                end)
                return
            end
            log.debug('########## unhandled op ##########')
        end
    end, sedsConnected)

    vim.schedule(function()
        -- NOTICE refresh state, in case some were removed
        R.forEach(seditor.checkIndentCount, seditors.selectors.getSeditorsConnected(bufId))
    end)

    local relayout = function()
        log.debug('relayout:', R.pluck('seditorBufferId', needsRelayout))
    end
    if not R.isEmpty(needsRelayout) then
        relayout()
    end
end

M.subscribeToBuffer = function()
    local log = logging.create('subscribeToBuffer')
    local bufId = vim.fn.bufnr('%')
    log.debug('checking:', { bufId = bufId, currentBuffer = currentBuffer }, activeBuffers)

    local sed = seditors.selectors.getSeditorById(bufId)
    if sed then
        activateBuffer('seditor', bufId, onSeditorBufferLines)
        return
    end

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if not R.isEmpty(sedsConnected) then
        activateBuffer('file editor', bufId, onFileBufferLines)
        return
    end

    log.debug("didn't subscribe to buffer: ", bufId)
end

M.unsubscribeFromBuffer = function(bufId)
    local log = logging.create('unsubscribeFromBuffer')

    log.debug('checking:', { bufId = bufId, currentBuffer = currentBuffer })

    local sed = seditors.selectors.getSeditorById(bufId)
    if sed then
        deactivateBuffer(log, bufId)
        seditors.actions.removeSeditor({ seditorBufferId = sed.seditorBufferId })
        return
    end

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if not R.isEmpty(sedsConnected) then
        deactivateBuffer(log, bufId)
        R.forEach(function(connectedWin)
            deactivateBuffer(log, connectedWin.seditorBufferId)
            seditors.actions.removeSeditor({ seditorBufferId = connectedWin.seditorBufferId })
            vim.cmd('bd! ' .. connectedWin.seditorBufferId)
            log.debug(
                string.format(
                    'after deleting buf %d the buf %d is visible',
                    connectedWin.seditorBufferId,
                    vim.fn.bufnr('%')
                )
            )
        end, sedsConnected)
        return
    end

    log.debug("didn't need to do anything: ", bufId)
end

return M
