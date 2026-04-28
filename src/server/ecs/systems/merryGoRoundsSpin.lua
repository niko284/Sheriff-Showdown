--!strict

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

type State = {
	scheduler: any,
}

local function merryGoRoundsSpin(world: jecs.World, state: State)
	local deltaTime = state.scheduler:getDeltaTime()

	for eid, merryGoRound, transform in world:query(Components.MerryGoRound, Components.Transform):iter() do
		local targetAngularVelocity = merryGoRound.targetAngularVelocity
		local currentAngularVelocity = merryGoRound.currentAngularVelocity
		local angularAcceleration = merryGoRound.angularAcceleration

		local angularVelocity =
			math.clamp(currentAngularVelocity + angularAcceleration * deltaTime, 0, targetAngularVelocity)
		local angularDisplacement = currentAngularVelocity * deltaTime
			+ 0.5 * angularAcceleration * math.pow(deltaTime, 2)

		local newCFrame = transform.cframe * CFrame.Angles(0, angularDisplacement, 0)

		local newMerry: Components.MerryGoRound = {
			targetAngularVelocity = merryGoRound.targetAngularVelocity,
			currentAngularVelocity = merryGoRound.currentAngularVelocity,
			angularAcceleration = merryGoRound.angularAcceleration,
			maxAngularVelocity = merryGoRound.maxAngularVelocity,
			hardStopIn = merryGoRound.hardStopIn,
		}
		local merryChanged = false

		if angularVelocity >= merryGoRound.maxAngularVelocity and merryGoRound.hardStopIn == nil then
			newMerry.hardStopIn = os.time() + 3
			merryChanged = true
		end

		if merryGoRound.hardStopIn and os.time() >= merryGoRound.hardStopIn then
			newMerry.targetAngularVelocity = 0
			newMerry.angularAcceleration = -0.25
			merryChanged = true
		end

		if merryGoRound.hardStopIn and angularVelocity == 0 then
			newMerry.hardStopIn = nil
			newMerry.angularAcceleration = 0.1
			merryChanged = true
		end

		if angularVelocity ~= merryGoRound.currentAngularVelocity then
			newMerry.currentAngularVelocity = angularVelocity
			merryChanged = true
		end

		if merryChanged then
			world:set(eid, Components.MerryGoRound, newMerry)
		end

		world:set(eid, Components.Transform, { cframe = newCFrame, doNotReconcile = true })
	end
end

return merryGoRoundsSpin
