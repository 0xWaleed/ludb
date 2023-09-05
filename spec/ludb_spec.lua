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

ludb_set_driver(fake_driver())

describe('ludb', function()
  after_each(function()
	clear_all()
  end)

  it('can save and retrieve basic number', function()
	ludb_save('x', 5)
	assert.equals(5, ludb_retrieve('x'))
  end)

  it('can save and retrieve basic string', function()
	ludb_save('x', 'value')
	assert.equals('value', ludb_retrieve('x'))
  end)

  it('can save and retrieve basic table', function()
	ludb_save('x', { name = "waleed" })
	assert.same({ name = "waleed" }, ludb_retrieve('x'))
  end)

  it('can save and retrieve basic number with nested key', function()
	ludb_save('items/x', 5)
	assert.equals(5, ludb_retrieve('items/x'))
	assert.same({ x = 5 }, ludb_retrieve('items/*'))
  end)

  it('can save and retrieve multiple nested 1', function()
	ludb_save('players/123/vehicles/12', { color = 1 })
	ludb_save('players/123/vehicles/34', { color = 2 })

	assert.is_table(ludb_retrieve('players/123/vehicles/12'))
	assert.is_table(ludb_retrieve('players/123/vehicles/34'))
	assert.is_same({ color = 1 }, ludb_retrieve('players/123/vehicles/12'))
	assert.is_same({ color = 2 }, ludb_retrieve('players/123/vehicles/34'))

	local expected = {
	  ['12'] = {
		color = 1
	  },
	  ['34'] = {
		color = 2
	  }
	}
	assert.is_same(expected, ludb_retrieve('players/123/vehicles/*'))
  end)

  it('can save and retrieve multiple nested 1', function()
	ludb_save('players/123/vehicles/12', { color = 1 })
	ludb_save('players/345/vehicles/34', { color = 2 })

	assert.is_table(ludb_retrieve('players/123/vehicles/12'))
	assert.is_table(ludb_retrieve('players/345/vehicles/34'))
	assert.is_same({ color = 1 }, ludb_retrieve('players/123/vehicles/12'))
	assert.is_same({ color = 2 }, ludb_retrieve('players/345/vehicles/34'))

	assert.is_same({
	  ['12'] = { color = 1 }
	}, ludb_retrieve('players/123/vehicles/*'))
	assert.is_same({
	  ['34'] = { color = 2 }
	}, ludb_retrieve('players/345/vehicles/*'))
  end)

  it('can save and retrieve multiple values from nested', function()
	ludb_save('players/123/vehicles/12', { color = 1 })
	ludb_save('players/123/items/12', { name = "pc" })
	ludb_save('players/123/friends/0xwaleed', { nickname = "Wal" })

	local expected = {
	  vehicles = {
		['12'] = { color = 1 }
	  },
	  items    = {
		['12'] = {
		  name = "pc"
		}
	  },
	  friends  = {
		['0xwaleed'] = {
		  nickname = "Wal"
		}
	  }
	}
	assert.is_same(expected, ludb_retrieve('players/123/*'))
  end)

  it('can save within a nested', function()
	ludb_save('players/123/vehicles/12', { color = 1 })
	ludb_save('players/123/vehicles', 55)
	assert.is_table(ludb_retrieve('players/123/vehicles/*'))
	local expected = 55
	assert.equals(expected, ludb_retrieve('players/123/vehicles'))
  end)

  it('expect able to get the item twice', function()
	ludb_save('players/123', 55)
	local items = ludb_retrieve('players/*')
	assert.same({ ['123'] = 55 }, items)
	assert.equals(55, ludb_retrieve('players/123'))
	assert.equals(55, ludb_retrieve('players/123'))
  end)

  it('should return nil when retrieving with *', function()
	assert.was_no_error(function()
	  ludb_retrieve('players/*')
	end)
  end)

  it('can traverse the root', function()
	ludb_save('players/123', 55)
	local expected = {
	  ['players'] = {
		['123'] = 55
	  },
	}
	assert.same(expected, ludb_retrieve('*'))
  end)

  it('delete', function()
	ludb_save('players/123', 55)
	assert.is_not_nil(ludb_retrieve('players/123'))
	ludb_delete('players/123')
	assert.is_nil(ludb_retrieve('players/123'))
	assert.is_table(ludb_retrieve('players/*'))
	assert.array(ludb_retrieve('players/*')).has.no.holes()
  end)

  it('delete multiple', function()
	ludb_save('players/123', 55)
	ludb_save('players/321', 66)
	ludb_save('players/456', 777)
	assert.is_not_nil(ludb_retrieve('players/123'))
	assert.is_not_nil(ludb_retrieve('players/321'))
	assert.is_not_nil(ludb_retrieve('players/456'))
	ludb_delete('players/123')
	ludb_delete('players/321')
	assert.is_nil(ludb_retrieve('players/123'))
	assert.is_nil(ludb_retrieve('players/321'))
	assert.is_not_nil(ludb_retrieve('players/456'))
	assert.is_table(ludb_retrieve('players/*'))
	assert.same({ ['456'] = 777 }, ludb_retrieve('players/*'))
	assert.array(ludb_retrieve('players/*')).has.holes(1)
  end)

  it('does not delete nested', function()
	ludb_save('players/123', 55)
	ludb_save('players/123/a', 77)
	ludb_delete('players/123')
	assert.is_nil(ludb_retrieve('players/123'))
	assert.equals(77, ludb_retrieve('players/123/a'))
  end)

  it('can delete all', function()
	ludb_save('players/123', 55)
	ludb_save('players/321', 66)
	ludb_delete_all('players/*')
	assert.is_nil(ludb_retrieve('players/123'))
	assert.is_nil(ludb_retrieve('players/321'))
  end)

  it('can delete from root 1', function()
	ludb_save('players/123', 55)
	ludb_save('players/321', 66)
	ludb_delete_all('*')
	assert.is_nil(ludb_retrieve('players/123'))
	assert.is_nil(ludb_retrieve('players/321'))
  end)

  it('can delete from root 2', function()
	ludb_save('players/123', { 1, 2, 3 })
	ludb_save('players/321', { 3, 2, 1 })
	ludb_delete_all('*')
	assert.is_nil(ludb_retrieve('players/123'))
	assert.is_nil(ludb_retrieve('players/321'))
  end)

  it('can delete from root 3', function()
	ludb_save('players/1', { name = 'waleed' })
	ludb_save('players/2', { name = 'bison' })
	ludb_save('players/3/info', { name = '0xWaleed' })
	ludb_delete_all('*')
	local items = ludb_retrieve('*')
	assert.is_nil(items)
  end)
end)
