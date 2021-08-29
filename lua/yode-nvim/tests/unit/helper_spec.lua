local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

describe('helper', function()
    it('maxPositiveNumber', function()
        assert.True(h.maxPositiveNumber > 999999999999999999999999)
    end)

    it('map', function()
        eq({ 11, 12, 13 }, h.map(R.add(10), { 1, 2, 3 }))
        eq({ foo = 101, bar = 102 }, h.map(R.add(100), { foo = 1, bar = 2 }))

        -- for comparision what `R.map` does, which is not the behaviour of
        -- Ramda.map
        eq({ 101, 102 }, R.map(R.add(100), { foo = 1, bar = 2 }))
    end)

    it('lenses', function()
        local list = { 10, 20, 30, 40 }
        local tbl = { foo = 'my foo', bar = 'other foo', baz = 'even more foo!', l = list }

        local second = h.lensIndex(2)
        local bar = h.lensProp('bar')
        local deep = h.lensPath({ 'l', 3 })

        eq(20, h.view(second, list))
        eq(nil, h.view(second, tbl))
        eq('other foo', h.view(bar, tbl))
        eq(nil, h.view(bar, list))
        eq(30, h.view(deep, tbl))
        eq(nil, h.view(deep, list))

        eq({ 10, 99, 30, 40 }, h.set(second, 99, list))
        eq({
            foo = 'my foo',
            -- changed here
            bar = 'now you see me',
            baz = 'even more foo!',
            l = list,
        }, h.set(
            bar,
            'now you see me',
            tbl
        ))
        eq({
            foo = 'my foo',
            bar = 'other foo',
            baz = 'even more foo!',
            l = {
                10,
                20,
                -- changed here
                77,
                40,
            },
        }, h.set(
            deep,
            77,
            tbl
        ))

        eq({ 10, 120, 30, 40 }, h.over(second, R.add(100), list))
        eq({
            foo = 'my foo',
            -- prepending here
            bar = 'this is other foo',
            baz = 'even more foo!',
            l = list,
        }, h.over(
            bar,
            R.concat('this is '),
            tbl
        ))
        eq({
            foo = 'my foo',
            bar = 'other foo',
            baz = 'even more foo!',
            l = {
                10,
                20,
                -- adding 100 here
                130,
                40,
            },
        }, h.over(
            deep,
            R.add(100),
            tbl
        ))
    end)

    it('createWhiteSpace', function()
        eq({ '', ' ', '  ', '   ', '          ' }, h.map(h.createWhiteSpace, { 0, 1, 2, 3, 10 }))
    end)

    it('getIndentConut', function()
        eq(0, h.getIndentCount({}))
        eq(0, h.getIndentCount({ '', '' }))
        eq(0, h.getIndentCount({ '', 'foo', '' }))
        eq(0, h.getIndentCount({ 'foo' }))

        eq(2, h.getIndentCount({ '  foo', '  bar' }))
        eq(2, h.getIndentCount({ '    foo', '  bar', '' }))
        eq(2, h.getIndentCount({ '  foo', '    bar' }))
        eq(2, h.getIndentCount({ '    foo', '  bar' }))
        eq(4, h.getIndentCount({ '    foo', '    bar' }))
    end)
end)
