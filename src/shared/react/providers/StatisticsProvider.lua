--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Contexts = ReplicatedStorage.react.contexts

local React = require(ReplicatedStorage.packages.React)
local Sift = require(ReplicatedStorage.packages.Sift)
local StatisticsContext = require(Contexts.StatisticsContext)

local ClientComm = require(PlayerScripts.ClientComm)

local ReplicatedStatistics = ClientComm:GetProperty("PlayerStatistics")

local e = React.createElement
local useState = React.useState
local useEffect = React.useEffect

local function StatisticsProvider(props)
	local statistics, setStatistics = useState({})

	useEffect(function()
		local statisticsChanged = ReplicatedStatistics:Observe(function(partialStatistics: { [string]: any })
			setStatistics(function(oldStatistics: { [string]: any })
				return Sift.Dictionary.join(oldStatistics, partialStatistics)
			end)
		end)

		return function()
			statisticsChanged:Disconnect()
		end
	end, {})

	return e(StatisticsContext.Provider, {
		value = statistics,
	}, props.children)
end

return StatisticsProvider
