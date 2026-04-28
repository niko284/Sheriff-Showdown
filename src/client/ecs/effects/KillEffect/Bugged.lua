--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Particles = Assets:FindFirstChild("particles") :: Folder
local BuggedParticles = Particles:FindFirstChild("Bugged") :: Folder

local AudioUtils = require("@utilities/AudioUtils")
local Components = require("@ecs/components")
local Types = require("@constants/Types")

local GLITCH_SOUND_ID = 5491518316

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
	replecsClient: any,
}

return {
	name = "Bugged",
	visualize = function(world, payload)
		local clientEntityId = payload.replecsClient
			and payload.replecsClient:get_client_entity(payload.killedServerEntityId)

		if clientEntityId then
			local renderable: Components.Renderable? = world:get(clientEntityId, Components.Renderable)
			if renderable then
				for _, particle in BuggedParticles:GetChildren() do
					if particle:IsA("ParticleEmitter") then
						local attach = Instance.new("Attachment")
						attach.Parent = renderable.instance:FindFirstChild("UpperTorso")
						local haloParticle = particle:Clone()
						haloParticle.Parent = attach

						local attachId = world:entity()
						world:set(attachId, Components.Renderable, { instance = attach })
						world:set(attachId, Components.Lifetime, {
							expiry = (DateTime.now().UnixTimestampMillis / 1000) + 5,
						})
					end
				end
				AudioUtils.PlaySoundOnInstance(GLITCH_SOUND_ID, renderable.instance)
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
