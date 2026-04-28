--!strict

local jecs = require("@packages/jecs")

local Actions = require("@ecs/actions")
local Components = require("@ecs/components")
local Generic = require("../Generic")
local InventoryService = require("@services/InventoryService")
local InventoryUtils = require("@utilities/InventoryUtils")
local ItemUtils = require("@utilities/ItemUtils")
local Items = require("@constants/Items")
local Janitor = require("@packages/Janitor")
local RoundService = require("@services/RoundService")
local Sift = require("@packages/Sift")
local Types = require("@constants/Types")

local RevolverRelayExtension = {
	Data = RoundService:GetRoundModeData("Revolver Relay"),
}

function RevolverRelayExtension.StartMatch(Match: Types.Match, RoundInstance: Types.Round, World: jecs.World)
	Generic.StartMatch(Match, RoundInstance, World, false)

	local shiftedPlayersInMatch = Sift.Array.shuffle(RoundService:GetAllPlayersInMatch(Match))
	local relayPlayerGunId = nil
	local relayJanitor = Janitor.new()

	local function giveGunToPlayer(player: Player)
		local entityId = RoundService:GetEntityIdFromPlayer(player)
		local plrComponent: Components.PlayerComponent? = World:get(entityId, Components.Player)

		-- Find existing gun child of this entity.
		local existingGunId: number? = nil
		for childId in World:query(Components.Gun):with(jecs.pair(jecs.ChildOf, entityId)) do
			existingGunId = childId
			break
		end

		local gunId: number

		if not existingGunId then
			local gunToUse: Types.ItemInfo = Items[2]

			if plrComponent then
				local inventory = InventoryService:GetInventory(plrComponent.player)
				local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
				if #equippedGuns > 0 then
					local itemInfo = ItemUtils.GetItemInfoFromId(equippedGuns[1].Id)
					if itemInfo then
						gunToUse = itemInfo
					end
				end
			end

			gunId = World:entity()
			World:set(gunId, Components.Gun, gunToUse.GunStatisticalData)
			World:set(gunId, Components.Owner, { OwnedBy = plrComponent and plrComponent.player })
			World:set(gunId, Components.Item, { Id = gunToUse.Id })
			World:add(gunId, jecs.pair(jecs.ChildOf, entityId))

			relayPlayerGunId = gunId
		else
			gunId = existingGunId
			relayPlayerGunId = gunId

			local gun = World:get(gunId, Components.Gun)
			if gun then
				World:set(gunId, Components.Gun, {
					LocalCooldownMillis = gun.LocalCooldownMillis,
					ReloadTimeMillis = gun.ReloadTimeMillis,
					Damage = gun.Damage,
					BulletLifeTime = gun.BulletLifeTime,
					MaxCapacity = gun.MaxCapacity,
					ReloadTime = gun.ReloadTime,
					CurrentCapacity = gun.CurrentCapacity,
					BulletSpeed = gun.BulletSpeed,
					BulletSoundId = gun.BulletSoundId,
					KnockStrength = gun.KnockStrength,
					Disabled = false,
					Reloading = gun.Reloading,
				})
			end
		end

		relayJanitor:Add(function()
			local gun = World:get(gunId, Components.Gun)
			if gun then
				World:set(gunId, Components.Gun, {
					LocalCooldownMillis = gun.LocalCooldownMillis,
					ReloadTimeMillis = gun.ReloadTimeMillis,
					Damage = gun.Damage,
					BulletLifeTime = gun.BulletLifeTime,
					MaxCapacity = gun.MaxCapacity,
					ReloadTime = gun.ReloadTime,
					CurrentCapacity = gun.CurrentCapacity,
					BulletSpeed = gun.BulletSpeed,
					BulletSoundId = gun.BulletSoundId,
					KnockStrength = gun.KnockStrength,
					Disabled = true,
					Reloading = gun.Reloading,
				})
			end
		end)
	end

	local currentRelayIndex = 1
	local relayPlayerHitMap: { [string]: boolean } = {}

	giveGunToPlayer(shiftedPlayersInMatch[currentRelayIndex])

	local changeRelay = function(_world, player: Player, actionPayload: any)
		local currentRelayPlayer = shiftedPlayersInMatch[currentRelayIndex]
		if player == currentRelayPlayer then
			local gun: Components.Gun? = World:get(actionPayload.fromGun, Components.Gun)
			if not gun then
				return
			end
			local shotId: string = actionPayload.actionId
			task.delay(gun.LocalCooldownMillis / 1000, function()
				if not relayPlayerHitMap[shotId] then
					if Janitor.Is(relayJanitor) then
						relayJanitor:Cleanup()
						currentRelayIndex = currentRelayIndex + 1
						if currentRelayIndex > #shiftedPlayersInMatch then
							currentRelayIndex = 1
						end
						giveGunToPlayer(shiftedPlayersInMatch[currentRelayIndex])
					end
				end
			end)
		end
	end

	local checkBulletHit = function(_world, player: Player, actionPayload: any)
		local currentRelayPlayer = shiftedPlayersInMatch[currentRelayIndex]
		if player == currentRelayPlayer then
			local targetEntityId = actionPayload.targetEntityId
			local targetHealth: Components.Health? = World:get(targetEntityId, Components.Health)
			if targetHealth and targetHealth.causedBy == relayPlayerGunId then
				relayPlayerHitMap[actionPayload.actionId] = true
			end
		end
	end

	table.insert(Actions.Shoot.afterProcess, changeRelay)
	table.insert(Actions.ProjectileHit.afterProcess, checkBulletHit)

	Generic.MatchFinishedPromise(Match):andThen(function()
		table.remove(Actions.Shoot.afterProcess, table.find(Actions.Shoot.afterProcess, changeRelay))
		table.remove(Actions.ProjectileHit.afterProcess, table.find(Actions.ProjectileHit.afterProcess, checkBulletHit))
		relayJanitor:Destroy()
	end)
end

return RevolverRelayExtension
