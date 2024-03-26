-- Current Interface Slice
-- August 8th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local RoduxUtils = require(Packages.RoduxUtils)

-- // Slice \\

return RoduxUtils.createSlice({
	name = "CurrentInterface",
	initialState = nil,
	reducers = {
		SetCurrentInterface = function(state, action)
			if state == "DailyRewards" or state == "TutorialPrompt" then
				if action.payload.interface ~= nil then
					return nil
				end
			end
			if action.payload.interface == nil or state == action.payload.interface then
				state = RoduxUtils.Draft.None
				return state
			end
			state = action.payload.interface
			return state
		end,
	},
})
