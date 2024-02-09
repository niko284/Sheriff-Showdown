-- Notification Controller
-- Nick
-- August 6th, 2022

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Controllers = LocalPlayer.PlayerScripts.controllers
local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde

local AudioController = require(Controllers.AudioController)
local NotificationSerde = require(Serde.NotificationSerde)
local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local NotificationRemotes = Remotes.Client:GetNamespace("Notifications")
local AddNotification = NotificationRemotes:Get("AddNotification")
local RemoveNotification = NotificationRemotes:Get("RemoveNotification")

-- // Controller Variables \\

local NotificationController = {
	Name = "NotificationController",
	GlobalNotificationAdded = Signal.new(),
	GlobalNotificationRemoved = Signal.new(),
	TextNotificationAdded = Signal.new(),
	TextNotificationRemoved = Signal.new(),
}

-- // Functions \\

function NotificationController:Init()
	AddNotification:Connect(function(Notification: string, NotificationType: Types.NotificationType)
		self:AddNotification(NotificationSerde.Deserialize(Notification), NotificationType)
	end)
	RemoveNotification:Connect(function(UUID: string)
		self:RemoveNotification(UUIDSerde.Deserialize(UUID))
	end)
end

function NotificationController:AddNotification(Notification: Types.Notification, NotificationType: Types.NotificationType)
	if NotificationType == "Toast" then
		AudioController:PlayPreset("NotificationReceived")
		self.GlobalNotificationAdded:Fire(Notification)
	elseif NotificationType == "Text" then
		NotificationController.TextNotificationAdded:Fire(Notification)
	end
end

function NotificationController:RemoveNotification(Id: string)
	self.GlobalNotificationRemoved:Fire(Id)
end

return NotificationController
