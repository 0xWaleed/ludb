---
--- Created By 0xWaleed <https://github.com/0xWaleed>
--- DateTime: 9/27/23 6:13 AM
---


require('ludb')

function pretty_print(tbl, indent)
	if not indent then
		indent = 0
	end

	for k, v in pairs(tbl) do
		formatting = string.rep("  ", indent) .. k .. ": "
		if type(v) == "table" then
			print(formatting)
			pretty_print(v, indent + 1)
		elseif type(v) == 'boolean' then
			print(formatting .. tostring(v))
		else
			print(formatting .. v)
		end
	end
end

local l = ludb_new()

l:save('players/123', "0xwaleed")
l:save('players/123/vehicles', { 'adder', 'bison' })
l:save('players/123/garages', { 'garage-1', 'garage-2' })
l:save('players/123/garages/standard', { 'garage-2' })
l:save('players/123/garages/premium', { 'garage-1' })

l:save('players/321', "0xwal")
l:save('players/321/vehicles', { 'hydra', 'jet' })
l:save('players/321/garages', { 'garage-1', 'garage-2', 'garage-3' })
l:save('players/321/garages/standard', { 'garage-2' })
l:save('players/321/garages/premium', { 'garage-1', 'garage-3' })

l:save('players/555', "rawan")
l:save('players/555/vehicles', { 'impala', 'jet' })
l:save('players/555/garages', { 'garage-1' })
l:save('players/555/garages/premium', { 'garage-1' })

pretty_print(l:retrieve('players/321/*'))