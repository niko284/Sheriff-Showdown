--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService.services

local Actions = require(ReplicatedStorage.ecs.actions)
local Components = require(ReplicatedStorage.ecs.components)
local Generic = require(script.Parent.Parent.Generic)
local InventoryService = require(Services.InventoryService)
local InventoryUtils = require(ReplicatedStorage.utils.InventoryUtils)
local Items = require(ReplicatedStorage.constants.Items)
local Matter = require(ReplicatedStorage.packages.Matter)
local RoundService = require(Services.RoundService)
local Sift = require(ReplicatedStorage.packages.Sift)
local Types = require(ReplicatedStorage.constants.Types)

local RevolverRelayExtension = {
	Data = RoundService:GetRoundModeData("Distraction"),
}

function RevolverRelayExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: Matter.World)
	Generic.StartMatch(Match, RoundInstance, World, false)

	local shiftedPlayersInMatch = Sift.Array.shuffle(RoundService:GetAllPlayersInMatch(Match))
	local relayPlayerGunId = nil

	local function giveGunToPlayer(player: Player)
		local entityId = RoundService:GetEntityIdFromPlayer(player)

		local plrComponent: Components.PlayerComponent? = World:get(entityId, Components.Player)
		local children: Components.Children = World:get(entityId, Components.Children)

		local newChildren = table.clone(children)

		local gunToUse = Items[2] -- default gun if nothing is equipped

		if plrComponent then
			local inventory = InventoryService:GetInventory(plrComponent.player)
			local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
			if #equippedGuns > 0 then
				gunToUse = equippedGuns[1] :: any
			end
		end

		local gunId = World:spawn(
			Components.Gun(gunToUse.GunStatisticalData),
			Components.Owner({
				OwnedBy = plrComponent and plrComponent.player,
			}),
			Components.Item({ Id = gunToUse.Id })
		)

		relayPlayerGunId = gunId

		table.insert(newChildren, gunId)
		World:insert(entityId, Components.Children({ children = newChildren }))
	end

	local currentRelayPlayer = shiftedPlayersInMatch[1]
	local relayPlayerHit = false

	giveGunToPlayer(currentRelayPlayer)

	-- @note: we probably should check bullethit action afterprocess to mark if the bullet hit someone. then in the task.delay, we can check for this flag.
	local changeRelay = function(_world, player: Player, actionPayload: any)
		if player == currentRelayPlayer then
			local spawnedBulletEntityId = actionPayload.spawnedBullet
			local bulletExpireTime = World:get(spawnedBulletEntityId, Components.Lifetime)
			task.delay(bulletExpireTime.expiry, function()
				if not relayPlayerHit then
					-- move to next relay player since we missed.
				end
			end)
		end
	end

	local checkBulletHit = function(_world, player: Player, actionPayload: any)
		if player == currentRelayPlayer then
			local targetEntityId = actionPayload.targetEntityId

			local targetHealth: Components.Health? = World:get(targetEntityId, Components.Health)

			if targetHealth and targetHealth.causedBy == relayPlayerGunId then -- our relay player's bullet hit someone
				relayPlayerHit = true
			end
		end
	end

	table.insert(Actions.Shoot.afterProcess, changeRelay)
	table.insert(Actions.BulletHit.afterProcess, checkBulletHit)

	Generic.MatchFinishedPromise(Match):andThen(function()
		table.remove(Actions.Shoot.afterProcess, table.find(Actions.Shoot.afterProcess, changeRelay))
		table.remove(Actions.BulletHit.afterProcess, table.find(Actions.BulletHit.afterProcess, checkBulletHit))
	end)
end

return RevolverRelayExtension
