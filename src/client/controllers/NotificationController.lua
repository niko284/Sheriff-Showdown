--!strict

local Net = require("@packages/Net")
local NotificationSerde = require("@network/serde/NotificationSerde")
local Remotes = require("@network/Remotes")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")
local UUIDSerde = require("@network/serde/UUIDSerde")

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

function NotificationController:OnInit()
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
