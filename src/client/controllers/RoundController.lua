-- Round Controller
-- February 8th, 2024
-- Nick

-- // Variables \\

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local ActionShared = ReplicatedStorage.ActionShared
local Assets = ReplicatedStorage:FindFirstChild("assets")

local AudioController = require(Controllers.AudioController)
local ClientComm = require(PlayerScripts.ClientComm)
local Distractions = require(Constants.Distractions)
local EffectUtils = require(Utils.EffectUtils)
local EntityModule = require(ActionShared.Entity)
local InterfaceController = require(Controllers.InterfaceController)
local KeybindInputController = require(Controllers.KeybindInputController)
local NotificationController = require(Controllers.NotificationController)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local RoundStatus = ClientComm:GetProperty("RoundStatus")
local VotingPoolClient = ClientComm:GetProperty("VotingPoolClient")
local StartMatchTimestamp = ClientComm:GetProperty("StartMatchTimestamp")

local RoundNamespace = Remotes.Client:GetNamespace("Round")
local StartMatch = RoundNamespace:Get("StartMatch")
local EndMatch = RoundNamespace:Get("EndMatch")
local ApplyTeamIndicator = RoundNamespace:Get("ApplyTeamIndicator")
local SendDistraction = RoundNamespace:Get("SendDistraction")

local DISTRACTION_SIGNS = Assets:FindFirstChild("distractions")
local CROSSHAIR_ICON = "rbxassetid://16896087891"

-- // Controller \\

local RoundController = {
	Name = "RoundController",
	StartVoting = Signal.new(),
	EndVoting = Signal.new(),
	DistractionReceived = Signal.new() :: Signal.Signal<Types.Distraction>,
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
				Description = "Match starting in 8 seconds",
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
	StartMatch:Connect(function()
		InterfaceController.DoTransition:Fire(2) -- 2 second transition
		KeybindInputController:SetMouseIcon(CROSSHAIR_ICON)
	end)
	EndMatch:Connect(function()
		KeybindInputController:SetMouseIcon("")

		-- clear any team indicators
		for _, teamIndicator in CollectionService:GetTagged("TeamIndicator") do
			teamIndicator:Destroy()
		end
	end)
	SendDistraction:Connect(function(Distraction: Types.Distraction)
		RoundController.DistractionReceived:Fire(Distraction) -- trigger the DistractionViewport component to show the sign for the distraction

		-- play the distraction audio
		local distractionInfo = Distractions[Distraction]
		if distractionInfo and distractionInfo.AudioId then
			local audioId = string.format("rbxassetid://%d", distractionInfo.AudioId)
			AudioController:PlayAudio(audioId)
		end
	end)

	ApplyTeamIndicator:Connect(function(teamColors: { [string]: { Players: { Player }, Color: Color3 } })
		for _teamName, teamInfo in teamColors do
			for _, player in teamInfo.Players do
				local entity = EntityModule.GetEntity(player.Character)
				if entity then
					EffectUtils.ApplyTeamIndicator(entity, teamInfo.Color)
				end
			end
		end
	end)
end

function RoundController:ShowDistraction(Distraction: Types.Distraction)
	local signModel = DISTRACTION_SIGNS:FindFirstChild(Distraction)
	local sign = signModel:Clone()
	sign.Parent = workspace

	--
end

return RoundController
