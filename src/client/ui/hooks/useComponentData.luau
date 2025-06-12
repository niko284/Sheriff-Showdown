--!strict

local RunService = game:GetService("RunService")

local Matter = require("@packages/Matter")
local React = require("@packages/React")

local useEffect = React.useEffect
local useState = React.useState

local function useComponentData(entityId: number?, world: Matter.World?, ...)
	local componentData, setComponentData = useState({})

	local components = table.pack(...)

	useEffect(function()
		local queriesChanged

		if world and entityId then
			queriesChanged = RunService.RenderStepped:Connect(function()
				for i, component in components do
					for eid, newComponentRecord in world:queryChanged(component) do
						if entityId == eid then
							setComponentData(function(oldData)
								local newData = table.clone(oldData)
								newData[i] = newComponentRecord.new
								return newData
							end)
						end
					end
				end
			end)
		end

		return function()
			queriesChanged:Disconnect()
		end
	end, { entityId, ... })

	return table.unpack(componentData)
end

return useComponentData
