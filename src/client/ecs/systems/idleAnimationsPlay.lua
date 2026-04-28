--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Animations = Assets:FindFirstChild("animations") :: Folder

local IDLE_ANIMATION = Animations:FindFirstChild("gunidle") :: Animation

-- Per-animator idle track cache to avoid reloading each frame.
local idleTracks: { [Animator]: AnimationTrack } = {}

type State = {
	replecsClient: any,
}

local function idleAnimationsPlay(world: jecs.World, state: State)
	local replecsClient = state.replecsClient

	for _eid, renderable, playerComp, children in
		world:query(Components.Renderable, Components.Player, Components.Children)
	do
		local gunServerEid: number? = children.gunEntityId
		if not gunServerEid then
			continue
		end

		local gunClientId = replecsClient and replecsClient:get_client_entity(gunServerEid)
		if not gunClientId or not world:contains(gunClientId) then
			continue
		end

		local gun = world:get(gunClientId, Components.Gun)
		if not gun or gun.Disabled == true then
			continue
		end

		local owner = world:get(gunClientId, Components.Owner)
		if not owner or owner.OwnedBy ~= playerComp.player then
			continue
		end

		local humanoid = renderable.instance:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator") :: Animator?
		if not animator then
			continue
		end

		local track = idleTracks[animator]
		if not track then
			track = animator:LoadAnimation(IDLE_ANIMATION)
			idleTracks[animator] = track
		end

		if not track.IsPlaying then
			track:Play()
		end
	end
end

return idleAnimationsPlay
