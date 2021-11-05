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
            return true, token
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

        if #currentGroup == 0 and token.status ~= 'same' then
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
        -- FIXME why did I write this?
        if R.last(group) == R.last(allTokens) then
            return group
        end

        local sortMatches = R.sort(R.ascend(R.prop('distance')))

        local findHappyStart = function(tokens)
            local takeTokensBeforeCount = R.max(1, tokens[1].index - CONNECTED_TOKEN_BORDER)
            local diffTokens = R.pipe(
                R.drop(takeTokensBeforeCount - 1),
                R.take(CONNECTED_TOKEN_BORDER)
            )(diffData.diffTokens)
            local diffLines = R.pipe(
                R.drop(takeTokensBeforeCount - 1),
                R.take(R.min(START_END_COMPARE_COUNT, #tokens + CONNECTED_TOKEN_BORDER)),
                M.joinTokenText,
                R.split('\n')
            )(diffData.diffTokens)
            local lineCount = R.length(diffLines)
            local baseText =
                R.pipe(
                    M.joinTokenText,
                    R.split('\n'),
                    R.take(lineCount),
                    R.join('\n')
                )(diffData.newTokens)
            local startMatches = h.map(function(counter)
                local diffLinesMatch = R.pipe(R.drop(counter), R.take(lineCount - counter))(
                    diffLines
                )
                local text = R.join('\n', diffLinesMatch)
                local distance = getEditDistance(baseText, text)

                return {
                    counter = counter,
                    text = text,
                    distance = distance,
                }
            end, R.range(
                0,
                lineCount
            ))

            local startMatchesSorted = sortMatches(startMatches)
            local bestMatch = R.head(startMatchesSorted)
            if bestMatch.counter == 0 then
                return tokens
            end

            local newLinesToRemove = bestMatch.counter
            local additionalTokens = R.dropWhile(function(t)
                local count = #R.match('\n', t.token)
                if count <= 0 then
                    return true
                elseif newLinesToRemove - count >= 1 then
                    newLinesToRemove = newLinesToRemove - count
                    return true
                end

                return false
            end, diffTokens)

            if #additionalTokens <= 0 then
                return tokens
            end

            local trimToken = R.pipe(
                R.splitEvery(1),
                R.dropWhile(function(char)
                    if newLinesToRemove > 0 then
                        if char == '\n' then
                            newLinesToRemove = newLinesToRemove - 1
                        end
                        return true
                    end

                    return false
                end),
                R.join('')
            )
            local additionalTokensTrimmed = h.over(
                h.lensIndex(1),
                h.over(h.lensProp('token'), trimToken),
                additionalTokens
            )
            local grouWithHappyStart = R.concat(additionalTokensTrimmed, tokens)

            return grouWithHappyStart
        end

        local findHappyEnd = function(tokens)
            local trailLineEndingCount = R.pipe(
                R.takeLast(START_END_COMPARE_COUNT),
                M.joinTokenText,
                R.split('\n'),
                R.length
            )(tokens)
            local groupLines = R.pipe(M.joinTokenText, R.split('\n'))(tokens)
            local baseText = R.pipe(
                M.joinTokenText,
                R.split('\n'),
                R.takeLast(trailLineEndingCount),
                R.join('\n')
            )(diffData.newTokens)
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

            local endMatchesSorted = sortMatches(endMatches)
            local bestMatch = R.head(endMatchesSorted)
            if bestMatch.counter == 0 then
                return tokens
            end

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
            end, tokens)

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

            --return h.map(R.omit({ 'tokens' }), endMatchesSorted)
            --return R.pipe(R.takeLast(CONNECTED_TOKEN_BORDER), M.joinTokenText, R.split('\n'))(group)
            --return R.pipe(R.takeLast(CONNECTED_TOKEN_BORDER), M.joinTokenText, R.split('\n'))(diffData.newTokens)

            return groupWithHappyEndingTrimmed
        end

        local withHappyStart = findHappyStart(group)
        local withHappyEnd = findHappyEnd(withHappyStart)

        return {
            tokens = withHappyEnd,
            text = M.joinTokenText(withHappyEnd),
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
