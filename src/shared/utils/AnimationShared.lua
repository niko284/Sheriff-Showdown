--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils

local InstanceUtils = require(Utils.InstanceUtils)
local Styles = require(Constants.Styles)
local Types = require(Constants.Types)

local IS_SERVER = RunService:IsServer()

local AnimationData: { [Types.Entity]: Types.AnimationInfo } = {}

local AnimationShared = {}

if not IS_SERVER then
	AnimationShared["Cached"] = {}
end

function AnimationShared.MakeAnimationInfo(Entity: Types.Entity)
	local AnimData = AnimationData[Entity]
	assert(not AnimData, "Animation data already exists.")

	local styleName = Entity:GetAttribute("Style") or "Default"
	local styleDict = AnimationShared.GetStyleFromName(styleName)

	Entity:SetAttribute("Style", styleName)

	AnimationData[Entity] = { Animations = {}, StyleName = styleName, StyleDictionary = styleDict }
	AnimationShared.SetStyle(Entity, styleName)

	Entity:GetAttributeChangedSignal("Style"):Connect(function()
		AnimationShared.SetStyle(Entity, Entity:GetAttribute("Style"))
	end)
end

function AnimationShared.PlayPassive(Entity: Types.Entity, Animation: Animation, TrackProps: { [string]: any }?): AnimationTrack
	local AnimData = AnimationData[Entity]
	assert(AnimData, "Animation data doesn't exist.")

	if AnimData.CurrentPassive == Animation then
		return AnimData.Animations[Animation]
	end

	if AnimData.CurrentPassive then
		AnimData.Animations[AnimData.CurrentPassive]:Stop()
	end
	if not AnimData.Animations[Animation] then
		AnimData.Animations[Animation] = AnimationShared.PlayAnimation(Animation, Entity, TrackProps)
	end

	AnimData.CurrentPassive = Animation
	AnimData.Animations[Animation]:Play()
	return AnimData.Animations[Animation]
end

function AnimationShared.PlayAnimation(Animation: Animation, Entity: Types.Entity, TrackProps: { [string]: any }?): AnimationTrack
	local AnimData = AnimationData[Entity]
	assert(AnimData, "Animation data doesn't exist.")

	local Animator = Entity.Humanoid:FindFirstChildOfClass("Animator")

	local Speed = TrackProps and TrackProps.Speed or 1
	if TrackProps and TrackProps.Speed then -- speed does not exist in AnimationTrack props so we have to remove it
		TrackProps.Speed = nil
	end

	assert(Animator, string.format("No animation for entity [%s]", Entity.Name))
	local AnimationTrack = Animator:LoadAnimation(Animation)

	if TrackProps then
		InstanceUtils.AssignProps(AnimationTrack, TrackProps)
	end
	AnimationTrack:AdjustSpeed(Speed)
	AnimationTrack:Play()

	return AnimationTrack
end
function AnimationShared.GetEntityStyle(Entity: Types.Entity): Types.Style
	local AnimData = AnimationData[Entity]
	assert(AnimData, "Animation data doesn't exist.")

	-- Any field not populated in the style will be populated with the default style fields.
	-- This is to allow for partial styles to be used.
	local inheritedStyle = Styles.Default
	local style = AnimData.StyleDictionary
	local newStyle = style
	-- fill in empty fields with inherited style
	for key, value in pairs(inheritedStyle) do
		if not newStyle[key] then
			newStyle[key] = value
		end
	end
	return newStyle :: Types.Style | any
end

function AnimationShared.GetStyleFromName(StyleName: string): Types.Style
	local style = Styles[StyleName]
	assert(style, string.format("Style [%s] doesn't exist.", StyleName))

	-- Any field not populated in the style will be populated with the default style fields.
	-- This is to allow for partial styles to be used.
	local inheritedStyle = Styles.Default
	local newStyle = style
	-- fill in empty fields with inherited style
	for key, value in pairs(inheritedStyle) do
		if not newStyle[key] then
			newStyle[key] = value
		end
	end
	return newStyle :: Types.Style | any
end

function AnimationShared.GetStyleName(Entity: Types.Entity): string
	local AnimData = AnimationData[Entity]
	assert(AnimData, "Animation data doesn't exist.")

	return AnimData.StyleName
end

function AnimationShared.SetStyle(Entity: Types.Entity, Style: string)
	local AnimData = AnimationData[Entity]
	assert(AnimData, "Animation data doesn't exist.")
	local StyleDict = Styles[Style]

	if StyleDict then
		AnimData.StyleName = Style
		AnimData.StyleDictionary = AnimationShared.GetStyleFromName(Style) -- We use this method to inherit the default style, otherwise we wouldn't be able to inherit.
		local Animator = Entity:FindFirstChildOfClass("Animator")
		AnimationShared.ChangeAnimations(Entity, AnimData.StyleDictionary)
		if Animator then
			for _, playingTrack in pairs(Animator:GetPlayingAnimationTracks()) do
				playingTrack:Stop(0)
			end
		end
	end
end

function AnimationShared.ChangeAnimations(Entity: Types.Entity, StyleDict: Types.Style)
	local Animate = Entity:FindFirstChild("Animate")
	if Animate and StyleDict.PassiveAnimations then
		local Humanoid = Entity:FindFirstChildOfClass("Humanoid")
		local Animator = Entity:FindFirstChildOfClass("Animator")

		if Animator then
			-- Stop all animation tracks
			for _, playingTrack in pairs(Animator:GetPlayingAnimationTracks()) do
				playingTrack:Stop(0)
			end
		end

		for animName, anim in pairs(StyleDict.PassiveAnimations) do
			local animateObj = Animate:FindFirstChild(animName)
			if animateObj then
				for _, animObj in animateObj:GetChildren() do
					if animObj:IsA("Animation") then
						animObj.AnimationId = anim.AnimationId
					end
				end
			end
		end

		if Humanoid then
			Humanoid:ChangeState(Enum.HumanoidStateType.Landed)
		end
	end
end

function AnimationShared.GetPlayingAnimations(Entity: Types.Entity): { Types.PlayingAnimation }
	local entityHumanoid = Entity:FindFirstChildOfClass("Humanoid")
	if entityHumanoid then
		local animator = entityHumanoid:FindFirstChildOfClass("Animator")
		if animator then
			local playingAnimations = {}
			for _, animationTrack in animator:GetPlayingAnimationTracks() do
				-- get only numbers from animationid
				local animationId = string.match(animationTrack.Animation.AnimationId, "%d+")
				table.insert(playingAnimations, {
					Track = animationTrack,
					Animation = animationTrack.Animation,
					AnimationId = tonumber(animationId) :: number,
				})
			end
			return playingAnimations
		end
	else
		-- As of right now, we can only get playing animations from humanoid entities on environments other than the local client because Roblox replicates animations from the Animator object.
		return {}
	end
	return {}
end

return AnimationShared
