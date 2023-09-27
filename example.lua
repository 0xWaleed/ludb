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

ludb_save('players/123', "0xwaleed")
ludb_save('players/123/vehicles', { 'adder', 'bison' })
ludb_save('players/123/garages', { 'garage-1', 'garage-2' })
ludb_save('players/123/garages/standard', { 'garage-2' })
ludb_save('players/123/garages/premium', { 'garage-1' })

ludb_save('players/321', "0xwal")
ludb_save('players/321/vehicles', { 'hydra', 'jet' })
ludb_save('players/321/garages', { 'garage-1', 'garage-2', 'garage-3' })
ludb_save('players/321/garages/standard', { 'garage-2' })
ludb_save('players/321/garages/premium', { 'garage-1', 'garage-3' })

ludb_save('players/555', "rawan")
ludb_save('players/555/vehicles', { 'impala', 'jet' })
ludb_save('players/555/garages', { 'garage-1' })
ludb_save('players/555/garages/premium', { 'garage-1' })

pretty_print(ludb_retrieve('players/321'))