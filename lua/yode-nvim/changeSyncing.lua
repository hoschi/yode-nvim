local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local layout = storeBundle.layout
local R = require('yode-nvim.deps.lamda.dist.lamda')
local seditor = require('yode-nvim.seditor')
local sharedLayoutActions = require('yode-nvim.layout.sharedActions')
local fileEditor = require('yode-nvim.fileEditor')

local M = {}

local activeBuffers = {}
-- NOTICE when setting lines through "nvim_buf_set_lines" in another buffer,
-- "vim.fn.bufnr('%')" is always the same buffer as bufId in the on_lines
-- event. so we need a "current buffer" which is the "current focused by user
-- buffer"
local currentBuffer

local deactivateBuffer = function(log, bufId)
    if activeBuffers[bufId] then
        log.debug('UNsubscribe from buffer:', bufId)
        activeBuffers = R.dissoc(bufId, activeBuffers)
    end
    if currentBuffer == bufId then
        currentBuffer = nil
        log.debug('Reset current buffer')
    end
end

local onBufferDetach = function(_, bufId)
    local log = logging.create('onBufferDetach')
    log.debug('detach', bufId)
    M.unsubscribeFromBuffer(bufId, true)
end

local onBufferReload = function(_, bufId)
    local log = logging.create('onBufferReload')
    log.debug('reload', bufId)

    fileEditor.handlePossibleFileContentChange(bufId)
    log.debug("didn't need to do anything: ", bufId)
end

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
        on_reload = onBufferReload,
    })
end

local onSeditorBufferLines = function(_, bufId, _, firstline, lastline, newLastline)
    local log = logging.create('onSeditorBufferLines')
    if currentBuffer ~= bufId then
        deactivateBuffer(log, bufId)
        return true
    end

    local linedata = vim.api.nvim_buf_get_lines(bufId, firstline, newLastline, true)
    local seditorWindow = seditors.selectors.getSeditorById(bufId)
    local operationType = h.getOperationOfBufLinesEvent(firstline, lastline, linedata)
    local lineData = seditorWindow.indentCount
            and h.map(
                R.concat(h.createWhiteSpace(seditorWindow.indentCount)),
                linedata
            )
        or linedata

    log.debug(bufId, operationType, {
        firstline = firstline,
        lastline = lastline,
        newLastline = newLastline,
        lineData = lineData,
    })
    -- NOTICE needed, because `:h textlock` is active and you get a E523 without it
    vim.schedule(function()
        local fileBufferFirstLine = firstline + seditorWindow.startLine
        local fileBufferLastLine = lastline + seditorWindow.startLine
        local lineLength = lastline - firstline
        local dataLength = #linedata
        vim.api.nvim_buf_set_lines(
            seditorWindow.fileBufferId,
            fileBufferFirstLine,
            fileBufferLastLine,
            true,
            lineData
        )
        seditor.checkIndentCount(seditorWindow)

        local sedsConnected = seditors.selectors.getSeditorsConnected(seditorWindow.fileBufferId)
        R.forEach(function(sed)
            if sed.seditorBufferId == bufId then
                log.debug('-- SKIP buf:', sed.seditorBufferId)
                return
            end
            local seditorLength = #vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
            local seditorStartLine = sed.startLine
            local seditorEndLine = seditorStartLine + seditorLength
            log.debug('-- buf:', sed.seditorBufferId, {
                seditorStartLine = seditorStartLine,
                seditorEndLine = seditorEndLine,
                seditorLength = seditorLength,
            })
            if operationType == h.BUF_LINES_OP_DELETE then
                if fileBufferLastLine <= seditorStartLine then
                    -- change was above sed
                    --
                    -- delete: shift
                    log.debug('---- shift by', -lineLength)
                    seditors.actions.changeStartLine({
                        seditorBufferId = sed.seditorBufferId,
                        amount = -lineLength,
                    })
                    return
                elseif fileBufferFirstLine >= seditorEndLine then
                    -- change was below window
                    return
                elseif
                    (
                        (fileBufferFirstLine >= seditorStartLine)
                        and (fileBufferLastLine <= seditorEndLine)
                    )
                    and not (
                        (fileBufferFirstLine == seditorStartLine)
                        and (fileBufferLastLine == seditorEndLine)
                    )
                then
                    -- TODO change was in sed, we don't support nested seditors at the moment
                    return
                elseif
                    (
                        (fileBufferLastLine <= seditorEndLine)
                        or (fileBufferFirstLine >= seditorStartLine)
                    )
                    or (
                        (fileBufferFirstLine <= seditorStartLine)
                        and (fileBufferLastLine >= seditorEndLine)
                    )
                then
                    -- TODO we don't support nested seditors at the moment
                    -- the first two OR cases: changes lay "half" in seditor
                    -- "half" outside, so boundary was removed
                    --
                    -- second third OR case: changes spans over the whole window
                    return
                end
                log.debug('########## unhandled op ##########')
            elseif operationType == h.BUF_LINES_OP_ADD then
                if fileBufferFirstLine <= seditorStartLine then
                    -- change was above sed
                    --
                    -- add: shift
                    log.debug('---- shift by', dataLength)
                    seditors.actions.changeStartLine({
                        seditorBufferId = sed.seditorBufferId,
                        amount = dataLength,
                    })
                    return
                elseif fileBufferFirstLine >= seditorEndLine then
                    -- change was below window
                    return
                elseif
                    (fileBufferFirstLine > seditorStartLine)
                    and (fileBufferFirstLine < seditorEndLine)
                then
                    -- TODO we don't support nested seditors at the moment
                    -- change was in sed
                    return
                end
                log.debug('########## unhandled op ##########')
            elseif operationType == h.BUF_LINES_OP_CHANGE_ADD then
                if fileBufferLastLine <= seditorStartLine then
                    -- change was above sed
                    --
                    -- changeAdd: shift by added portion
                    log.debug('---- shift by', dataLength - lineLength)
                    seditors.actions.changeStartLine({
                        seditorBufferId = sed.seditorBufferId,
                        amount = dataLength - lineLength,
                    })
                    return
                elseif fileBufferFirstLine >= seditorEndLine then
                    -- change was below window
                    return
                elseif
                    (fileBufferFirstLine >= seditorStartLine)
                    and (fileBufferLastLine <= seditorEndLine)
                then
                    -- TODO we don't support nested seditors at the moment
                    return
                elseif
                    (fileBufferFirstLine < seditorStartLine)
                    and (fileBufferLastLine > seditorEndLine)
                then
                    -- TODO we don't support nested seditors at the moment
                    -- change encloses sed fully
                    --
                    -- findOrRemove: check if this window was removed, if yes:
                    -- remove it from state and relayout
                    -- changeAdd: findOrRemove, relayout by return value
                    -- NOTICE I don't know how to trigger this with normal editor
                    -- commands, but it is the case when
                    -- `vim.api.nvim_buf_set_lines` is used, e.g. in a formatter
                    -- plugin
                    return
                end
                log.debug('########## unhandled op ##########')
            elseif operationType == h.BUF_LINES_OP_CHANGE then
                if fileBufferLastLine <= seditorStartLine then
                    -- change was above sed
                    return
                elseif fileBufferFirstLine >= seditorEndLine then
                    -- change was below window
                    return
                elseif
                    (fileBufferFirstLine >= seditorStartLine)
                    and (fileBufferLastLine <= seditorEndLine)
                then
                    -- TODO we don't support nested seditors at the moment
                    -- change was in sed
                    return
                elseif
                    (
                        (fileBufferLastLine <= seditorEndLine)
                        or (fileBufferFirstLine >= seditorStartLine)
                    )
                    or (
                        (fileBufferFirstLine <= seditorStartLine)
                        and (fileBufferLastLine >= seditorEndLine)
                    )
                then
                    -- TODO we don't support nested seditors at the moment
                    -- the first two OR cases: changes lay "half" in seditor
                    -- "half" outside, so boundary was removed
                    --
                    -- second and third OR case: changes spans over the whole window
                    --
                    -- change: apply changes for the lines of swindow
                    return
                end
                log.debug('########## unhandled op ##########')
            end
        end, sedsConnected)

        -- NOTICE this event is ignored at the moment for performance reasons
        -- as we don't need to handle it with the default layout!
        if operationType ~= h.BUF_LINES_OP_CHANGE then
            layout.actions.multiTabContentChanged({
                tabId = vim.api.nvim_get_current_tabpage(),
                bufId = bufId,
            })
        end
    end)
