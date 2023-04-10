local h = require('yode-nvim.helper')
local R = require('yode-nvim.deps.lamda.dist.lamda')

local eq = assert.are.same

describe('helper', function()
    it('maxPositiveNumber', function()
        assert.True(h.maxPositiveNumber > 999999999999999999999999)
    end)

    it('keysSorted', function()
        eq({ 'bar', 'foo' }, h.keysSorted({ foo = 101, bar = 102 }))
        eq({ 'bar', 'foo' }, h.keysSorted({ bar = 101, foo = 102 }))

        eq({}, h.keysSorted({}))
    end)

    it('map', function()
        eq({ 11, 12, 13 }, h.map(R.add(10), { 1, 2, 3 }))
        eq({ foo = 101, bar = 102 }, h.map(R.add(100), { foo = 1, bar = 2 }))

        -- WARNING seems R.map doesn't gurantees in which order keys get mapped
        local sort = R.sort(R.lt)

        -- for comparision what `R.map` does, which is not the behaviour of
        -- Ramda.map
        eq(sort({ 101, 102 }), sort(R.map(R.add(100), { foo = 1, bar = 2 })))
    end)

    it('mapWithIndex', function()
        eq(
            { '5:1:567', '6:2:567', '7:3:567' },
            h.mapWithIndex(function(data, i, all)
                return data .. ':' .. i .. ':' .. R.join('', all)
            end, {
                5,
                6,
                7,
            })
        )

        eq(
            { foo = '10:foo', bar = '20:bar' },
            h.mapWithIndex(function(data, i)
                return data .. ':' .. i
            end, {
                foo = 10,
                bar = 20,
            })
        )

        -- this only works when props have values
        eq(
            { bar = '20:bar' },
            h.mapWithIndex(function(data, i)
                return data .. ':' .. i
            end, {
                foo = nil,
                bar = 20,
            })
        )
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
        }, h.set(bar, 'now you see me', tbl))
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
        }, h.set(deep, 77, tbl))

        eq({ 10, 120, 30, 40 }, h.over(second, R.add(100), list))
        eq({
            foo = 'my foo',
            -- prepending here
            bar = 'this is other foo',
            baz = 'even more foo!',
            l = list,
        }, h.over(bar, R.concat('this is '), tbl))
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
        }, h.over(deep, R.add(100), tbl))
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

    it('next/prevIndex', function()
        local data = { 100, 200, 300 }

        eq(1, h.nextIndex(1, { 666 }))
        eq(1, h.prevIndex(1, { 666 }))

        eq(nil, h.nextIndex(1, {}))
        eq(nil, h.prevIndex(1, {}))

        eq(nil, h.nextIndex(5, {}))
        eq(nil, h.prevIndex(5, {}))

        eq(nil, h.nextIndex(1, nil))
        eq(nil, h.prevIndex(1, nil))

        eq(nil, h.nextIndex(6, nil))
        eq(nil, h.prevIndex(6, nil))

        eq(2, h.nextIndex(1, data))
        eq(3, h.nextIndex(2, data))
        eq(1, h.nextIndex(3, data))

        eq(3, h.prevIndex(1, data))
        eq(1, h.prevIndex(2, data))
        eq(2, h.prevIndex(3, data))
    end)

    it('convert table with number keys to VimL compatiblle dict', function()
        local data = { [5] = { foo = 'bar' }, [100] = 'test', [2] = { 10, 11, 12 } }

        eq(
            { ['5'] = { foo = 'bar' }, ['100'] = 'test', ['2'] = { 10, 11, 12 } },
            h.makeVimTable(data)
        )
        eq({ ['1'] = 1, ['2'] = 2, ['3'] = 3 }, h.makeVimTable({ 1, 2, 3 }))
        eq({}, h.makeVimTable())
    end)

    pending('showBufferInFloatingWindow')
end)
