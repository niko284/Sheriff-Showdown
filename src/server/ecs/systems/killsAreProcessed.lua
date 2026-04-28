--!strict

local Players = game:GetService("Players")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local function killsAreProcessed(world: jecs.World)
	for eid, killed in world:query(Components.Killed) do
		if killed.expiry and os.time() < killed.expiry then
			continue
		end

		local renderable = world:get(eid, Components.Renderable)

		-- Remove the processRemoval guard so statusEffectsExpire will clean it up next frame.
		world:set(eid, Components.Killed, {
			killerEntityId = killed.killerEntityId,
			expiry = killed.expiry,
			markedKill = killed.markedKill,
		})

		local playerComp = world:get(eid, Components.Player)
		if not playerComp and renderable then
			local player = Players:GetPlayerFromCharacter(renderable.instance)
			if player then
				playerComp = { player = player }
			end
		end

		if playerComp then
			task.spawn(playerComp.player.LoadCharacter, playerComp.player)
		elseif renderable and renderable.instance:IsDescendantOf(game) then
			renderable.instance:Destroy()
		end
	end
	-- Ragdoll, statistics, and knock-on-kill are handled by the Killed OnAdd observer
	-- in server/ecs/observers.lua.
end

return killsAreProcessed
