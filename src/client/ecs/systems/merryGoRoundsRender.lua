local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)

local Components = require(ReplicatedStorage.ecs.components)

local useDeltaTime = Matter.useDeltaTime

local function merryGoRoundsRender(world: Matter.World)
	local deltaTime = useDeltaTime()

	-- associate replicated merryGoRound entities with their renderable and transform components
	for eid, _merryGoRound, serverEntity in
		world
			:query(Components.MerryGoRound, MatterReplication.ServerEntity)
			:without(Components.Renderable, Components.Transform)
	do
		local merryGoRoundModel: PVInstance? = nil
		for _, instance in CollectionService:GetTagged("MerryGoRound") do
			if instance:GetAttribute("serverEntityId") == serverEntity.id then
				merryGoRoundModel = instance
				break
			end
		end
		if not merryGoRoundModel then
			continue
		end
		world:insert(eid, Components.Renderable({ instance = merryGoRoundModel }))
		world:insert(eid, Components.Transform({ cframe = merryGoRoundModel:GetPivot() }))
	end

	-- update the rotation of the merryGoRound as the server replicates over the new physics state
	for eid, merryGoRound, transform, renderable in
		world:query(Components.MerryGoRound, Components.Transform, Components.Renderable)
	do
		local targetAngularVelocity = merryGoRound.targetAngularVelocity
		local currentAngularVelocity = merryGoRound.currentAngularVelocity
		local angularAcceleration = merryGoRound.angularAcceleration

		local rotator = renderable.instance:FindFirstChild("rotator") :: BasePart

		local angularVelocity =
			math.clamp(currentAngularVelocity + angularAcceleration * deltaTime, 0, targetAngularVelocity)
		local angularDisplacement = currentAngularVelocity * deltaTime
			+ 0.5 * angularAcceleration * math.pow(deltaTime, 2)

		local newCFrame = transform.cframe * CFrame.Angles(0, angularDisplacement, 0)

		transform = transform:patch({
			cframe = newCFrame,
		})
		world:insert(eid, transform)

		rotator.AssemblyAngularVelocity = Vector3.new(0, angularVelocity, 0)
	end
end

return merryGoRoundsRender
