--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)

local useThrottle = Matter.useThrottle

local MERRY_GO_ROUND_ATTRIBUTE = RunService:IsServer() and "serverEntityId" or "clientEntityId"

local function merryGoRoundsSpin(world: Matter.World)
	local deltaTime = Matter.useDeltaTime()

	--[[if useThrottle(1) then
		for _eid, renderable: Components.Renderable, _target: Components.Target in
			world:query(Components.Renderable, Components.Target):without(Components.Killed)
		do
			local character = renderable.instance :: PVInstance
			local rightFoot = character:FindFirstChild("RightFoot") :: BasePart

			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { renderable.instance }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local rayDown = workspace:Raycast(rightFoot.Position, Vector3.new(0, -10, 0), rayParams)

			if rayDown then
				local merryGoRoundModel = rayDown.Instance:FindFirstAncestor("MerryGoRound")
				local merryGoRoundId = merryGoRoundModel and merryGoRoundModel:GetAttribute(MERRY_GO_ROUND_ATTRIBUTE)
				if merryGoRoundModel and merryGoRoundId then
					local merryGoRound = world:get(merryGoRoundId, Components.MerryGoRound)
					if merryGoRound then
						if merryGoRound.hardStopIn == nil then -- we don't want to override the hard stop
							print(`new target angular velocity: ${merryGoRound.currentAngularVelocity + 0.5}`)
							merryGoRound = merryGoRound:patch({
								targetAngularVelocity = merryGoRound.currentAngularVelocity + 0.5,
							})
							world:insert(merryGoRoundId, merryGoRound)
						end
					end
				end
			end
		end
	end--]]

	for eid, merryGoRound, transform in world:query(Components.MerryGoRound, Components.Transform) do
		local targetAngularVelocity = merryGoRound.targetAngularVelocity
		local currentAngularVelocity = merryGoRound.currentAngularVelocity
		local angularAcceleration = merryGoRound.angularAcceleration

		local angularVelocity =
			math.clamp(currentAngularVelocity + angularAcceleration * deltaTime, 0, targetAngularVelocity)
		local angularDisplacement = currentAngularVelocity * deltaTime
			+ 0.5 * angularAcceleration * math.pow(deltaTime, 2)

		local newCFrame = transform.cframe * CFrame.Angles(0, angularDisplacement, 0)

		if angularVelocity >= merryGoRound.maxAngularVelocity and merryGoRound.hardStopIn == nil then
			merryGoRound = merryGoRound:patch({
				hardStopIn = os.time() + 3, -- hard stop in 3 seconds
			})
			world:insert(eid, merryGoRound)
		end

		if merryGoRound.hardStopIn and os.time() >= merryGoRound.hardStopIn then
			merryGoRound = merryGoRound:patch({
				targetAngularVelocity = 0,
				angularAcceleration = -0.25,
			})
			world:insert(eid, merryGoRound)
		end

		if merryGoRound.hardStopIn and angularVelocity == 0 then
			merryGoRound = merryGoRound:patch({
				hardStopIn = Matter.None,
				angularAcceleration = 0.1,
			})
			world:insert(eid, merryGoRound)
		end

		if angularVelocity ~= merryGoRound.currentAngularVelocity then
			merryGoRound = merryGoRound:patch({
				currentAngularVelocity = angularVelocity,
			})
			world:insert(eid, merryGoRound)
		end

		world:insert(eid, transform:patch({ cframe = newCFrame, doNotReconcile = true })) -- doNotReconcile is important here, server shouldn't reconcile this
	end
end

return {
	system = merryGoRoundsSpin,
	event = "stepped",
}
