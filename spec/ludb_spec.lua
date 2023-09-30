---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 9/4/23 6:19 AM
---

require('ludb')

assert:set_parameter("TableFormatLevel", -1)

local function fake_driver()
	-- this simulate the disk file driver, we use json.encode to avoid ref

	local o         = {}
	local json      = require('json')

	local g_storage = {}

	function o.set(k, v)
		g_storage[k] = json.encode(v)
	end

	function o.get(k)
		if not g_storage[k] then
			return
		end
		return json.decode(g_storage[k])
	end

	function o.clear()
		g_storage = {}
	end

	function o.delete(k)
		g_storage[k] = nil
	end

	return o

end

describe('l', function()
	local l

	before_each(function()
		l = ludb_new()
		l:setDriver(fake_driver())
	end)

	after_each(function()
		l:clearAll()
	end)

	it('can save and retrieve basic number', function()
		l:save('x', 5)
		assert.equals(5, l:retrieve('x'))
	end)

	it('can save and retrieve basic string', function()
		l:save('x', 'value')
		assert.equals('value', l:retrieve('x'))
	end)

	it('can save and retrieve basic table', function()
		l:save('x', { name = "waleed" })
		assert.same({ name = "waleed" }, l:retrieve('x'))
	end)

	it('can save and retrieve basic number with nested key', function()
		l:save('items/x', 5)
		assert.equals(5, l:retrieve('items/x'))
		assert.same({ x = { value = 5 } }, l:retrieve('items/*'))
	end)

	it('two instances with different prefix cannot share same values', function()
		-- ensure they read from same source as we use in memory
		local driver = fake_driver()
		local l1     = ludb_new('l1')
		l1:setDriver(driver)
		local l2 = ludb_new('l2')
		l2:setDriver(driver)

		l1:save('key', 5)
		l2:save('key', 3)
		assert.is_not_nil(l2:retrieve('key'))
		assert.not_equals(l1:retrieve('key'), l2:retrieve('key'))
	end)

	it('two instances with same prefix share same values', function()
		-- ensure they read from same source as we use in memory
		local driver = fake_driver()
		local l1     = ludb_new('prefix')
		l1:setDriver(driver)
		local l2 = ludb_new('prefix')
		l2:setDriver(driver)

		l1:save('key', 5)
		l2:save('key', 3)

		assert.is_not_nil(l2:retrieve('key'))
		assert.equals(l1:retrieve('key'), l2:retrieve('key'))
	end)

	it('can save and retrieve multiple nested 1', function()
		l:save('players/123/vehicles/12', { color = 1 })
		l:save('players/123/vehicles/34', { color = 2 })

		assert.is_table(l:retrieve('players/123/vehicles/12'))
		assert.is_table(l:retrieve('players/123/vehicles/34'))
		assert.is_same({ color = 1 }, l:retrieve('players/123/vehicles/12'))
		assert.is_same({ color = 2 }, l:retrieve('players/123/vehicles/34'))

		local expected = {
			['12'] = {
				value = { color = 1 }
			},
			['34'] = {
				value = { color = 2 }
			}
		}
		assert.is_same(expected, l:retrieve('players/123/vehicles/*'))
	end)

	it('can save and retrieve multiple nested 1', function()
		l:save('players/123/vehicles/12', { color = 1 })
		l:save('players/345/vehicles/34', { color = 2 })

		assert.is_table(l:retrieve('players/123/vehicles/12'))
		assert.is_table(l:retrieve('players/345/vehicles/34'))
		assert.is_same({ color = 1 }, l:retrieve('players/123/vehicles/12'))
		assert.is_same({ color = 2 }, l:retrieve('players/345/vehicles/34'))

		assert.is_same({
			['12'] = { value = { color = 1 } }
		}, l:retrieve('players/123/vehicles/*'))
		assert.is_same({
			['34'] = { value = { color = 2 } }
		}, l:retrieve('players/345/vehicles/*'))
	end)

	it('can save and retrieve multiple values from nested', function()
		l:save('players/123/vehicles/12', { color = 1 })
		l:save('players/123/items/12', { name = "pc" })
		l:save('players/123/friends/0xwaleed', { nickname = "Wal" })

		local expected = {
			vehicles = {
				['12'] = { value = { color = 1 } }
			},
			items    = {
				['12'] = {
					value = {
						name = "pc"
					}
				}
			},
			friends  = {
				['0xwaleed'] = {
					value = {
						nickname = "Wal"
					}
				}
			}
		}
		assert.is_same(expected, l:retrieve('players/123/*'))
	end)

	it('can save within a nested', function()
		l:save('players/123/vehicles/12', { color = 1 })
		l:save('players/123/vehicles', 55)
		assert.is_table(l:retrieve('players/123/vehicles/*'))
		local expected = {
			value  = 55,
			["12"] = {
				value = {
					color = 1
				}
			}
		}
		local passed   = l:retrieve('players/123/vehicles/*')
		assert.same(expected, passed)
	end)

	it('expect able to get the item twice', function()
		l:save('players/123', 55)
		local items = l:retrieve('players/*')
		assert.same({ ['123'] = { value = 55 } }, items)
		assert.same(55, l:retrieve('players/123'))
		assert.same(55, l:retrieve('players/123'))
	end)

	it('should return nil when retrieving with *', function()
		assert.was_no_error(function()
			l:retrieve('players/*')
		end)
	end)

	it('can traverse the root', function()
		l:save('players/123', 55)
		local expected = {
			['players'] = {
				['123'] = { value = 55 }
			},
		}
		assert.same(expected, l:retrieve('*'))
	end)

	it('can combine nested and value ina nested path', function()
		l:save('players/123', { id = "123", name = "0xWaleed" })
		l:save('players/123/vehicles', { 'adder', 'bison' })
		l:save('players/123/garages', { 'garage-1', 'garage-2' })
		local expected = {
			['players'] = {
				['123'] = {
					value        = {
						id   = "123",
						name = "0xWaleed"
					},
					['vehicles'] = {
						value = { 'adder', 'bison' }
					},
					['garages']  = {
						value = { 'garage-1', 'garage-2' }
					}
				},
			},
		}
		assert.same(expected, l:retrieve('*'))
	end)

	it('delete', function()
		l:save('players/123', 55)
		assert.is_not_nil(l:retrieve('players/123'))
		l:delete('players/123')
		assert.is_nil(l:retrieve('players/123'))
		assert.is_table(l:retrieve('players/*'))
		assert.array(l:retrieve('players/*')).has.no.holes()
	end)

	it('delete multiple', function()
		l:save('players/123', 55)
		l:save('players/321', 66)
		l:save('players/456', 777)
		assert.is_not_nil(l:retrieve('players/123'))
		assert.is_not_nil(l:retrieve('players/321'))
		assert.is_not_nil(l:retrieve('players/456'))
		l:delete('players/123')
		l:delete('players/321')
		assert.is_nil(l:retrieve('players/123'))
		assert.is_nil(l:retrieve('players/321'))
		assert.is_not_nil(l:retrieve('players/456'))
		assert.is_table(l:retrieve('players/*'))
		assert.same({ ['456'] = { value = 777 } }, l:retrieve('players/*'))
		assert.array(l:retrieve('players/*')).has.holes(1)
	end)

	it('does not delete nested', function()
		l:save('players/123', 55)
		l:save('players/123/a', 77)
		l:delete('players/123')
		assert.is_nil(l:retrieve('players/123'))
		assert.equals(77, l:retrieve('players/123/a'))
	end)

	it('can delete all', function()
		l:save('players/123', 55)
		l:save('players/321', 66)
		l:deleteAll('players/*')
		assert.is_nil(l:retrieve('players/123'))
		assert.is_nil(l:retrieve('players/321'))
	end)

	it('can delete from root 1', function()
		l:save('players/123', 55)
		l:save('players/321', 66)
		l:deleteAll('*')
		assert.is_nil(l:retrieve('players/123'))
		assert.is_nil(l:retrieve('players/321'))
	end)

	it('can delete from root 2', function()
		l:save('players/123', { 1, 2, 3 })
		l:save('players/321', { 3, 2, 1 })
		l:deleteAll('*')
		assert.is_nil(l:retrieve('players/123'))
		assert.is_nil(l:retrieve('players/321'))
	end)

	it('can delete from root 3', function()
		l:save('players/1', { name = 'waleed' })
		l:save('players/2', { name = 'bison' })
		l:save('players/3/info', { name = '0xWaleed' })
		l:deleteAll('*')
		local items = l:retrieve('*')
		assert.is_nil(items)
	end)
end)
