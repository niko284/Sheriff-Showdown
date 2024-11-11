local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage.packages.Matter)

local function useAnimation(animator: Animator, animation: Animation, pause: boolean)
	if pause == nil then
		pause = false
	end

	local state = Matter.useHookState(animator, function(storage)
		if storage.animationTrack then
			storage.animationTrack:Stop()
			storage.animationTrack = nil
			storage.animation = nil
		end
	end)

	if state.animation ~= animation then
		state.animation = animation
		if state.animationTrack then
			state.animationTrack:Stop()
			state.played = nil
			state.animationTrack = nil
		end
	end

	if state.animationTrack == nil then
		state.animationTrack = animator:LoadAnimation(animation)
	end

	local looped = state.animationTrack.Looped

	if not state.animationTrack.IsPlaying and (looped or (not looped and not state.played)) then
		state.played = true
		state.animationTrack:Play()
	end

	-- pause or unpause the animation
	state.animationTrack:AdjustSpeed(pause and 0 or 1)

	return state.animationTrack
end

return useAnimation
