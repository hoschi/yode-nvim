local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local store = storeBundle.store
local seditors = storeBundle.seditors
local layout = storeBundle.layout
local R = require('yode-nvim.deps.lamda.dist.lamda')
local seditor = require('yode-nvim.seditor')
local sharedLayoutActions = require('yode-nvim.layout.sharedActions')
local diffLib = require('yode-nvim.diffLib')

local M = {}

local ZOMBIE_COUNTDOWN_VALUE = 11
-- FIXME remove `isZombie` and replace with `zombie` which stores all data?
-- Would at least give better logging
local zombies = {}
local decrementZombie = h.over(h.lensProp('countdown'), R.subtract(R.__, 1))

local handleZombies = function(fileBufferId, editLineCount)
    local log = logging.create('handleZombies')
    local layoutActions = {}

    -- ignoring one line changes for now, doesn't seem worth diffing
    -- TODO do it for zombies with only one line as well, skipped because of
    -- lazyness. One line changes are often the fast pace typing events.
    if editLineCount <= 1 then
        log.debug('not processing one line changes')
        return zombies, {}
    end

    zombiesConnected = R.filter(R.pathEq({ 'seditor', 'fileBufferId' }, fileBufferId))(
        R.values(zombies)
    )
    if #zombiesConnected <= 0 then
        log.debug('no zombies for file buffer', fileBufferId)
        return zombies, {}
    end

    log.trace('processing zombies', zombiesConnected)
    local fileText = R.join('\n', vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))
    local updatedZombies = h.map(function(zombie)
        local seditorBufferId = zombie.seditor.seditorBufferId
        local diffData = diffLib.diff(fileText, zombie.text)
        local blocks = diffLib.findConnectedBlocks(diffData)
        if #blocks <= 0 then
            log.debug('nothing to recover for', seditorBufferId)
            return zombie
        end

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        log.debug('recover!', seditorData)
        local lines = R.split('\n', seditorData.text)
        local indentCount = h.getIndentCount(lines)

        local cleanedLines = h.map(R.drop(indentCount), lines)
        seditors.actions.changeData({
            seditorBufferId = seditorBufferId,
            data = { isZombie = false, indentCount = indentCount, startLine = seditorData.startLine },
        })
        vim.schedule(function()
            -- FIXME do this in middleware
            vim.bo[seditorBufferId].modifiable = true

            vim.api.nvim_buf_set_lines(seditorBufferId, 0, -1, true, cleanedLines)
        end)
        layoutActions = R.append(
            sharedLayoutActions.actions.contentChanged({
                tabId = vim.api.nvim_get_current_tabpage(),
                bufId = seditorBufferId,
            }),
            layoutActions
        )
        return R.assoc('countdown', 0, zombie)
    end, zombiesConnected)

    local processedZombies = R.reduce(function(newZombies, zombie)
        local updatedZombie = decrementZombie(zombie)
        local sed = seditors.selectors.getSeditorById(updatedZombie.seditor.seditorBufferId)
        if updatedZombie.countdown <= 0 then
            if sed.isZombie then
                log.debug(
                    'removing really dead zombie from state and nvim',
                    updatedZombie.seditor.seditorBufferId
                )
                vim.schedule(function()
                    vim.cmd('bd! ' .. updatedZombie.seditor.seditorBufferId)
                end)
            end

            log.debug('removing zombie from checklist', updatedZombie.seditor.seditorBufferId)
            return R.dissoc(updatedZombie.seditor.seditorBufferId, newZombies)
        end

        log.debug('updating zombie', updatedZombie)
        return R.assoc(zombie.seditor.seditorBufferId, updatedZombie, newZombies)
    end, zombies, updatedZombies)

    if updateLayout then
        vim.schedule(function()
            layout.actions.syncTabLayoutToNeovim()
        end)
    end

    return processedZombies, layoutActions
end

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
        vim.api.nvim_buf_set_lines(
            seditorWindow.fileBufferId,
            firstline + seditorWindow.startLine,
            lastline + seditorWindow.startLine,
            true,
            lineData
        )
        seditor.checkIndentCount(seditorWindow)

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

local onFileBufferLines = function(_event, bufId, tick, firstline, lastline, newLastline)
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
        zombies, zombieLayoutActions = handleZombies(bufId, editLineCount)
        vim.schedule(function()
            R.forEach(store.dispatch, zombieLayoutActions)
        end)
        return
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
                seditors.actions.changeData({
                    seditorBufferId = sed.seditorBufferId,
                    data = { isZombie = true },
                })
                zombies = R.assoc(sed.seditorBufferId, {
                    seditor = sed,
                    text = R.pipe(
                        sed.indentCount
                                and h.map(R.concat(h.createWhiteSpace(sed.indentCount)))
                            or R.identity,
                        R.join('\n')
                    )(
                        vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
                    ),
                    countdown = ZOMBIE_COUNTDOWN_VALUE,
                }, zombies)
                -- FIXME do this in middleware
                vim.bo[sed.seditorBufferId].modifiable = false
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
                seditors.actions.changeData({
                    seditorBufferId = sed.seditorBufferId,
                    data = { isZombie = true },
                })
                zombies = R.assoc(sed.seditorBufferId, {
                    seditor = sed,
                    text = R.pipe(
                        sed.indentCount
                                and h.map(R.concat(h.createWhiteSpace(sed.indentCount)))
                            or R.identity,
                        R.join('\n')
                    )(
                        vim.api.nvim_buf_get_lines(sed.seditorBufferId, 0, -1, true)
                    ),
                    countdown = ZOMBIE_COUNTDOWN_VALUE,
                }, zombies)
                -- FIXME do this in middleware
                vim.bo[sed.seditorBufferId].modifiable = false
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

    zombies, zombieLayoutActions = handleZombies(bufId, editLineCount)
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
        layout.actions.multiTabRemoveSeditor({
            bufId = sed.seditorBufferId,
        })
        return
    end

    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    if not R.isEmpty(sedsConnected) then
        deactivateBuffer(log, bufId)
        R.forEach(function(connectedEditor)
            deactivateBuffer(log, connectedEditor.seditorBufferId)
            seditors.actions.removeSeditor({ seditorBufferId = connectedEditor.seditorBufferId })
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
        end, sedsConnected)
        return
    end

    log.debug("didn't need to do anything: ", bufId)
end

return M
