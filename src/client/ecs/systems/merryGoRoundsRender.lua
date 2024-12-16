local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local Components = require(ReplicatedStorage.ecs.components)

local useDeltaTime = Matter.useDeltaTime

local function merryGoRoundsRender(world: Matter.World)
	local deltaTime = useDeltaTime()

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
			doNotReconcile = false,
		})
		world:insert(eid, transform)

		if rotator then
			rotator.AssemblyAngularVelocity = Vector3.new(0, angularVelocity, 0)
		end
	end
end

return merryGoRoundsRender
