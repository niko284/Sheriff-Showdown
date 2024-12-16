--!strict

local MathUtils = {}

-- // Functions \\

function MathUtils.RotateCFrameAroundWorldAxis(CoordinateFrame: CFrame, WorldAxis: Vector3, Amount: number): CFrame
	local objectAxis = CoordinateFrame:VectorToObjectSpace(WorldAxis)
	return CoordinateFrame * CFrame.fromAxisAngle(objectAxis, Amount)
end

function MathUtils.RotateCFrameCameraBehavior(CoordinateFrame: CFrame, dPitch: number, dYaw: number): CFrame
	CoordinateFrame = MathUtils.RotateCFrameAroundWorldAxis(CoordinateFrame, Vector3.new(0, 1, 0), dYaw)
	CoordinateFrame *= CFrame.Angles(dPitch, 0, 0)
	return CoordinateFrame
end

function MathUtils.GetCFramePitch(CoordinateFrame: CFrame): number
	-- Returns angle of LookVector of our coordinate frame in relation to the XZ plane. (Pitch relative to the world)
	local lookVector = CoordinateFrame.LookVector
	local pY = lookVector.Y
	local pX = Vector3.new(lookVector.X, 0, lookVector.Z).Magnitude
	return math.atan2(pY, pX)
end

function MathUtils.GetCFrameYaw(CoordinateFrame: CFrame): number
	-- Returns angle of LookVector in relation to XY plane. (Yaw relative to the world)
	local lookVector = (CoordinateFrame.LookVector * Vector3.new(1, 0, 1))
	return math.atan2(lookVector.X, lookVector.Z)
end

function MathUtils.GetCFrameAngles(CoordinateFrame: CFrame)
	return CoordinateFrame - CoordinateFrame.Position
end

function MathUtils.CFrameToOrientation(cf: CFrame)
	local rx, ry, rz = cf:ToOrientation()
	return Vector3.new(math.deg(rx), math.deg(ry), math.deg(rz))
end

function MathUtils.ConstrainAngles(Angles: CFrame, pitchLimits: NumberRange, yawLimits: NumberRange): CFrame
	-- Given rotation, constrains it to the given pitch and yaw limits

	local unlimitedCFrame = Angles
	local limitedCFrame = unlimitedCFrame

	if pitchLimits then
		local newPitch = MathUtils.GetCFramePitch(unlimitedCFrame)
		if newPitch > pitchLimits.Max then
			local extraPitch = newPitch - pitchLimits.Max
			limitedCFrame = MathUtils.RotateCFrameCameraBehavior(limitedCFrame, -extraPitch, 0)
		elseif newPitch < pitchLimits.Min then
			local missingPitch = pitchLimits.Min - newPitch
			limitedCFrame = MathUtils.RotateCFrameCameraBehavior(limitedCFrame, missingPitch, 0)
		end
	end

	-- Limit yaw

	if yawLimits then
		local newYaw = MathUtils.GetCFrameYaw(limitedCFrame)
		if newYaw > yawLimits.Max then
			local extraYaw = newYaw - yawLimits.Max
			limitedCFrame = MathUtils.RotateCFrameCameraBehavior(limitedCFrame, 0, -extraYaw)
		elseif newYaw < yawLimits.Min then
			local missingYaw = yawLimits.Min - newYaw
			limitedCFrame = MathUtils.RotateCFrameCameraBehavior(limitedCFrame, 0, missingYaw)
		end
	end

	return limitedCFrame
end

function MathUtils.GetModelCornerDistance(Model: Model): number
	local _, size = Model:GetBoundingBox()
	return Vector3.new(size.X / 2 + size.Y / 2 + size.Z / 2).Magnitude
end

return MathUtils
