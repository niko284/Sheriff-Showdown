local Deserializer = {}

type Serializer = {
	Serialize: (any) -> string,
	Deserialize: (string) -> any,
}
type NextMiddleware = (Player: Player, ...any) -> any

local function DeserializerMiddleware(deserializers: { Serializer })
	return function(next: NextMiddleware, _instance: Instance)
		return function(player: Player, ...: any)
			local deserialized = {}
			local args = { ... }
			for i, arg in args do
				local deserializer = deserializers[i]
				if deserializer then
					local success, deserializedArg = pcall(function()
						if typeof(deserializer) == "function" then
							return deserializer(arg)
						else
							return deserializer.Deserialize(arg)
						end
					end)
					if success then
						deserialized[i] = deserializedArg
					else
						return false
					end
				else
					deserialized[i] = arg
				end
			end
			return next(player, unpack(deserialized))
		end
	end
end

Deserializer.__call = function(_, ...: any)
	return DeserializerMiddleware(...)
end

return setmetatable({}, Deserializer)
