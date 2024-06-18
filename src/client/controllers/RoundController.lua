--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts
local Controllers = PlayerScripts.controllers
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder

local AudioUtils = require(Utils.AudioUtils)
local Distractions = require(Constants.Distractions)
local KeybindInputController = require(Controllers.KeybindInputController)
local Net = require(Packages.Net)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local RoundNamespace = Remotes.Client:GetNamespace("Round")
local StartMatch = RoundNamespace:Get("StartMatch") :: Net.ClientListenerEvent
local EndMatch = RoundNamespace:Get("EndMatch") :: Net.ClientListenerEvent
local SendDistraction = RoundNamespace:Get("SendDistraction") :: Net.ClientListenerEvent

local DISTRACTION_SIGNS = Assets:FindFirstChild("distractions") :: Folder
local CROSSHAIR_ICON = "rbxassetid://16896087891"

-- // Controller \\

local RoundController = {
	Name = "RoundController",
	StartVoting = Signal.new(),
	EndVoting = Signal.new(),
	DistractionReceived = Signal.new() :: Signal.Signal<Types.Distraction>,
	StartMatch = Signal.new() :: Signal.Signal<number>,
}

function RoundController:OnStart()
	StartMatch:Connect(function()
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
			AudioUtils.PlaySoundOnInstance(distractionInfo.AudioId, SoundService)
		end
	end)
end

function RoundController:ShowDistraction(Distraction: Types.Distraction)
	local signModel = DISTRACTION_SIGNS:FindFirstChild(Distraction) :: Model
	local sign = signModel:Clone()
	sign.Parent = workspace
end

return RoundController
