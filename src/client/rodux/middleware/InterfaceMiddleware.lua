-- Interface Middleware
-- August 8th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers

local InterfaceController = require(Controllers.InterfaceController)

-- // Middleware \\

return function(nextDispatch, store)
	return function(action)
		if action.type == "SetCurrentInterface" then
			local oldInterface = store:getState().CurrentInterface
			local newInterface = action.payload.interface
			if (oldInterface == "DailyRewards" or oldInterface == "TutorialPrompt") and newInterface ~= nil then
				return nextDispatch(action)
			end
			if not newInterface or oldInterface == newInterface then
				InterfaceController.InterfaceChanged:Fire(nil)
			elseif oldInterface ~= newInterface then
				InterfaceController.InterfaceChanged:Fire(newInterface)
			end
		end
		return nextDispatch(action)
	end
end
