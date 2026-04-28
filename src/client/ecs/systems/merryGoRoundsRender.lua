--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

type State = {
	scheduler: any,
}

local function merryGoRoundsRender(world: jecs.World, state: State)
	local deltaTime = state.scheduler:getDeltaTime()

	for eid, merryGoRound, transform, renderable in
		world:query(Components.MerryGoRound, Components.Transform, Components.Renderable)
	do
		local currentAngularVelocity = merryGoRound.currentAngularVelocity
		local angularAcceleration = merryGoRound.angularAcceleration
		local targetAngularVelocity = merryGoRound.targetAngularVelocity

		local rotator = renderable.instance:FindFirstChild("rotator") :: BasePart?

		local angularVelocity =
			math.clamp(currentAngularVelocity + angularAcceleration * deltaTime, 0, targetAngularVelocity)
		local angularDisplacement = currentAngularVelocity * deltaTime
			+ 0.5 * angularAcceleration * math.pow(deltaTime, 2)

		local newCFrame = transform.cframe * CFrame.Angles(0, angularDisplacement, 0)

		world:set(eid, Components.Transform, { cframe = newCFrame, doNotReconcile = false })

		if rotator then
			rotator.AssemblyAngularVelocity = Vector3.new(0, angularVelocity, 0)
		end
	end
end

return merryGoRoundsRender
