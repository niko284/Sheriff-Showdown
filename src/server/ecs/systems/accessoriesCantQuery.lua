--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function disableQueryingForAccessories(instance: Instance)
	for _, child in instance:GetChildren() do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle") :: BasePart?
			if handle and handle.CanQuery then
				handle.CanQuery = false
			end
		end
	end
end

local function accessoriesCantQuery(world: jecs.World)
	for _eid, renderable, _target in world:query(Components.Renderable, Components.Target) do
		disableQueryingForAccessories(renderable.instance)
	end
end

return accessoriesCantQuery
