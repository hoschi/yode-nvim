local h = require('yode-nvim.helper')
local logging = require('yode-nvim.logging')
local storeBundle = require('yode-nvim.redux.index')
local seditors = storeBundle.seditors
local layout = storeBundle.layout
local R = require('yode-nvim.deps.lamda.dist.lamda')
local sharedLayoutActions = require('yode-nvim.layout.sharedActions')
local diffLib = require('yode-nvim.diffLib')

local M = {}

M.writeFileEditor = function()
    local log = logging.create('writeFileEditor')

    local bufId = vim.fn.bufnr('%')
    local sedsConnected = seditors.selectors.getSeditorsConnected(bufId)
    R.forEach(function(sed)
        vim.bo[sed.seditorBufferId].modified = false
    end, sedsConnected)
end

M.handleZombies = function(fileBufferId, editLineCount, onAction)
    local log = logging.create('handleZombies')

    -- ignoring one line changes for now, doesn't seem worth diffing
    -- TODO do it for zombies with only one line as well, skipped because of
    -- lazyness. One line changes are often the fast pace typing events.
    if editLineCount ~= nil and editLineCount <= 1 then
        log.debug('not processing one line changes')
        return {}
    end

    zombiesConnected = R.values(seditors.selectors.getZombieSeditorsConnected(fileBufferId))
    if #zombiesConnected <= 0 then
        log.debug('no zombies for file buffer', fileBufferId)
        return {}
    end

    log.trace('processing zombies', zombiesConnected)
    local fileText = R.join('\n', vim.api.nvim_buf_get_lines(fileBufferId, 0, -1, true))
    local zombieActions = h.map(function(sed)
        local seditorBufferId = sed.seditorBufferId
        local diffData = diffLib.diff(fileText, sed.zombie.text)
        local blocks = diffLib.findConnectedBlocks(diffData)
        if #blocks <= 0 then
            local newCountdown = sed.zombie.countdown - 1
            if newCountdown <= 0 then
                log.debug('removing really dead zombie from state and nvim', seditorBufferId)
                vim.schedule(function()
                    vim.cmd('bd! ' .. seditorBufferId)
                end)
                return
            end

            log.debug('nothing to recover for', seditorBufferId)
            seditors.actions.changeData({
                seditorBufferId = seditorBufferId,
                data = { zombie = { countdown = newCountdown } },
            })
            return
        end

        local seditorData = diffLib.getSeditorDataFromBlocks(blocks, diffData)
        log.debug('recover!', seditorData)
        local lines = R.split('\n', seditorData.text)
        local indentCount = h.getIndentCount(lines)

        local cleanedLines = h.map(R.drop(indentCount), lines)
        seditors.actions.changeData({
            seditorBufferId = seditorBufferId,
            data = { indentCount = indentCount, startLine = seditorData.startLine },
        })
        seditors.actions.resurrectSeditor({
            seditorBufferId = seditorBufferId,
        })
        vim.schedule(function()
            vim.api.nvim_buf_set_lines(seditorBufferId, 0, -1, true, cleanedLines)
        end)
        if onAction then
            return onAction(seditorBufferId)
        else
            return sharedLayoutActions.actions.contentChanged({
                tabId = vim.api.nvim_get_current_tabpage(),
                bufId = seditorBufferId,
            })
        end
    end, zombiesConnected)

    return R.reject(R.isNil, zombieActions)
end

M.handlePossibleFileContentChange = function(fileBufferId)
    local log = logging.create('handlePossibleFileContentChange')
    local sedsConnected = seditors.selectors.getSeditorsConnected(fileBufferId)
    if R.isEmpty(sedsConnected) then
        log.debug('no seditors connected to', fileBufferId)
        return
    end

    log.debug('processing file buffer', fileBufferId)
    R.forEach(function(connectedEditor)
        log.debug('add editor to zombie list', connectedEditor.seditorBufferId)
        seditors.actions.softlyKillSeditor({
            seditorBufferId = connectedEditor.seditorBufferId,
        })
    end, sedsConnected)

    M.handleZombies(fileBufferId, nil, function(seditorBufferId)
        vim.schedule(function()
            layout.actions.multiTabContentChanged({
                tabId = vim.api.nvim_get_current_tabpage(),
                bufId = seditorBufferId,
            })
            -- content hasn't changed by the action, it is now on par with
            -- the file buffer
            vim.bo[seditorBufferId].modified = false
        end)
    end)
end

return M
