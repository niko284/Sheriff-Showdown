--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local React = require(Packages.React)

local useState = React.useState
local useEffect = React.useEffect

local function usePlayers()
	local players, setPlayers = useState(function()
		return Players:GetPlayers()
	end)

	useEffect(function()
		local playerAddedSignal = Players.PlayerAdded:Connect(function()
			setPlayers(Players:GetPlayers())
		end)

		local playerRemovedSignal = Players.PlayerRemoving:Connect(function()
			setPlayers(Players:GetPlayers())
		end)

		return function()
			playerAddedSignal:Disconnect()
			playerRemovedSignal:Disconnect()
		end
	end, { setPlayers })

	return players
end

return usePlayers
