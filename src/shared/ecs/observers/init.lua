--!strict

local RunService = game:GetService("RunService")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local idAttribute = if RunService:IsServer() then "serverEntityId" else "clientEntityId"

export type Context = {
	isClient: boolean,
	replecsClient: any?,
}

local function registerObservers(world: jecs.World, ctx: Context)
	local Renderable = Components.Renderable
	local Transform = Components.Transform

	-- Track Renderable signal connections per entity so we can clean up on removal.
	local ancestryConnections: { [jecs.Entity]: RBXScriptConnection } = {}

	local function bindAncestry(entity: jecs.Entity, instance: Instance)
		if ancestryConnections[entity] then
			ancestryConnections[entity]:Disconnect()
		end
		ancestryConnections[entity] = instance.AncestryChanged:Connect(function()
			if instance:IsDescendantOf(game) then
				return
			end
			if not world:contains(entity) then
				return
			end

			-- Server-replicated entities on the client are owned by the server;
			-- removing the Renderable here would race with replication.
			if ctx.isClient and ctx.replecsClient and ctx.replecsClient:get_server_entity(entity) then
				return
			end

			if world:has(entity, Renderable) then
				world:remove(entity, Renderable)
			end
		end)
	end

	world:set(Renderable, jecs.OnAdd, function(entity: jecs.Entity, _id: jecs.Id, value: Components.Renderable)
		if not value.instance then
			return
		end
		value.instance:SetAttribute(idAttribute, entity)
		bindAncestry(entity, value.instance)

		local transform = world:get(entity, Transform)
		if transform and not transform.doNotReconcile then
			local pv = value.instance :: PVInstance
			pv:PivotTo(transform.cframe)
		end
	end)

	world:set(Renderable, jecs.OnChange, function(entity: jecs.Entity, _id: jecs.Id, value: Components.Renderable)
		value.instance:SetAttribute(idAttribute, entity)
		bindAncestry(entity, value.instance)
	end)

	world:set(Renderable, jecs.OnRemove, function(entity: jecs.Entity)
		local conn = ancestryConnections[entity]
		if conn then
			conn:Disconnect()
			ancestryConnections[entity] = nil
		end

		local prev = world:get(entity, Renderable)
		if not prev or not prev.instance then
			return
		end

		if ctx.isClient and ctx.replecsClient and ctx.replecsClient:get_server_entity(entity) then
			return
		end

		prev.instance:Destroy()
	end)

	world:set(Transform, jecs.OnAdd, function(entity: jecs.Entity, _id: jecs.Id, value: Components.Transform)
		if value.doNotReconcile then
			return
		end
		local renderable = world:get(entity, Renderable)
		if renderable then
			local pv = renderable.instance :: PVInstance
			pv:PivotTo(value.cframe)
		end
	end)

	world:set(Transform, jecs.OnChange, function(entity: jecs.Entity, _id: jecs.Id, value: Components.Transform)
		if value.doNotReconcile then
			return
		end
		local renderable = world:get(entity, Renderable)
		if renderable then
			local pv = renderable.instance :: PVInstance
			pv:PivotTo(value.cframe)
		end
	end)
end

return registerObservers
