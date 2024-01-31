-- Handler Collector
-- Ron
-- December 9th, 2022

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants

local Types = require(Constants.Types)

local HandlerModules = script:GetDescendants()
local CombatHandlers: Types.Handlers = {}

for _, HandlerModule: Instance in HandlerModules do
	if HandlerModule:IsA("ModuleScript") then
		local Success, err = pcall(function()
			local Handler: Types.ActionHandler = require(HandlerModule)
			if Handler then
				local settingsData = Handler.Data.SettingsData
				if not settingsData then
					warn(string.format("Handler %s has no settings data.", Handler.Data.Name))
					return
				end
				CombatHandlers[Handler.Data.Name] = Handler
			end
		end)

		if not Success then
			warn(string.format("Could not load handler module '%s' \nError:[%s]", HandlerModule.Name, tostring(err)))
		end
	end
end

return CombatHandlers
