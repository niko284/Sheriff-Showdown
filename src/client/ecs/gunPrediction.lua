--!strict

local Players = game:GetService("Players")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")
local Util = require("@ecs/Util")

local clientPredicting = false
local predictedCap: { [number]: number } = {}
local predictedReload: { [number]: boolean } = {}
local lastOwner: { [number]: Player? } = {}

local GunPrediction = {}

function GunPrediction.predict(world: jecs.World, eid: number, newGun: Components.Gun)
	predictedCap[eid] = newGun.CurrentCapacity
	predictedReload[eid] = newGun.Reloading == true
	lastOwner[eid] = Util.GetOwnerPlayer(world, eid :: any)

	clientPredicting = true
	world:set(eid :: any, Components.Gun, newGun)
	clientPredicting = false
end

function GunPrediction.register(world: jecs.World)
	world:set(Components.Gun, jecs.OnChange, function(entity: jecs.Entity, _id: jecs.Id, newValue: Components.Gun)
		if clientPredicting then
			return
		end

		local owner = Util.GetOwnerPlayer(world, entity)

		if lastOwner[entity :: any] ~= owner then
			predictedCap[entity :: any] = nil
			predictedReload[entity :: any] = nil
			lastOwner[entity :: any] = owner
		end

		if owner ~= Players.LocalPlayer then
			return
		end

		local cap = predictedCap[entity :: any]
		if cap == nil then
			return
		end

		local reload = predictedReload[entity :: any] == true
		if newValue.CurrentCapacity == cap and (newValue.Reloading == true) == reload then
			return
		end

		local restored = table.clone(newValue)
		restored.CurrentCapacity = cap
		restored.Reloading = reload or nil

		clientPredicting = true
		world:set(entity, Components.Gun, restored)
		clientPredicting = false
	end)

	world:set(Components.Gun, jecs.OnRemove, function(entity: jecs.Entity)
		predictedCap[entity :: any] = nil
		predictedReload[entity :: any] = nil
		lastOwner[entity :: any] = nil
	end)
end

return GunPrediction
