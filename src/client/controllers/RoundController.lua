-- Round Controller
-- February 8th, 2024
-- Nick

-- // Variables \\

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants

local ClientComm = require(PlayerScripts.ClientComm)
local InterfaceController = require(Controllers.InterfaceController)
local NotificationController = require(Controllers.NotificationController)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local RoundStatus = ClientComm:GetProperty("RoundStatus")
local VotingPoolClient = ClientComm:GetProperty("VotingPoolClient")

-- // Controller \\

local RoundController = {
	Name = "RoundController",
	StartVoting = Signal.new(),
	EndVoting = Signal.new(),
}

function RoundController:Start()
	RoundStatus:Observe(function(Status: string)
		InterfaceController:WaitForAppLoaded():andThen(function()
			NotificationController:AddNotification({
				Description = Status,
				Title = "",
				Duration = nil,
				UUID = HttpService:GenerateGUID(false),
				ClickToDismiss = false,
			}, "Text")
		end)
	end)
	VotingPoolClient:Observe(function(VotingPool: Types.VotingPoolClient)
		InterfaceController:WaitForAppLoaded():expect()
		if VotingPool then
			RoundController.StartVoting:Fire(VotingPool)
		else
			RoundController.EndVoting:Fire()
		end
	end)
end

return RoundController
