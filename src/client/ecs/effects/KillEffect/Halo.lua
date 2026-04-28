--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Particles = Assets:FindFirstChild("particles") :: Folder
local HaloParticle = Particles:FindFirstChild("HaloParticle") :: ParticleEmitter

local Components = require("@ecs/components")
local Types = require("@constants/Types")

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
	replecsClient: any,
}

return {
	name = "Halo",
	visualize = function(world, payload)
		local clientEntityId = payload.replecsClient
			and payload.replecsClient:get_client_entity(payload.killedServerEntityId)

		if clientEntityId then
			local renderable: Components.Renderable? = world:get(clientEntityId, Components.Renderable)
			if renderable then
				local haloAttach = Instance.new("Attachment")
				haloAttach.Parent = renderable.instance:FindFirstChild("UpperTorso")
				local haloParticle = HaloParticle:Clone()
				haloParticle.Parent = haloAttach

				local haloId = world:entity()
				world:set(haloId, Components.Renderable, { instance = haloAttach })
				world:set(haloId, Components.Lifetime, {
					expiry = (DateTime.now().UnixTimestampMillis / 1000) + 5,
				})
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
