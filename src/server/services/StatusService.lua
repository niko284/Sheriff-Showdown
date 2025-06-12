local Components = require("@ecs/components")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local StatusService = { Name = "StatusService", StatusProcessed = Signal.new() :: Signal.Signal<number, Types.Status> }
StatusService.StatusComponents = {
	Components.Killed,
	Components.Slowed,
	Components.Knocked,
}

return StatusService
