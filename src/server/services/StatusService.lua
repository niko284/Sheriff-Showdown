local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local StatusService = { Name = "StatusService", StatusProcessed = Signal.new() :: Signal.Signal<number, Types.Status> }

return StatusService
