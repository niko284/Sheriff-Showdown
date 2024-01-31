-- Physics Utils
-- October 15th, 2023
-- Nick

-- // Variables \\

local HERTZ = (1 / 480) -- (1 / 240) * 0.5

-- // Utils \\

local PhysicsUtils = {}

function PhysicsUtils.GetCorrection(Gravity: Vector3, Time: number): Vector3
	return HERTZ * Gravity * Time
end

function PhysicsUtils.GetPositionAtTime(Origin: Vector3, Velocity: Vector3, Gravity: Vector3, Time: number): Vector3
	local Position = PhysicsUtils.GetPosition(Origin, Velocity, Gravity, Time)
	return Position + PhysicsUtils.GetCorrection(Gravity, Time)
end

function PhysicsUtils.GetPosition(Origin: Vector3, Velocity: Vector3, Gravity: Vector3, Time: number): Vector3
	return Origin + Velocity * Time + 0.5 * Gravity * (Time ^ 2)
end

return PhysicsUtils
