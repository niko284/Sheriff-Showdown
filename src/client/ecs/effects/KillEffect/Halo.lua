local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Particles = Assets:FindFirstChild("particles") :: Folder
local HaloParticle = Particles:FindFirstChild("HaloParticle") :: ParticleEmitter

local Components = require(ReplicatedStorage.ecs.components)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local Types = require(ReplicatedStorage.constants.Types)

type KillEffectPayload = {
	killerServerEntityId: number,
	killedServerEntityId: number,
}

return {
	name = "Halo",
	visualize = function(world, payload)
		local clientEntityId = MatterReplication.resolveServerId(world, payload.killedServerEntityId)

		if clientEntityId then
			local renderable: Components.Renderable<Model>? = world:get(clientEntityId, Components.Renderable)
			if renderable then
				local haloAttach = Instance.new("Attachment")
				haloAttach.Parent = renderable.instance:FindFirstChild("UpperTorso")
				local haloParticle = HaloParticle:Clone()
				haloParticle.Parent = haloAttach

				world:spawn(
					Components.Renderable({
						instance = haloAttach,
					}),
					Components.Lifetime({
						expiry = os.time() + 5, -- 5 seconds
					})
				)
			end
		end
	end,
} :: Types.VisualEffect<KillEffectPayload>
