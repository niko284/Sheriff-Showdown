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
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local RoundStatus = ClientComm:GetProperty("RoundStatus")
local VotingPoolClient = ClientComm:GetProperty("VotingPoolClient")
local StartMatchTimestamp = ClientComm:GetProperty("StartMatchTimestamp")

local RoundNamespace = Remotes.Client:GetNamespace("Round")

local StartMatchCountdown = RoundNamespace:Get("StartMatchCountdown")

-- // Controller \\

local RoundController = {
	Name = "RoundController",
	StartVoting = Signal.new(),
	EndVoting = Signal.new(),
	StartMatch = Signal.new() :: Signal.Signal<number>,
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
	StartMatchTimestamp:Observe(function(StartTimestamp: number?)
		if StartTimestamp then
			NotificationController:AddNotification({
				Description = "Match starting in 5 seconds",
				Title = "",
				Duration = 5,
				UUID = HttpService:GenerateGUID(false),
				ClickToDismiss = false,
				OnHeartbeat = function()
					return "Match starting in " .. math.max(0, math.floor(StartTimestamp - os.time())) .. " seconds"
				end,
			}, "Text")
		end
	end)
end

return RoundController
