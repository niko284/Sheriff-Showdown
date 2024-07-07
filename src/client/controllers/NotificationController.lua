--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.network.serde

local Net = require(Packages.Net)
local NotificationSerde = require(Serde.NotificationSerde)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local NotificationRemotes = Remotes.Client:GetNamespace("Notifications")
local AddNotification = NotificationRemotes:Get("AddNotification") :: Net.ClientListenerEvent
local RemoveNotification = NotificationRemotes:Get("RemoveNotification") :: Net.ClientListenerEvent

-- // Controller Variables \\

local NotificationController = {
	Name = "NotificationController",
	GlobalNotificationAdded = Signal.new(),
	GlobalNotificationRemoved = Signal.new(),
}

-- // Functions \\

function NotificationController:Init()
	AddNotification:Connect(function(Notification: string)
		self:AddNotification(NotificationSerde.Deserialize(Notification))
	end)
	RemoveNotification:Connect(function(UUID: string)
		self:RemoveNotification(UUIDSerde.Deserialize(UUID))
	end)
end

function NotificationController:AddNotification(Notification: Types.Notification)
	self.GlobalNotificationAdded:Fire(Notification)
end

function NotificationController:RemoveNotification(Id: string)
	self.GlobalNotificationRemoved:Fire(Id)
end

return NotificationController
