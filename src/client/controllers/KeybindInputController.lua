--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Packages = ReplicatedStorage.packages

local Components = require(ReplicatedStorage.ecs.components)
local Input = require(Packages.Input)
local Janitor = require(Packages.Janitor)
local Matter = require(Packages.Matter)
local TopbarPlus = require(Packages.TopbarPlus)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerMouse = LocalPlayer:GetMouse()

local Assets = ReplicatedStorage:FindFirstChild("assets") :: Folder
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Other = Assets:FindFirstChild("other") :: Folder
local ShiftLockUI = Other:FindFirstChild("shiftLock") :: ScreenGui

local KeybindInputController = {
	Name = "KeybindInputController",
	CameraJanitor = Janitor.new(),
	TopbarJanitor = Janitor.new(),
	World = nil :: Matter.World, -- gets injected
	ShiftLockUI = nil :: ScreenGui?,
	MobileShiftLockEnabled = false,
}

function KeybindInputController:OnStart()
	LocalPlayer.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

	Input.PreferredInput.Observe(function(inputType)
		if inputType == "Touch" then
			KeybindInputController:CreateMobileTopbar()
		else
			KeybindInputController.TopbarJanitor:Cleanup()
		end
	end)

	local shiftLockUIClone = ShiftLockUI:Clone()
	shiftLockUIClone.Parent = PlayerGui

	KeybindInputController.ShiftLockUI = shiftLockUIClone
end

function KeybindInputController:CreateMobileTopbar(): ()
	local shiftlockIcon = TopbarPlus.new()

	shiftlockIcon:setImage("rbxasset://textures/MouseLockedCursor.png"):setOrder(1)

	shiftlockIcon.toggled:Connect(function(selected: boolean)
		KeybindInputController:SetMobileShiftLock(selected)
	end)

	KeybindInputController.TopbarJanitor:Add(function()
		shiftlockIcon:destroy()
	end)
end

function KeybindInputController:SetMouseIcon(Icon: string)
	PlayerMouse.Icon = Icon
end

function KeybindInputController:IsMobileShiftLockEnabled()
	return KeybindInputController.MobileShiftLockEnabled
end

function KeybindInputController:SetMobileShiftLock(Enabled: boolean)
	local cameraJan = KeybindInputController.CameraJanitor
	cameraJan:Cleanup()
	local char = LocalPlayer.Character

	KeybindInputController.MobileShiftLockEnabled = Enabled

	if KeybindInputController.ShiftLockUI then
		KeybindInputController.ShiftLockUI.Enabled = Enabled
	end

	if not char then
		return
	end

	local isRagdolled = false
	local clientEntityId = char:GetAttribute("clientEntityId")

	if clientEntityId and KeybindInputController.World:get(clientEntityId, Components.Ragdolled) then
		isRagdolled = true
	end

	if not Enabled then
		Camera.CFrame = Camera.CFrame * CFrame.new(-1.7, 0, 0)
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if char and humanoid then
			humanoid.AutoRotate = true
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
		end
		return Enabled
	end

	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return false
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
		humanoid.CameraOffset = Vector3.new(0.5, 0, 0)
	end

	local rootAttachment = humanoidRootPart:FindFirstChild("RootAttachment") :: Attachment?
	if not rootAttachment then
		return
	end

	local alignOrientation: AlignOrientation = cameraJan:Add(Instance.new("AlignOrientation"))
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = rootAttachment
	-- alignOrientation.RigidityEnabled = true
	alignOrientation.Responsiveness = 1e99
	alignOrientation.MaxAngularVelocity = 1e99
	alignOrientation.MaxTorque = 1e99
	alignOrientation.ReactionTorqueEnabled = true
	alignOrientation.Parent = rootAttachment

	cameraJan:Add(
		RunService.RenderStepped:Connect(function()
			if not humanoidRootPart or humanoidRootPart:IsDescendantOf(workspace) == false then
				return
			end

			alignOrientation.Enabled = if isRagdolled then false else true

			if not isRagdolled then
				alignOrientation.CFrame = CFrame.new(
					humanoidRootPart.Position,
					Vector3.new(
						Camera.CFrame.LookVector.X * 900000,
						humanoidRootPart.Position.Y,
						Camera.CFrame.LookVector.Z * 900000
					)
				)
			end
			Camera.CFrame = Camera.CFrame * CFrame.new(1.7, 0, 0)
		end),
		"Disconnect"
	)

	return Enabled
end

return KeybindInputController
