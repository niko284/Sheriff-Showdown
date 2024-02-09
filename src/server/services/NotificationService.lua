--!strict

-- Notification Service
-- August 13th, 2022
-- Nick

-- // Variables \\

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = ReplicatedStorage.constants
local Serde = ReplicatedStorage.serde

local NotificationSerde = require(Serde.NotificationSerde)
local Remotes = require(ReplicatedStorage.Remotes)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local NotificationRemotes = Remotes.Server:GetNamespace("Notifications")
local AddNotification = NotificationRemotes:Get("AddNotification")
local RemoveNotification = NotificationRemotes:Get("RemoveNotification")

-- // Service Variables \\

local NotificationService = {
	Name = "NotificationService",
}

-- // Functions \\

function NotificationService:AddNotification(
	Player: Player,
	Notification: Types.Notification,
	NotificationType: Types.NotificationType
)
	AddNotification:SendToPlayer(Player, NotificationSerde.Serialize(Notification), NotificationType)
end

function NotificationService:RemoveNotification(Player: Player, UUID: string)
	RemoveNotification:SendToPlayer(Player, UUIDSerde.Serialize(UUID))
end

return NotificationService
