--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require("@packages/jecs")

local Components = require("@ecs/components")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Animations = Assets:FindFirstChild("animations") :: Folder

local IDLE_ANIMATION = Animations:FindFirstChild("gunidle") :: Animation

local idleTracks: { [Animator]: AnimationTrack } = {}

local function idleAnimationsPlay(world: jecs.World)
	for eid, renderable, _playerComp in world:query(Components.Renderable, Components.Player) do
		local gun: Components.Gun? = nil

		for _gunClientId, gunComp in world:query(Components.Gun):with(jecs.pair(jecs.ChildOf, eid)) do
			gun = gunComp
			break
		end

		if not gun or gun.Disabled == true then
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