end

local onFileBufferLines = function(_, bufId, tick, firstline, lastline, newLastline)
    local log = logging.create('onFileBufferLines')
    if currentBuffer ~= bufId then
        deactivateBuffer(log, bufId)
        return true
    end
    if tick == nil then
        return
    end

    local zombieLayoutActions
    local layoutActions = {}
    local linedata = vim.api.nvim_buf_get_lines(bufId, firstline, newLastline, true)
    local lineLength = lastline - firstline
    local dataLength = #linedata
    local operationType, editLineCount = h.getOperationOfBufLinesEvent(
        firstline,
        lastline,
        linedata
    )
    log.debug(
        bufId,
        'lines:',
        operationType,
        firstline,
        lastline,
        newLastline,
        editLineCount,
        linedata
    )

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if R.isEmpty(sedsConnected) then
        zombieLayoutActions = fileEditor.handleZombies(bufId, editLineCount)
        vim.schedule(function()
            R.forEach(store.dispatch, zombieLayoutActions)
        end)
        return
    end
    local syncModified = function(seditorBufferId)
        local isModified = vim.bo[bufId].modified
        log.debug('set modified', seditorBufferId, isModified)
        vim.bo[seditorBufferId].modified = isModified
    end

    R.forEach(function(sed)
        local seditorLength = #vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
        local seditorStartLine = sed.startLine
        local seditorEndLine = seditorStartLine + seditorLength

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
                    syncModified(sed.seditorBufferId)
                end)
                layoutActions = R.append(
                    sharedLayoutActions.actions.contentChanged({
                        tabId = vim.api.nvim_get_current_tabpage(),
                        bufId = sed.seditorBufferId,
                    }),
                    layoutActions
                )
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
                -- delete: zombie, relayout

                log.debug('---- add editor to zombie list (delete op)', sed.seditorBufferId)
                seditors.actions.softlyKillSeditor({
                    seditorBufferId = sed.seditorBufferId,
                })
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
                    syncModified(sed.seditorBufferId)
                end)
                layoutActions = R.append(
                    sharedLayoutActions.actions.contentChanged({
                        tabId = vim.api.nvim_get_current_tabpage(),
                        bufId = sed.seditorBufferId,
                    }),
                    layoutActions
                )
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
                layoutActions = R.append(
                    sharedLayoutActions.actions.contentChanged({
                        tabId = vim.api.nvim_get_current_tabpage(),
                        bufId = sed.seditorBufferId,
                    }),
                    layoutActions
                )
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
                -- findOrRemove: check if this window was removed, if yes:
                -- remove it from state and relayout
                -- changeAdd: findOrRemove, relayout by return value
                -- NOTICE I don't know how to trigger this with normal editor
                -- commands, but it is the case when
                -- `vim.api.nvim_buf_set_lines` is used, e.g. in a formatter
                -- plugin

                log.debug('---- add editor to zombie list (change add op)', sed.seditorBufferId)
                seditors.actions.softlyKillSeditor({
                    seditorBufferId = sed.seditorBufferId,
                })
                return
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
                    syncModified(sed.seditorBufferId)
                end)
                return
            elseif
                ((lastline <= seditorEndLine) or (firstline >= seditorStartLine))
                or ((firstline <= seditorStartLine) and (lastline >= seditorEndLine))
            then
                -- the first two OR cases: changes lay "half" in seditor
                -- "half" outside, so boundary was removed
                --
                -- second and third OR case: changes spans over the whole window
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
                    syncModified(sed.seditorBufferId)
                end)
                return
            end
            log.debug('########## unhandled op ##########')
        end
    end, sedsConnected)

    zombieLayoutActions = fileEditor.handleZombies(bufId, editLineCount)
    vim.schedule(function()
        -- NOTICE refresh state, in case some were removed
        R.forEach(seditor.checkIndentCount, seditors.selectors.getSeditorsConnected(bufId))
        if R.isEmpty(layoutActions) and R.isEmpty(zombieLayoutActions) then
            log.debug('no relayouting needed')
            -- needs to run in vim.schedule as well, as we need to wait for the
            -- "change buf lines" calls, which are also scheduled
        else
            local actions = R.concat(layoutActions, zombieLayoutActions)
            log.debug('relayouting!', #actions)
            R.forEach(store.dispatch, actions)
        end
    end)
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

    fileEditor.handleZombies(bufId, nil, function(seditorBufferId)
        vim.schedule(function()
            layout.actions.multiTabContentChanged({
                tabId = vim.api.nvim_get_current_tabpage(),
                bufId = seditorBufferId,
            })
            -- content hasn't changed by the action, under certain circumstances. E.g. reading
            -- the file buffer with `e!` from disc detaches the buffer and resubscribes to its
            -- changes where we sync the seditors to the current not modified state.
            vim.bo[seditorBufferId].modified = vim.bo[bufId].modified
        end)
    end)

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if not R.isEmpty(sedsConnected) then
        activateBuffer('file editor', bufId, onFileBufferLines)
        return
    end

    log.debug("didn't subscribe to buffer: ", bufId)
end

M.unsubscribeFromBuffer = function(bufId, softKillIt)
    local log = logging.create('unsubscribeFromBuffer')

    log.debug('checking:', { bufId = bufId, currentBuffer = currentBuffer })

    local sed = seditors.selectors.getSeditorById(bufId)
    if sed then
        deactivateBuffer(log, bufId)
        if softKillIt then
            log.debug('add editor to zombie list', bufId)
            seditors.actions.softlyKillSeditor({
                seditorBufferId = bufId,
            })
        else
            seditors.actions.removeSeditor({ seditorBufferId = sed.seditorBufferId })
            layout.actions.multiTabRemoveSeditor({
                bufId = sed.seditorBufferId,
            })
        end
        return
    end

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if not R.isEmpty(sedsConnected) then
        deactivateBuffer(log, bufId)
        R.forEach(function(connectedEditor)
            deactivateBuffer(log, connectedEditor.seditorBufferId)
            if softKillIt then
                log.debug('add editor to zombie list', connectedEditor.seditorBufferId)
                seditors.actions.softlyKillSeditor({
                    seditorBufferId = connectedEditor.seditorBufferId,
                })
            else
                seditors.actions.removeSeditor({
                    seditorBufferId = connectedEditor.seditorBufferId,
                })
                layout.actions.multiTabRemoveSeditor({
                    bufId = connectedEditor.seditorBufferId,
                })
                vim.cmd('bd! ' .. connectedEditor.seditorBufferId)
                log.debug(
                    string.format(
                        'after deleting buf %d the buf %d is visible',
                        connectedEditor.seditorBufferId,
                        vim.fn.bufnr('%')
                    )
                )
            end
        end, sedsConnected)
        return
    end

    log.debug("didn't need to do anything: ", bufId)
end

return M
