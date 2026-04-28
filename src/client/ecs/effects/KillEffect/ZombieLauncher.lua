--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Other = Assets:FindFirstChild("other") :: Folder
local ZombieRagdoll = Other:FindFirstChild("ZombieMesh") :: MeshPart

local AudioUtils = require("@utilities/AudioUtils")
local Components = require("@ecs/components")
local Types = require("@constants/Types")

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
	replecsClient: any,
}

local AUDIO_PRESETS = { 24902227, 24902268, 24902294, 35971877, 35971915 }

return {
	name = "Zombie Launcher",
	visualize = function(world, payload)
		local clientEntityId = payload.replecsClient
			and payload.replecsClient:get_client_entity(payload.killedServerEntityId)

		if clientEntityId then
			local renderable: Components.Renderable? = world:get(clientEntityId, Components.Renderable)
			if renderable then
				local zombie = ZombieRagdoll:Clone()
				zombie:PivotTo((renderable.instance :: PVInstance):GetPivot() * CFrame.new(0, 5, 0))
				zombie.Parent = workspace

				AudioUtils.PlaySoundOnInstance(AUDIO_PRESETS[math.random(1, #AUDIO_PRESETS)], zombie)

				local zombieId = world:entity()
				world:set(zombieId, Components.Renderable, { instance = zombie })
				world:set(zombieId, Components.Lifetime, {
					expiry = (DateTime.now().UnixTimestampMillis / 1000) + 5,
				})
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
