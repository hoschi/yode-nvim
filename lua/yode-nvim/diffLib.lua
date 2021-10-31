local diffLibOrig = require('yode-nvim.deps.diff.diff.lua.diff')
local bkTree = require('yode-nvim.deps.bk-tree.bk-tree')
local R = require('yode-nvim.deps.lamda.dist.lamda')
local h = require('yode-nvim.helper')

local M = {}

local CONNECTED_TOKEN_BORDER = 10
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

    local baseText = R.pipe(R.takeLast(CONNECTED_TOKEN_BORDER), M.joinTokenText)(newTokens)

    return { diffTokens = arr, oldTokens = oldTokens, newTokens = newTokens, baseText = baseText }
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

        local bestMatch = R.reduce(function(lastMatch, counter)
            local groupTokens = R.pipe(R.dropLast(counter), R.takeLast(CONNECTED_TOKEN_BORDER))(
                group
            )
            local text = M.joinTokenText(groupTokens)
            local distance = getEditDistance(diffData.baseText, text)

            if not R.isEmpty(lastMatch) and lastMatch.distance <= distance then
                return lastMatch
            end

            return {
                tokens = groupTokens,
                text = text,
                distance = distance,
            }
        end, {}, R.range(
            0,
            CONNECTED_TOKEN_BORDER
        ))

        local groupWithHappyEnding = R.dropLastWhile(
            R.complement(R.propEq('index', R.last(bestMatch.tokens).index)),
            group
        )
        local groupWithHappyEndingTrimmed = h.over(
            h.lensIndex(#groupWithHappyEnding),
            -- NOTICE this is ... complicated. Seperator for splitting is
            -- `%s+`. This means a token can contain several new line
            -- characters. But as Yode seditors are created line wise,
            -- every valid groups must end without a new line character.
            h.over(h.lensProp('token'), R.takeWhile(R.complement(R.equals('\n')))),
            groupWithHappyEnding
        )

        return {
            tokens = groupWithHappyEndingTrimmed,
            text = M.joinTokenText(groupWithHappyEndingTrimmed),
        }
    end, validGroups)

    return lineGroups
end

M.getSeditorDataFromBlocks = function(blocks, diffData)
    local block, bestMatch

    if #blocks <= 0 then
        return
    end

    if #blocks == 1 then
        block = R.head(blocks)
    else
        bestMatch = R.reduce(function(lastMatch, currentBlock)
            local distance = getEditDistance(diffData.baseText, currentBlock.text)
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
