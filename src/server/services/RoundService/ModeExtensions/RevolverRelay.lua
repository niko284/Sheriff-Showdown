--!strict

local jecs = require("@packages/jecs")

local Actions = require("@ecs/actions")
local Components = require("@ecs/components")
local Generic = require("../Generic")
local InventoryService = require("@services/InventoryService")
local InventoryUtils = require("@utilities/InventoryUtils")
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
		local childComp: Components.Children? = World:get(entityId, Components.Children)
		local gunId = nil

		if not childComp or not childComp.gunEntityId then
			local newChildren: Components.Children = childComp and table.clone(childComp) or {}

			local gunToUse = Items[2]

			if plrComponent then
				local inventory = InventoryService:GetInventory(plrComponent.player)
				local equippedGuns = InventoryUtils.GetItemsOfType(inventory, "Gun", true)
				if #equippedGuns > 0 then
					gunToUse = equippedGuns[1] :: any
				end
			end

			gunId = World:entity()
			World:set(gunId, Components.Gun, gunToUse.GunStatisticalData)
			World:set(gunId, Components.Owner, { OwnedBy = plrComponent and plrComponent.player })
			World:set(gunId, Components.Item, { Id = gunToUse.Id })
			World:add(gunId, jecs.pair(jecs.ChildOf, entityId))
			World:set(gunId, Components.Children, {})

			relayPlayerGunId = gunId

			newChildren.gunEntityId = gunId
			World:set(entityId, Components.Children, newChildren)
		else
			gunId = childComp.gunEntityId

			local gun = World:get(gunId, Components.Gun)
			if gun then
				World:set(gunId, Components.Gun, {
					LocalCooldownMillis = gun.LocalCooldownMillis,
					ReloadTimeMillis = gun.ReloadTimeMillis,
					Damage = gun.Damage,
					CriticalDamage = gun.CriticalDamage,
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
					CriticalDamage = gun.CriticalDamage,
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
	-- maps actionId → true when that shot hit someone before the bullet cooldown expired
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
