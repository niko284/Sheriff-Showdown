--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Other = Assets:FindFirstChild("other") :: Folder
local ZombieRagdoll = Other:FindFirstChild("ZombieMesh") :: MeshPart

local AudioUtils = require(ReplicatedStorage.utils.AudioUtils)
local Components = require(ReplicatedStorage.ecs.components)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local Types = require(ReplicatedStorage.constants.Types)

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
}

local AUDIO_PRESETS = { 24902227, 24902268, 24902294, 35971877, 35971915 }

return {
	name = "Zombie Launcher",
	visualize = function(world, payload)
		local clientEntityId = MatterReplication.resolveServerId(world, payload.killedServerEntityId)

		if clientEntityId then
			local renderable: Components.Renderable<PVInstance>? = world:get(clientEntityId, Components.Renderable)
			if renderable then
				local zombie = ZombieRagdoll:Clone()
				zombie:PivotTo(renderable.instance:GetPivot() * CFrame.new(0, 5, 0))
				zombie.Parent = workspace

				AudioUtils.PlaySoundOnInstance(AUDIO_PRESETS[math.random(1, #AUDIO_PRESETS)], zombie)

				world:spawn(
					Components.Renderable({
						instance = zombie,
					}),
					Components.Lifetime({
						expiry = os.time() + 5,
					})
				)
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
