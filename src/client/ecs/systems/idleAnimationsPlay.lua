--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = require(ReplicatedStorage.ecs.components)
local Matter = require(ReplicatedStorage.packages.Matter)
local MatterReplication = require(ReplicatedStorage.packages.MatterReplication)
local Types = require(ReplicatedStorage.constants.Types)
local useAnimation = require(ReplicatedStorage.ecs.hooks.useAnimation)

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Animations = Assets:FindFirstChild("animations") :: Folder

local IDLE_ANIMATION = Animations:FindFirstChild("gunidle") :: Animation

local function idleAnimationsPlay(world: Matter.World)
	for
		_eid,
		renderable: Components.Renderable<Types.Character>,
		player: Components.PlayerComponent,
		children: Components.Children<Types.TargetChildren>
	in world:query(Components.Renderable, Components.Player, Components.Children) do
		local gunChild = children.children.gunEntityId

		if gunChild then
			local gunClientId = MatterReplication.resolveServerId(world, gunChild)
			if not gunClientId or not world:contains(gunClientId) then
				continue
			end
			local gun: Components.Gun? = world:get(gunClientId, Components.Gun)
			if gun then
				local ownedBy: Components.Owner? = world:get(gunClientId, Components.Owner)
				if not ownedBy or ownedBy.OwnedBy ~= player.player then
					continue
				end
				if gun.Disabled == true then
					continue
				end
				local animator = renderable.instance.Humanoid:FindFirstChildOfClass("Animator") :: Animator
				useAnimation(animator, IDLE_ANIMATION, false)
			end
		end
	end
end

return idleAnimationsPlay
