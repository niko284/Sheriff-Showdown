local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local StatusService = { Name = "StatusService", StatusProcessed = Signal.new() :: Signal.Signal<number, Types.Status> }
StatusService.StatusComponents = {
	Components.Killed,
	Components.Slowed,
	Components.Knocked,
}

return StatusService
