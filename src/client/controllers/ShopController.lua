--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CrateData = require(ReplicatedStorage.constants.Crates)
local EffectUtils = require(ReplicatedStorage.utils.EffectUtils)
local Freeze = require(ReplicatedStorage.packages.Freeze)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Janitor = require(ReplicatedStorage.packages.Janitor)
local MathUtils = require(ReplicatedStorage.utils.MathUtils)
local Promise = require(ReplicatedStorage.packages.Promise)
local Rarities = require(ReplicatedStorage.constants.Rarities)
local Signal = require(ReplicatedStorage.packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Particles = Assets:FindFirstChild("particles") :: Folder
local CurrentCamera = workspace.CurrentCamera
local Guns = Assets:FindFirstChild("guns") :: Folder
local Crates = Assets:FindFirstChild("crates") :: Folder
local Other = Assets:FindFirstChild("other") :: Folder

local CRATE_MAP = Other:FindFirstChild("CrateMap") :: Model
local GUN_TWEEN_UP_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CRATE_DOWN_MARKER_NAME = "CrateDown"
local PARTICLE_MARKER_NAME = "ParticleEnabled"
local ATTACHMENTS_PARTICLES = Particles:FindFirstChild("Attachments") :: BasePart

local ShopController = {
	Name = "ShopController",
	CrateOpened = Signal.new() :: Signal.Signal<Types.Crate, number, () -> ()>,
	OpenAnimations = {},
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

function ShopController:OnInit()
	for crateType, crateInfo in CrateData do
		local openAnimationId = string.format("rbxassetid://%d", crateInfo.OpenAnimation)
		local openAnimation = Instance.new("Animation")
		openAnimation.AnimationId = openAnimationId
		ShopController.OpenAnimations[crateType] = openAnimation
	end
	ContentProvider:PreloadAsync(Freeze.Dictionary.values(ShopController.OpenAnimations))
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

	local rarityInfo = Rarities[GunInfo.Rarity :: any]

	if not rarityInfo then
		return
	end

	local crateJanitor = Janitor.new()

	local particleAttachment = ATTACHMENTS_PARTICLES:FindFirstChild(GunInfo.Rarity :: any) :: Attachment?

	local crateMapCF = CFrame.new(-4.267, -27822.162, -11.591)

	local crateMap = crateJanitor:Add(CRATE_MAP:Clone(), "Destroy")
	crateMap:PivotTo(crateMapCF)
	crateMap.Parent = workspace

	local cratePlacementPart = crateMap:WaitForChild("CrateSpawn") :: BasePart
	local cratePivot = cratePlacementPart:GetPivot()

	local crate = crateModel:Clone() :: Model
	crate:PivotTo(cratePivot * CFrame.Angles(0, math.rad(90), 0))
	crate.Parent = workspace

	EffectUtils.SetDescendantsProperty(crate, "ParticleEmitter", "Enabled", false)
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

	local openAnimation = ShopController.OpenAnimations[CrateType]

	local track = animationController:LoadAnimation(openAnimation) :: AnimationTrack
	track:Play()
	track.TimePosition = 0.03

	task.delay(0.03, function()
		CurrentCamera.CFrame =
			CFrame.lookAt(cratePivot.Position + cratePivot.LookVector * 8 + Vector3.new(0, 2, 0), cratePosition)
		-- angle the camera down slightly to look at the crate, and also move the camera up a bit
	end)

	if rarityInfo.CrateFOV then
		TweenService:Create(CurrentCamera, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			FieldOfView = rarityInfo.CrateFOV,
		}):Play()
	end

	track:AdjustSpeed(1)

	-- pop the gun out of the crate
	local gunFolder = Guns:FindFirstChild(GunInfo.Name) :: Folder?
	if not gunFolder then
		warn("Gun not found: " .. GunInfo.Name)
		return
	end

	local gunModel = crateJanitor:Add(getGunModel(gunFolder), "Destroy")

	gunModel:PivotTo(CFrame.new(crateCFrame.Position))

	if particleAttachment then
		particleAttachment:Clone().Parent = gunModel.PrimaryPart
	end

	local primaryPart = gunModel.PrimaryPart :: BasePart

	track:GetMarkerReachedSignal(PARTICLE_MARKER_NAME):Once(function()
		-- enable particles
		EffectUtils.SetDescendantsProperty(crate, "ParticleEmitter", "Enabled", true)
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
		TweenService:Create(CurrentCamera, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			FieldOfView = 70,
		}):Play()
		task.wait(0.2)
		local gunSlightDownTween = TweenService:Create(gunModel.PrimaryPart :: BasePart, GUN_TWEEN_UP_INFO, {
			CFrame = primaryPart.CFrame * CFrame.new(0, -1, 0) * CFrame.Angles(0, math.rad(45), 0),
		})
		gunSlightDownTween:Play()
		gunSlightDownTween.Completed:Once(function()
			EffectUtils.SetDescendantsProperty(
				cratePlacementPart,
				"ParticleEmitter",
				"Color",
				ColorSequence.new(rarityInfo.Color)
			)
			EffectUtils.EmitParticleCount(cratePlacementPart, rarityInfo.ImpactEmit)

			local minCamDistance = MathUtils.GetModelCornerDistance(gunModel)

			local tween = crateJanitor:Add(
				TweenService:Create(
					CurrentCamera,
					TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.2),
					{
						CFrame = CFrame.lookAt(
							cratePivot.Position + cratePivot.LookVector * (minCamDistance * 2),
							cratePosition
						),
					}
				),
				"Destroy"
			)
			tween:Play()

			local bobTween = crateJanitor:Add(
				TweenService:Create(
					gunModel.PrimaryPart :: BasePart,
					TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0),
					{
						Position = (gunModel.PrimaryPart :: BasePart).Position + Vector3.new(0, 0.5, 0),
					}
				),
				"Destroy"
			)
			bobTween:Play()

			ShopController.CrateOpened:Fire(CrateType, GunId, function()
				crateJanitor:Destroy()
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
