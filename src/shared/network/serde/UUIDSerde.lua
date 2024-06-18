--!strict

local Format = { 8, 4, 4, 4, 12 }

return {
	-- We assume the UUID is a 128 bit value without braces and with the
	-- 8-4-4-4-12 format.
	Serialize = function(UUID: string): string
		UUID = UUID:gsub("-", "")
		return (UUID:gsub(".", function(c)
			return ("%02X"):format(c:byte())
		end))
	end,
	SerializeTable = function(self: any, uuidList: { string }): { string }
		local serialized = {}
		for i, uuid in uuidList do
			serialized[i] = self.Serialize(uuid)
		end
		return serialized
	end,
	DeserializeTable = function(self: any, serializedList: { string }): { string }
		local uuidList = {}
		for _, uuid in serializedList do
			table.insert(uuidList, self.Deserialize(uuid))
		end
		return uuidList
	end,
	Deserialize = function(encodedUUID: any): string
		local noDashes = (encodedUUID:gsub("..", function(cc)
			return string.char(tonumber(cc, 16) :: number)
		end))
		local UUID = ""
		-- Rebuild UUID with dashes
		local startIndex: number = 1
		for i = 1, #Format do
			local s = noDashes:match("%w+", startIndex):sub(1, Format[i])
			startIndex = select(2, noDashes:find(s, startIndex))
			startIndex += 1
			UUID = (i == 1 and s) or (UUID .. "-" .. s)
		end
		return UUID
	end,
}
