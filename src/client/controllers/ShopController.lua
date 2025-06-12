--!strict

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CrateData = require("@constants/Crates")
local EffectUtils = require("@utilities/EffectUtils")
local Freeze = require("@packages/Freeze")
local InterfaceController = require("./InterfaceController")
local ItemUtils = require("@utilities/ItemUtils")
local Janitor = require("@packages/Janitor")
local MathUtils = require("@utilities/MathUtils")
local Promise = require("@packages/Promise")
local Rarities = require("@constants/Rarities")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local Particles = Assets:FindFirstChild("particles") :: Folder
local CurrentCamera = workspace.CurrentCamera
local Guns = Assets:FindFirstChild("guns") :: Folder
local Crates = Assets:FindFirstChild("crates") :: Folder
local Other = Assets:FindFirstChild("other") :: Folder

local CRATE_MAP = Other:FindFirstChild("CrateMap") :: Model
local GUN_TWEEN_UP_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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
	local crateStand = crateMap:WaitForChild("Stand") :: Model
	local dustPart = crateStand:WaitForChild("DustPart") :: BasePart

	local crate = crateJanitor:Add(crateModel:Clone(), "Destroy") :: Model
	local crateGoal = cratePivot * CFrame.Angles(0, math.rad(90), 0)
	local primaryPart = crate.PrimaryPart :: BasePart

	crate:PivotTo(crateGoal * CFrame.new(crateGoal:VectorToObjectSpace(Vector3.yAxis).Unit * 8))
	crate.Parent = workspace

	EffectUtils.SetDescendantsProperty(crate, "ParticleEmitter", "Enabled", false)
	EffectUtils.DisableBeams(crate)

	-- position the camera to face the front of the crate
	CurrentCamera.CameraType = Enum.CameraType.Scriptable

	InterfaceController.HideHUD:Fire(true)
	InterfaceController.InterfaceChanged:Fire(nil)

	CurrentCamera.CFrame = CFrame.lookAt(
		cratePivot.Position + cratePivot.LookVector * 8 + Vector3.new(0, 3, 0),
		cratePlacementPart.Position
	)

	-- animate the crate
	local animationController = crate:FindFirstChildOfClass("AnimationController") :: any?
	if not animationController then
		warn("Crate animation controller not found: ", CrateType)
		return
	end

	local openAnimation = ShopController.OpenAnimations[CrateType]

	local track = animationController:LoadAnimation(openAnimation) :: AnimationTrack

	local crateTween =
		TweenService:Create(primaryPart, TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			CFrame = crateGoal,
		})

	task.wait(1)

	crateTween:Play()
	crateTween.Completed:Wait()

	--[[local origPivot = primaryPart:GetPivot()
	local crateSpring = Spring.new(0)
	crateSpring.Damper = 0.1

	local on = false

	local elapsed = 0
	crateSpring.Speed = 25

	local targetOffset = 2
	local shakeTime = 2

	local shakeCrate = crateJanitor:Add(
		RunService.Heartbeat:Connect(function(_dt: number)
			local offsetCF = CFrame.new(0, 0, crateSpring.Position)
			primaryPart:PivotTo(origPivot * offsetCF)
			crateSpring.Target = targetOffset
			targetOffset = targetOffset * (1 - (elapsed / shakeTime)) * (on and -1 or 1)
			on = not on
		end),
		"Disconnect"
	)

	task.wait(shakeTime)--]]

	-- shakeCrate:Disconnect()

	-- pop the gun out of the crate
	local gunFolder = Guns:FindFirstChild(GunInfo.Name) :: Folder?
	if not gunFolder then
		warn("Gun not found: " .. GunInfo.Name)
		return
	end

	local gunModel = crateJanitor:Add(getGunModel(gunFolder), "Destroy")
	local gunPrimary = gunModel.PrimaryPart :: BasePart
	local crateOffset = (gunFolder:GetAttribute("crateOffset") or CFrame.identity) :: CFrame

	gunModel:PivotTo(cratePivot * crateOffset)

	if particleAttachment then
		particleAttachment:Clone().Parent = gunPrimary
	end

	track:GetMarkerReachedSignal(PARTICLE_MARKER_NAME):Once(function()
		-- enable particles
		EffectUtils.SetDescendantsProperty(crate, "ParticleEmitter", "Enabled", true)
		EffectUtils.EnableBeams(crate)

		gunModel.Parent = workspace
		-- tween the gun upwards
		local gunTween = TweenService:Create(gunPrimary :: BasePart, GUN_TWEEN_UP_INFO, {
			CFrame = gunModel:GetPivot()
				* CFrame.new(gunModel:GetPivot():VectorToObjectSpace(Vector3.yAxis).Unit * 3)
				* CFrame.Angles(0, math.rad(90), 0),
		})

		gunTween:Play()
	end)

	local dustShown = false
	track:GetMarkerReachedSignal("DustShow"):Connect(function()
		dustShown = not dustShown
		EffectUtils.SetDescendantsProperty(dustPart, "ParticleEmitter", "Enabled", dustShown)
	end)

	track.Stopped:Once(function()
		EffectUtils.DisableBeams(crate)
		EffectUtils.DisableBeams(crate)

		local crateOut =
			TweenService:Create(primaryPart, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
				CFrame = primaryPart.CFrame * CFrame.new(0, 0, -20),
			})
		crateOut:Play()
		crateOut.Completed:Wait()

		TweenService:Create(CurrentCamera, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			FieldOfView = 70,
		}):Play()

		task.wait(0.2)

		local gunSlightDownTween = TweenService:Create(gunPrimary :: BasePart, GUN_TWEEN_UP_INFO, {
			CFrame = gunPrimary.CFrame
				* CFrame.new(gunPrimary.CFrame:VectorToObjectSpace(Vector3.yAxis).Unit * -2.5)
				* CFrame.Angles(0, math.rad(15), 0),
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

			local gunPivot = gunPrimary:GetPivot()

			local minCamDistance = MathUtils.GetModelCornerDistance(gunModel)

			local tween = crateJanitor:Add(
				TweenService:Create(
					CurrentCamera,
					TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.2),
					{
						CFrame = CFrame.lookAt(
							gunPivot.Position + cratePivot.LookVector * (minCamDistance * 2.5),
							gunPivot.Position
						),
					}
				),
				"Destroy"
			)
			tween:Play()

			local bobTween = crateJanitor:Add(
				TweenService:Create(
					gunPrimary :: BasePart,
					TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true, 0),
					{
						Position = gunPrimary.Position + Vector3.new(0, 0.3, 0),
					}
				),
				"Destroy"
			)
			bobTween:Play()

			ShopController.CrateOpened:Fire(CrateType, GunId, function()
				crateJanitor:Destroy()
				InterfaceController.HideHUD:Fire(false)
				-- shakeCrate:Disconnect()
			end)
		end) --]]
	end)

	track:Play()

	return Promise.fromEvent(track.Stopped, function()
		return true
	end):andThen(function()
		return Promise.delay(2)
	end)
end

return ShopController
