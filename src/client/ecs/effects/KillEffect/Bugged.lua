--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Particles = Assets:FindFirstChild("particles") :: Folder
local BuggedParticles = Particles:FindFirstChild("Bugged") :: Folder

local AudioUtils = require(ReplicatedStorage.utils.AudioUtils)
local Components = require(ReplicatedStorage.ecs.components)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local Types = require(ReplicatedStorage.constants.Types)

local GLITCH_SOUND_ID = 5491518316

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
}

return {
	name = "Bugged",
	visualize = function(world, payload)
		local clientEntityId = MatterReplication.resolveServerId(world, payload.killedServerEntityId)

		if clientEntityId then
			local renderable: Components.Renderable<Model>? = world:get(clientEntityId, Components.Renderable)
			if renderable then
				for _, particle in BuggedParticles:GetChildren() do
					if particle:IsA("ParticleEmitter") then
						local attach = Instance.new("Attachment")
						attach.Parent = renderable.instance:FindFirstChild("UpperTorso")
						local haloParticle = particle:Clone()
						haloParticle.Parent = attach

						world:spawn(
							Components.Renderable({
								instance = attach,
							}),
							Components.Lifetime({
								expiry = os.time() + 5, -- 5 seconds
							})
						)
					end
				end
				AudioUtils.PlaySoundOnInstance(GLITCH_SOUND_ID, renderable.instance)
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
