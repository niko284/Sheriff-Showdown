-- Root Reducer
-- January 22nd, 2024
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.packages.Rodux)

local Slices = script.Parent.slices

-- // Root Reducer \\

local RootReducer = {}

for _, SliceModule: Instance in pairs(Slices:GetChildren()) do
	if SliceModule:IsA("ModuleScript") then
		local Slice = require(SliceModule)
		RootReducer[Slice.name] = Slice.reducer
	end
end

return Rodux.combineReducers(RootReducer)
