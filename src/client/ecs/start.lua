local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Matter = require(ReplicatedStorage.packages.Matter)
local Spark = require(ReplicatedStorage.packages.Spark)

local InputState = Spark.InputState
local Actions = Spark.Actions
local InputMap = Spark.InputMap

function Actions:justPressed(action: string): boolean
	local signal = self:justPressedSignal(action)
	local iterator = Matter.useEvent(action, signal)

	return iterator() ~= nil
end

function Actions:justReleased(action: string): boolean
	local signal = self:justReleasedSignal(action)
	local iterator = Matter.useEvent(action, signal)

	return iterator() ~= nil
end

local function start(systemsContainers: { Instance })
	local state = {
		inputState = InputState.new(),
		actions = Actions.new({ "shoot" }),
		inputMap = InputMap.new():insert("shoot", Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR1),
	}

	local world = Matter.World.new()
	local loop = Matter.Loop.new(world, state)

	local systems = {}
	for _, systemContainer in ipairs(systemsContainers) do
		for _, system in systemContainer:GetChildren() do
			table.insert(systems, require(system))
		end
	end

	loop:scheduleSystems(systems)

	loop:begin({
		default = RunService.Heartbeat,
		RenderStepped = RunService.RenderStepped,
		Heartbeat = RunService.Heartbeat,
		Stepped = RunService.Stepped,
	})

	return world
end

return start
