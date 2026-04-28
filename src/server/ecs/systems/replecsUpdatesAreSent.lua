--!strict

local BlinkServer = require("@server/modules/BlinkServer")

local function replecsUpdatesAreSent(_world, state)
	for player, changes, variants in state.replecsServer:collect_updates() do
		BlinkServer.ReplecsUpdate.Fire(player, { Changes = changes, Variants = variants })
	end
	for player, changes, variants in state.replecsServer:collect_unreliable() do
		BlinkServer.ReplecsUnreliableUpdate.Fire(player, { Changes = changes, Variants = variants })
	end
end

return replecsUpdatesAreSent
