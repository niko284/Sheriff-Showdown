--!strict

-- Use Scale Ratio
-- January 22nd, 2024
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils

local DependencyArray = require(Utils.DependencyArray)
local InterfaceController = require(Controllers.InterfaceController)
local React = require(Packages.React)

local useState = React.useState
local useEffect = React.useEffect

-- // Hook \\

local function useScaleRatio()
	local scaleRatio, setScaleRatio = useState(function()
		return InterfaceController:GetScaleRatio()
	end)
	useEffect(function()
		if scaleRatio == nil then
			local ratio = InterfaceController:GetScaleRatio()
			if ratio then
				setScaleRatio(ratio)
			end
		end
		local scaleRatioChanged = InterfaceController.ScaleRatioChanged:Connect(function(newScaleRatio: number)
			setScaleRatio(newScaleRatio)
		end)
		return function()
			scaleRatioChanged:Disconnect()
		end
	end, DependencyArray(setScaleRatio, scaleRatio))
	return scaleRatio ~= nil and scaleRatio or 1
end

return useScaleRatio
