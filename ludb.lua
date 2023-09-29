---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 9/4/23 6:18 AM
---

KEY_DELIMITER = '/'

local function memory_driver()
	local o      = {}
	local memory = {}

	o.set        = function(k, v)
		memory[k] = v
	end

	o.get        = function(k)
		return memory[k]
	end

	o.clear      = function()
		memory = {}
	end

	o.delete     = function(k)
		memory[k] = nil
	end

	return o
end

local function split(str, delimiter)
	local result = {}
	for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
		table.insert(result, match)
	end
	return result
end

local function table_contains(tbl, element)
	if not tbl then
		return false
	end

	for _, value in pairs(tbl) do
		if value == element then
			return true
		end
	end
	return false
end

local function retrieve_nested(instance, id)
	id         = id:gsub('%/%*', '')

	local item = instance._driver.get(id)
	if item and type(item) == 'table' and item.nested_keys and #item.nested_keys > 0 then
		local out = {}
		for _, k in ipairs(item.nested_keys) do
			local value = retrieve_nested(instance, ('%s/%s'):format(id, k))
			out[k]      = value
		end

		if item.value then
			out.value = item.value
		end

		return out
	end

	if item then
		return item
	end
end

local function internal_delete_all(instance, id)

end

local ludbMT   = {}
ludbMT.__index = ludbMT

function ludb_new(prefix)
	local o   = {}
	o._driver = memory_driver()
	o._prefix = prefix
	return setmetatable(o, ludbMT)
end

function ludbMT:_buildPath(keys)
	local out = {}
	if self._prefix then
		table.insert(out, self._prefix)
	end

	for _, item in ipairs(keys) do
		table.insert(out, item)
	end
	return table.concat(out, KEY_DELIMITER)
end

function ludbMT:setDriver(driver)
	self._driver = driver
end

function ludbMT:clearAll()
	self._driver.clear()
end

function ludbMT:save(id, item)
	id           = self:_buildPath({ 'root', id })
	keys         = split(id, KEY_DELIMITER)
	keysFromRoot = {}
	local parent
	for _, key in ipairs(keys) do

		table.insert(keysFromRoot, key)

		local fullPathKey = self:_buildPath(keysFromRoot)

		current           = self._driver.get(fullPathKey)

		if not current then
			current = { nested_keys = {} }
		end

		if parent then
			if not parent.nested_keys then
				parent.nested_keys = {}
			end

			if parent.nested_keys and not table_contains(parent.nested_keys, key) then
				table.insert(parent.nested_keys, key)
				self._driver.set(parentKey, parent)
			end
		end

		parent    = current
		parentKey = fullPathKey
	end

	local inItem      = { value = item }

	local storageItem = self._driver.get(id)

	if storageItem then
		inItem.nested_keys = storageItem.nested_keys
	end

	self._driver.set(id, inItem)
end

function ludbMT:retrieve(id)
	if id == '*' then
		id = 'root'
	else
		id = self:_buildPath({ 'root', id })
	end

	if id:find('%/%*') or id == 'root' then
		return retrieve_nested(self, id)
	end

	local item = self._driver.get(id)

	if item then
		return item
	end
end

function ludbMT:_internalDeleteAll(id)
	local items = self._driver.get(id)
	if not items then
		return
	end
	if not items.nested_keys then
		self._driver.delete(id)
		return
	end

	for _, k in ipairs(items.nested_keys) do
		local fullKey = self:_buildPath({ id, k })
		self:_internalDeleteAll(fullKey)
	end
	self._driver.delete(id)
end

function ludbMT:delete(id)
	id = self:_buildPath({ 'root', id })
	self._driver.delete(id)
end

function ludbMT:deleteAll(id)
	if id == '*' then
		id = 'root'
	else
		id = id:gsub('%/%*', '')
		id = self:_buildPath({ 'root', id })
	end

	self:_internalDeleteAll(id)
end