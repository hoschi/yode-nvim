local diffLibOrig = require('yode-nvim.deps.diff.diff.lua.diff')
local bkTree = require('yode-nvim.deps.bk-tree.bk-tree')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')

local M = {}

local CONNECTED_TOKEN_BORDER = 15
local START_END_COMPARE_COUNT = 50
local isSame = R.propEq('status', 'same')
local isNotSame = R.complement(isSame)
local getTokensStartingWithSameOne = R.dropWhile(isNotSame)
local getEditDistance = bkTree.levenshtein_dist

M.joinTokenText = R.pipe(R.pluck('token'), R.join(''))

M.diff = function(old, new, separator)
    local diffData = diffLibOrig.diff(old, new, separator)

    local arr = {}
    for i, tokenRecord in ipairs(diffData) do
        arr = R.append({ index = i, token = tokenRecord[1], status = tokenRecord[2] }, arr)
    end

    local oldTokens = h.mapWithIndex(function(token, i)
        return { index = i, token = token }
    end, diffLibOrig.split(
        old,
        separator
    ))

    local newTokens = h.mapWithIndex(function(token, i)
        return { index = i, token = token }
    end, diffLibOrig.split(
        new,
        separator
    ))

    return { diffTokens = arr, oldTokens = oldTokens, newTokens = newTokens }
end

M.findConnectedBlocks = function(diffData)
    local allTokens

    if #diffData.diffTokens <= 0 then
        return {}
    end

    allTokens = diffData.diffTokens
    if allTokens[1].index == 1 and allTokens[1].status == 'same' and allTokens[1].token == '' then
        -- I don't see why this is there
        allTokens = R.drop(1, allTokens)
    end

    local notSameGroupCounter = 0
    local groupTokens = function(token)
        if token.status == 'same' then
            notSameGroupCounter = 0
        end

        if notSameGroupCounter >= CONNECTED_TOKEN_BORDER then
            notSameGroupCounter = 0
            return false
        else
            notSameGroupCounter = notSameGroupCounter + 1
        end

        if token.status == 'in' then
            return true
        end

        return true, token
    end

    local startTokens = getTokensStartingWithSameOne(allTokens)
    local allGroups = R.reduce(function(groups, token)
        local currentGroup = R.last(groups)

        if #currentGroup == 1 and token.status ~= 'same' then
            return groups
        end

        local isValid, groupToken = groupTokens(token)

        if not isValid then
            return R.append({}, groups)
        elseif groupToken then
            return R.update(#groups, R.append(groupToken, currentGroup), groups)
        end

        return groups
    end, {
        {},
        --}, R.take( 10, startTokens))
    }, startTokens)

    local lossFactor = 0.2
    local validGroups = R.filter(function(group)
        return #group > R.max(0, #diffData.newTokens * (1 - lossFactor))
            and #group < #diffData.newTokens * (1 + lossFactor)
    end, allGroups)

    local lineGroups = h.map(function(group)
        -- FIXME implement after test created
        --local newFirstToken = R.pipe(
        --R.take(group[1].index - 1),
        --R.reverse,
        --R.takeWhile(R.complement(R.propEq('text', '\n')))
        --)(allTokens)

        if R.last(group) == R.last(allTokens) then
            return group
        end

        local trailLineEndingCount = R.pipe(
            R.takeLast(START_END_COMPARE_COUNT),
            M.joinTokenText,
            R.split('\n'),
            R.length
        )(group)
        local baseText = R.pipe(
            M.joinTokenText,
            R.split('\n'),
            R.takeLast(trailLineEndingCount),
            R.join('\n')
        )(diffData.newTokens)
        local groupLines = R.pipe(M.joinTokenText, R.split('\n'))(group)
        local endMatches = h.map(function(counter)
            local groupLinesMatch = R.pipe(
                R.dropLast(counter),
                R.takeLast(trailLineEndingCount - counter)
            )(groupLines)
            local text = R.join('\n', groupLinesMatch)
            local distance = getEditDistance(baseText, text)

            return {
                counter = counter,
                text = text,
                distance = distance,
            }
        end, R.range(
            0,
            trailLineEndingCount
        ))

        local endMatchesSorted = R.sort(R.ascend(R.prop('distance')), endMatches)
        local bestMatch = R.head(endMatchesSorted)

        local newLinesToRemove = bestMatch.counter
        local groupWithHappyEnding = R.dropLastWhile(function(t)
            local count = #R.match('\n', t.token)
            if count <= 0 then
                return true
            elseif newLinesToRemove - count >= 1 then
                newLinesToRemove = newLinesToRemove - count
                return true
            end

            return false
        end, group)

        local trimToken = R.pipe(
            R.splitEvery(1),
            R.reduceRight(function(char, str)
                if char == '\n' and newLinesToRemove > 0 then
                    newLinesToRemove = newLinesToRemove - 1
                    return str
                end

                return R.concat(char, str)
            end, '')
        )
        local groupWithHappyEndingTrimmed = h.over(
            h.lensIndex(#groupWithHappyEnding),
            h.over(h.lensProp('token'), trimToken),
            groupWithHappyEnding
        )

        --return endMatchesSorted

        --return h.map(R.omit({ 'tokens' }), endMatchesSorted)
        --return R.pipe(R.takeLast(CONNECTED_TOKEN_BORDER), M.joinTokenText, R.split('\n'))(group)
        --return R.pipe(R.takeLast(CONNECTED_TOKEN_BORDER), M.joinTokenText, R.split('\n'))(diffData.newTokens)

        return {
            tokens = groupWithHappyEndingTrimmed,
            text = M.joinTokenText(groupWithHappyEndingTrimmed),
        }
    end, validGroups)

    return lineGroups
end

M.getSeditorDataFromBlocks = function(blocks, diffData)
    local block, bestMatch, baseText

    if #blocks <= 0 then
        return
    end

    if #blocks == 1 then
        block = R.head(blocks)
    else
        baseText = M.joinTokenText(newTokens)
        bestMatch = R.reduce(function(lastMatch, currentBlock)
            local distance = getEditDistance(baseText, currentBlock.text)
            if not R.isEmpty(lastMatch) and lastMatch.distance <= distance then
                return lastMatch
            end

            return {
                block = currentBlock,
                distance = distance,
            }
        end, {}, blocks)

        block = bestMatch.block
    end

    local startLine = R.pipe(
        R.take(block.tokens[1].index),
        R.pluck('token'),
        R.join(''),
        R.split('\n'),
        R.length,
        R.subtract(R.__, 1)
    )(diffData.oldTokens)

    return { text = block.text, startLine = startLine }
end

return M
