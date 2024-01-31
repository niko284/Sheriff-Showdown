-- Inventory Slice
-- August 8th, 2023
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local RoduxUtils = require(Packages.RoduxUtils)

-- // Slice \\

return RoduxUtils.createSlice({
	name = "Inventory",
	initialState = {
		Items = {},
		Equipped = {},
	},
	reducers = {
		SetInventory = function(state, action)
			if action.payload == nil then
				return state
			end
			state = action.payload
			return state
		end,
		EquipItem = function(state, action)
			if RoduxUtils.Draft.find(state.Equipped, action.payload.item.UUID) then
				return state
			end
			for _i, item in state.Items do
				if item.UUID == action.payload.item.UUID then
					RoduxUtils.Draft.insert(state.Equipped, item.UUID)
					break
				end
			end
			return state
		end,
		UnequipItem = function(state, action)
			if not RoduxUtils.Draft.find(state.Equipped, action.payload.item.UUID) then
				return state
			else
				RoduxUtils.Draft.remove(state.Equipped, RoduxUtils.Draft.find(state.Equipped, action.payload.item.UUID))
				return state
			end
		end,
		AddItem = function(state, action)
			RoduxUtils.Draft.insert(state.Items, action.payload.item)
		end,
		RemoveItem = function(state, action)
			for i, item in state.Items do
				if item.UUID == action.payload.item.UUID then
					RoduxUtils.Draft.remove(state.Items, i)
					break
				end
			end
		end,
		SetItem = function(state, action)
			for i, item in state.Items do
				if item.UUID == action.payload.item.UUID then
					state.Items[i] = action.payload.item
					break
				end
			end
		end,
	},
})
