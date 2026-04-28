--!strict

local BlinkClient = require("@client/modules/BlinkClient")
local NotificationSerde = require("@network/serde/NotificationSerde")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")
local UUIDSerde = require("@utilities/UUIDSerde")

-- // Controller Variables \\

local NotificationController = {
	Name = "NotificationController",
	GlobalNotificationAdded = Signal.new(),
	GlobalNotificationRemoved = Signal.new(),
}

-- // Functions \\

function NotificationController:OnInit()
	BlinkClient.NotificationAdd.On(function(Notification: string)
		self:AddNotification(NotificationSerde.Deserialize(Notification))
	end)
	BlinkClient.NotificationRemove.On(function(UUID: string)
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
