--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CrateData = require(ReplicatedStorage.constants.Crates)
local EffectUtils = require(ReplicatedStorage.utils.EffectUtils)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Promise = require(ReplicatedStorage.packages.Promise)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local CurrentCamera = workspace.CurrentCamera
local Guns = Assets:FindFirstChild("guns") :: Folder
local Crates = Assets:FindFirstChild("crates") :: Folder
local GUN_TWEEN_UP_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CRATE_DOWN_MARKER_NAME = "CrateDown"
local PARTICLE_MARKER_NAME = "ParticleEnabled"

local ShopController = {
	Name = "ShopController",
	CrateOpened = Signal.new() :: Signal.Signal<Types.Crate, number, () -> ()>,
}

local function getGunModel(gunFolder: Folder): Model
	if gunFolder:FindFirstChild("Render") then
		local gunModel = gunFolder:FindFirstChild("Render") :: Model
		local mod = gunModel:Clone()
		return mod
	else
		local mod = Instance.new("Model")
		local handsFolder = gunFolder:FindFirstChild("Hands") :: Folder
		local handAttach = handsFolder:FindFirstChild("Handattach") :: Accessory
		local handle = handAttach:FindFirstChild("Handle") :: BasePart
		local handleClone = handle:Clone()
		mod.PrimaryPart = handleClone
		handleClone.Parent = mod
		return mod
	end
end

function ShopController:OpenMultipleCrates(Crate: Types.Crate, GunInfo: { Types.Item })
	for _, gun in ipairs(GunInfo) do
		local gunInfo = ItemUtils.GetItemInfoFromId(gun.Id)
		ShopController:OpenCrate(Crate, gunInfo.Id):await()
		task.wait(0.2)
	end
end

function ShopController:OpenCrate(CrateType: Types.Crate, GunId: number): any
	local GunInfo = ItemUtils.GetItemInfoFromId(GunId)
	if not GunInfo then
		warn("Gun info not found: " .. GunId)
		return
	end
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
	track.TimePosition = 0.03
	track:AdjustSpeed(0)

	task.delay(0.03, function()
		CurrentCamera.CFrame = CFrame.new(cratePosition + crateCFrame.RightVector * 3.75, cratePosition)
		-- angle the camera down slightly to look at the crate, and also move the camera up a bit
		CurrentCamera.CFrame = CurrentCamera.CFrame * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, 1, 0)
	end)

	track:AdjustSpeed(1)

	-- pop the gun out of the crate
	local gunFolder = Guns:FindFirstChild(GunInfo.Name) :: Folder?
	if not gunFolder then
		warn("Gun not found: " .. GunInfo.Name)
		return
	end

	local gunModel = getGunModel(gunFolder)

	gunModel:PivotTo(CFrame.new(crateCFrame.Position))

	local primaryPart = gunModel.PrimaryPart :: BasePart

	track:GetMarkerReachedSignal(PARTICLE_MARKER_NAME):Once(function()
		-- enable particles
		EffectUtils.EnableParticles(crate)
		EffectUtils.EnableBeams(crate)

		gunModel.Parent = workspace
		-- tween the gun upwards
		local gunTween = TweenService:Create(gunModel.PrimaryPart :: BasePart, GUN_TWEEN_UP_INFO, {
			CFrame = primaryPart.CFrame * CFrame.new(0, 1, 0),
		})

		gunTween:Play()
	end)
	track:GetMarkerReachedSignal(CRATE_DOWN_MARKER_NAME):Once(function()
		EffectUtils.DisableBeams(crate)
		EffectUtils.DisableBeams(crate)
		task.wait(0.2)
		local gunSlightDownTween = TweenService:Create(gunModel.PrimaryPart :: BasePart, GUN_TWEEN_UP_INFO, {
			CFrame = primaryPart.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(195), 0),
		})
		gunSlightDownTween:Play()
		gunSlightDownTween.Completed:Once(function()
			ShopController.CrateOpened:Fire(CrateType, GunId, function()
				gunModel:Destroy()
				--crate:Destroy()
			end)
		end)
	end)
	track.Stopped:Once(function()
		-- disable particles
		crate:Destroy()
	end)

	return Promise.fromEvent(track.Stopped, function()
		return true
	end):andThen(function()
		return Promise.delay(2)
	end)
end

return ShopController
