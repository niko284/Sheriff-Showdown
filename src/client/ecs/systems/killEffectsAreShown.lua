local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local Components = require(ReplicatedStorage.ecs.components)
local Effects = require(PlayerScripts.ecs.effects)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local MatterTypes = require(ReplicatedStorage.ecs.MatterTypes)

local KillEffect = Effects.KillEffect

type KilledRecord = MatterTypes.WorldChangeRecord<Components.Killed>

local function killEffectsAreShown(world: Matter.World)
	for eid, killedRecord: KilledRecord in world:queryChanged(Components.Killed) do
		if killedRecord.new then
			local serverEntity: MatterReplication.ServerEntityData = world:get(eid, MatterReplication.ServerEntity)
			KillEffect.visualize(world, {
				killerServerEntityId = killedRecord.new.killerEntityId,
				killedServerEntityId = serverEntity.id,
			})
		end
	end
end

return killEffectsAreShown
