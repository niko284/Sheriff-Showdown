--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Promise = require(ReplicatedStorage.packages.Promise)
local Types = require(ReplicatedStorage.constants.Types)
local CrateData = require(ReplicatedStorage.constants.Crates)
local EffectUtils = require(ReplicatedStorage.utils.EffectUtils)

local Assets = ReplicatedStorage:FindFirstChild("assets")
local CurrentCamera = workspace.CurrentCamera
local Guns = Assets:FindFirstChild("guns")
local Crates = ReplicatedStorage:FindFirstChild("assets"):FindFirstChild("crates")
local GUN_TWEEN_UP_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CRATE_DOWN_MARKER_NAME = "CrateDown"
local PARTICLE_MARKER_NAME = "ParticleEnabled"

local ShopController = {
    Name = "ShopController"
}

function ShopController:OpenCrate(CrateType: Types.CrateType, GunInfo: Types.ItemInfo)
	local crateModel = Crates:FindFirstChild(CrateType)
	if not crateModel then
		warn("Crate not found: " .. CrateType)
		return
	end

	local crateInfo = CrateData[CrateType]
	if not crateInfo then
		warn("Crate info not found: " .. CrateType)
		return
	end

	local crate = crateModel:Clone() :: Model
	crate:PivotTo(CFrame.new(-4.267, -27822.162, -11.591) * CFrame.Angles(math.rad(90), 0, 0))
	crate.Parent = workspace

	EffectUtils.DisableParticles(crate)
	EffectUtils.DisableBeams(crate)

	-- position the camera to face the front of the crate
	CurrentCamera.CameraType = Enum.CameraType.Scriptable

	local crateCFrame = crate:GetPivot()
	local cratePosition = crate:GetPivot().Position

	-- animate the crate
	local animationController = crate:FindFirstChildOfClass("AnimationController") :: any?
	if not animationController then
		warn("Crate animation controller not found: ", CrateType)
		return
	end

	local openAnimationId = string.format("rbxassetid://%d", crateInfo.OpenAnimation)
	local openAnimation = Instance.new("Animation")
	openAnimation.AnimationId = openAnimationId

	local track = animationController:LoadAnimation(openAnimation) :: AnimationTrack
	track:Play()

	task.wait(0.1) -- wait for the box to snap to its new position (snaps down to animate upwards)

	CurrentCamera.CFrame = CFrame.new(cratePosition + crateCFrame.RightVector * 3.75, cratePosition)
	-- angle the camera down slightly to look at the crate, and also move the camera up a bit
	CurrentCamera.CFrame = CurrentCamera.CFrame * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, 1, 0)

	-- pop the gun out of the crate
	local gunFolder = Guns:FindFirstChild(GunInfo.Name)
	if not gunFolder then
		warn("Gun not found: " .. GunInfo.Name)
		return
	end

	local gunModel = gunFolder.Render:Clone() :: Model
	gunModel:PivotTo(CFrame.new(crateCFrame.Position))

    local primaryPart = gunModel.PrimaryPart :: BasePart 

	track:GetMarkerReachedSignal(PARTICLE_MARKER_NAME):Once(function()
		-- enable particles
		EffectUtils.EnableParticles(crate)
		EffectUtils.EnableBeams(crate)

		gunModel.Parent = workspace
		-- tween the gun upwards
		local gunTween = TweenService:Create(gunModel.PrimaryPart, GUN_TWEEN_UP_INFO, {
			CFrame = primaryPart.CFrame * CFrame.new(0, 1, 0),
		})

		gunTween:Play()
	end)
	track:GetMarkerReachedSignal(CRATE_DOWN_MARKER_NAME):Once(function()
		EffectUtils.DisableBeams(crate)
		EffectUtils.DisableBeams(crate)
		task.wait(0.2)
		local gunSlightDownTween = TweenService:Create(gunModel.PrimaryPart, GUN_TWEEN_UP_INFO, {
			CFrame = primaryPart.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(195), 0),
		})
		gunSlightDownTween:Play()
	end)
	track.Stopped:Once(function()
		-- disable particles
		crate:Destroy()
	end)

	return Promise.fromEvent(track.Stopped, function()
		task.wait(2)
		return true
	end)
end

return ShopController