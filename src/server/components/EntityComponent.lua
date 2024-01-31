-- Server Entity Component
-- April 16th, 2023
-- Nick

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local ActionShared = ReplicatedStorage.ActionShared
local Services = ServerScriptService.services

local Component = require(Packages.Component)
local EntityModule = require(ActionShared.Entity)
local EntityService = require(Services.EntityService)
local Janitor = require(Packages.Janitor)
local NevermoreService = require(Services.NevermoreService)

local ragdollBinders = NevermoreService:GetPackage("RagdollBindersServer")

-- // Entity \\

local EntityComponent = Component.new({
	Tag = "Entity",
	Ancestors = { workspace },
	Extensions = {},
})

-- // Functions \\

function EntityComponent:Construct()
	self._Janitor = Janitor.new()

	self._Player = Players:GetPlayerFromCharacter(self.Instance)

	local Entity = EntityModule.MakeEntityState(self.Instance)

	self.Entity = Entity

	-- we don't want joints to break on death b/c we have grip in the game.
	Entity.Humanoid.BreakJointsOnDeath = false
	Entity.Humanoid:GetPropertyChangedSignal("BreakJointsOnDeath"):Connect(function()
		if Entity.Humanoid.BreakJointsOnDeath then
			Entity.Humanoid.BreakJointsOnDeath = false
		end
	end)

	if self._Player then -- Player entities automatically get the Ragdollable binder through PlayerHumanoidBinder
		EntityService.PlayerEntityReady:Fire(self._Player, self.Entity)
		--[[else -- If not a player, we manually add the Ragdollable binder so we can ragdoll our non-player entities.
		ragdollBinders.Ragdollable:Bind(Entity.Humanoid)
		self._Janitor:Add(function()
			ragdollBinders.Ragdollable:Unbind(Entity.Humanoid)
		end)--]]
	end
end

function EntityComponent:Stop()
	self._Janitor:Cleanup()
end

return EntityComponent
