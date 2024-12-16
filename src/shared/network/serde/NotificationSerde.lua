--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MsgPack = require(ReplicatedStorage.utils.MsgPack)
local Types = require(ReplicatedStorage.constants.Types)
local UUIDSerde = require(ReplicatedStorage.network.serde.UUIDSerde)
local t = require(ReplicatedStorage.packages.t)

local notificationMap = {
	"Title",
	"Description",
	"UUID",
	"Duration",
	-- Optional fields in the end
	"ClickToDismiss",
	"Options",
	"OnFade",
	"OnDismiss",
}
local notificationStruct = t.strictInterface({
	Title = t.string,
	Description = t.string,
	UUID = t.string,
	Duration = t.numberPositive,
	ClickToDismiss = t.optional(t.boolean),
	Options = t.optional(t.table),
	OnFade = t.optional(t.callback),
	OnDismiss = t.optional(t.callback),
})

-- // Serde Layer \\

return {
	Serialize = function(Notification: Types.Notification): string
		assert(notificationStruct(Notification))
		local serializedNotification = {}
		-- Serialize the UUID
		for index, key in notificationMap do
			serializedNotification[index] = Notification[key]
			if key == "UUID" then
				-- Serialize
				serializedNotification[index] = UUIDSerde.Serialize(Notification[key])
			end
		end
		return MsgPack.encode(serializedNotification)
	end,
	SerializeTable = function(self: any, notifications: { Types.Notification }): { string }
		local serializedNotifications = {}
		for _, notification in notifications do
			table.insert(serializedNotifications, self.Serialize(notification))
		end
		return serializedNotifications
	end,
	Deserialize = function(SerializedNotification: string): Types.Notification
		local decodedNotification = MsgPack.decode(SerializedNotification)
		local notification = {}
		for index, key in notificationMap do
			notification[key] = decodedNotification[index]
		end
		if notification.UUID then
			notification.UUID = UUIDSerde.Deserialize(notification.UUID)
		end
		return notification
	end,
	DeserializeTable = function(self: any, SerializedTable: { string }): { Types.Notification }
		local deserialize = {}
		for _i, serializedNotification in SerializedTable do
			table.insert(deserialize, self.Deserialize(serializedNotification))
		end
		return deserialize
	end,
}
