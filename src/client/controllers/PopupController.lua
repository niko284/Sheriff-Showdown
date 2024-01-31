-- Action Controller
-- January 22nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local Signal = require(Packages.Signal)

-- // Controller \\

local PopupController = {
	Name = "PopupController",
	ActionPopupAdded = Signal.new(),
	ActionPopupRemoved = Signal.new(),
}

-- // Functions \\

function PopupController:Init() end

return PopupController
