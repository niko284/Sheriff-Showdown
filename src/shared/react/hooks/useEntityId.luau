--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local React = require(ReplicatedStorage.packages.React)
local useAttribute = require(ReplicatedStorage.hooks.useAttribute)

local useState = React.useState
local useEffect = React.useEffect

local function usePlayerEntityId(player: Player, world: Matter.World?)
	local entityId, setEntityId = useState(nil :: number?)
	local serverEntityId = useAttribute(player, "serverEntityId")

	useEffect(function()
		if not world then
			return function() end
		end

		if serverEntityId and world then
			local resolvedClientId = MatterReplication.resolveServerId(world, serverEntityId)
			if resolvedClientId then
				setEntityId(resolvedClientId)
				return function() end
			end
		end

		local detectPlayerComponent
		detectPlayerComponent = RunService.RenderStepped:Connect(function()
			for playerEid, playerComponent in world:query(Components.Player) do
				if playerComponent.OwnedBy == player then
					setEntityId(playerEid)
					detectPlayerComponent:Disconnect()
					return
				end
			end
		end)

		return function()
			if detectPlayerComponent then
				detectPlayerComponent:Disconnect()
			end
		end
	end, { player, serverEntityId } :: { any })

	return entityId
end

return usePlayerEntityId
