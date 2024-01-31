--!strict
-- Instance Utils
-- August 9th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Promise = require(Packages.Promise)

-- // Utils \\

local InstanceUtils = {}

function InstanceUtils.AssignProps(Instance: Instance, Props: { [string]: any })
	for prop, value in Props do
		pcall(function()
			(Instance :: any)[prop] = value -- avoid property setting errors.
		end)
	end
end

function InstanceUtils.AssignPropsRecursive(Instance: Instance, Callback: (Instance: Instance) -> ())
	Callback(Instance)
	for _, child in ipairs(Instance:GetChildren()) do
		InstanceUtils.AssignPropsRecursive(child, Callback)
	end
end

function InstanceUtils.ContainedInVolume(BrickSize: Vector3, BrickCFrame: CFrame, Position: Vector3)
	local RelPosition = BrickCFrame:PointToObjectSpace(Position)
	if
		math.abs(RelPosition.X) <= BrickSize.X / 2
		and math.abs(RelPosition.Y) <= BrickSize.Y / 2
		and math.abs(RelPosition.Z) <= BrickSize.Z / 2
	then
		return true
	end
	return false
end

function InstanceUtils.WaitForChild(parent: Instance, name: string, className: string?, timeOut: number?)
	local child: Instance? = parent:FindFirstChild(name)
	if child then
		return Promise.resolve(child)
	end

	local promise = Promise.fromEvent(parent.ChildAdded, function(addedChild: Instance)
		return addedChild.Name == name and (not className or addedChild:IsA(className))
	end)

	local connection
	connection = parent.Destroying:Connect(function()
		promise:cancel()
	end)

	if timeOut then
		Promise.delay(timeOut):andThen(function()
			promise:cancel()
		end)
	end

	promise:finally(function()
		connection:Disconnect()
	end)

	return promise
end

function InstanceUtils.WaitForChildOfClass(parent: Instance, className: string, timeOut: number?)
	local child: Instance? = parent:FindFirstChildOfClass(className)
	if child then
		return Promise.resolve(child)
	end

	local promise = Promise.fromEvent(parent.ChildAdded, function(addedChild: Instance)
		return addedChild:IsA(className)
	end)

	local connection
	connection = parent.Destroying:Connect(function()
		promise:cancel()
	end)

	if timeOut then
		Promise.delay(timeOut):andThen(function()
			promise:cancel()
		end)
	end

	promise:finally(function()
		connection:Disconnect()
	end)

	return promise
end

return InstanceUtils
