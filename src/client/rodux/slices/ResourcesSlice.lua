-- Resources Slice
-- August 8th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local RoduxUtils = require(Packages.RoduxUtils)
local Sift = require(Packages.Sift)

-- // Slice \\

return RoduxUtils.createSlice({
	name = "Resources",
	initialState = {},
	reducers = {
		SetResources = function(state, action)
			local originalState = RoduxUtils.Draft.original(state)
			return Sift.Dictionary.merge(originalState, action.payload)
		end,
	},
})
