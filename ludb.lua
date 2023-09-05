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

local g_driver = memory_driver()

function ludb_set_driver(driver)
  g_driver = driver
end

local function split(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
	table.insert(result, match)
  end
  return result
end

function clear_all()
  g_driver.clear()
end

local function build_path(keys)
  local out = {}
  for _, item in ipairs(keys) do
	table.insert(out, item)
  end
  return table.concat(out, KEY_DELIMITER)
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

function ludb_save(id, item)
  id           = build_path({ 'root', id })
  keys         = split(id, KEY_DELIMITER)
  keysFromRoot = {}
  local parent
  for _, key in ipairs(keys) do

	table.insert(keysFromRoot, key)

	local fullPathKey = build_path(keysFromRoot)

	current           = g_driver.get(fullPathKey)

	if not current then
	  current = { nested_keys = {} }
	end

	if parent then
	  if parent.nested_keys and not table_contains(parent.nested_keys, key) then
		table.insert(parent.nested_keys, key)
		g_driver.set(parentKey, parent)
	  end
	end

	parent    = current
	parentKey = fullPathKey
  end

  local inItem      = { value = item }

  local storageItem = g_driver.get(id)

  if storageItem then
	inItem.nested_keys = storageItem.nested_keys
  end

  g_driver.set(id, inItem)
end

local function retrieve_nested(id)
  id         = id:gsub('%/%*', '')

  local item = g_driver.get(id)
  if item and type(item) == 'table' and item.nested_keys and #item.nested_keys > 0 then
	local out = {}
	for _, k in ipairs(item.nested_keys) do
	  local value = retrieve_nested(('%s/%s'):format(id, k))
	  out[k]      = value
	end

	return out
  end

  if item then
	return item.value
  end
end

function ludb_retrieve(id)
  if id == '*' then
	id = 'root'
  else
	id = build_path({ 'root', id })
  end
  if id:find('%/%*') or id == 'root' then
	return retrieve_nested(id)
  end

  local item = g_driver.get(id)

  if item then
	return item.value
  end
end

function ludb_delete(id)
  id = build_path({ 'root', id })
  g_driver.delete(id)
end

function internal_delete_all(id)
  local items = g_driver.get(id)
  if not items then
	return
  end
  if not items.nested_keys then
	g_driver.delete(id)
	return
  end

  for _, k in ipairs(items.nested_keys) do
	local fullKey = build_path({ id, k })
	internal_delete_all(fullKey)
  end
  g_driver.delete(id)
end

function ludb_delete_all(id)
  if id == '*' then
	id = 'root'
  else
	id = id:gsub('%/%*', '')
	id = build_path({ 'root', id })
  end

  internal_delete_all(id)
end