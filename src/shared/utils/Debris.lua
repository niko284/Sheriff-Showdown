local Debris = {}

function Debris.AddSingle(item, t)
	task.delay(t, function()
		if item and item.Parent ~= nil then
			item:Destroy()
		end
	end)
end

function Debris.MassDestroy(Cache, t)
	task.delay(t or 0.0001, function()
		for i = 1, #Cache do
			if Cache[i] and Cache[i].Parent ~= nil then
				Cache[i]:Destroy()
			end
		end
	end)
end

return Debris
