--!strict

-- Combat Controller
-- November 21st, 2022
-- Ron

-- // Variables \\

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Input = require(Packages.Input)
local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local PreferredInput = Input.PreferredInput

local DoubleTapThresholdMillis = 200

type TouchInputButtonData = {
	Image: string,
	Size: UDim2,
	Position: UDim2,
	Order: number,
}
local SWIPE_DIRECTIONS = { Enum.SwipeDirection.Left, Enum.SwipeDirection.Right, Enum.SwipeDirection.Up, Enum.SwipeDirection.Down }
local TOUCH_INPUT_BUTTONS = {
	Run = {
		Image = "rbxassetid://14933991418",
		Position = UDim2.fromScale(0.38, 0.7),
		Size = UDim2.fromScale(0.18, 0.18),
		Order = 1,
	},
	["Heavy Attack"] = {
		Image = "rbxassetid://14933989201",
		Position = UDim2.fromScale(0.63, 0.26),
		Size = UDim2.fromScale(0.18, 0.18),
		Order = 2,
	},
	--[[["Light Attack"] = {
		Image = "rbxassetid://14933990360",
		Position = UDim2.fromScale(0.65, 0.29),
		Size = UDim2.fromScale(0.18, 0.18),
	},--]]
	Block = {
		Image = "rbxassetid://14933987739",
		Position = UDim2.fromScale(0.3, 0.5),
		Size = UDim2.fromScale(0.18, 0.18),
		Order = 3,
	},
	Dodge = {
		Image = "rbxassetid://13132533500",
		Position = UDim2.fromScale(0.4, 0.3),
		Size = UDim2.fromScale(0.18, 0.18),
		Order = 4,
	},
	ShiftLock = {
		Order = 5,
	},
} :: { [string]: TouchInputButtonData }
local CONTEXT_GUI = Instance.new("ScreenGui")
CONTEXT_GUI.Name = "ContextGui"
CONTEXT_GUI.Parent = PlayerGui
CONTEXT_GUI.ResetOnSpawn = false

local KeybindInputController = {
	Name = "KeybindInputController",
	Bound = {},
}

local Enabled = true
local touchShiftLockJanitor = Janitor.new()

function KeybindInputController:Init()
	LocalPlayer.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

	local touchShiftLockEnabled = false

	PreferredInput.Observe(function(NewPreferredInput)
		if NewPreferredInput == "Touch" then
			-- the chat window for mobile has size 0.25, 0.2 in scale and we want to position it on the top left of the screen instead of the bottom right.
			StarterGui:SetCore("ChatWindowPosition", UDim2.fromScale(0, 0))

			ContextActionService:UnbindAction("ShiftLOCK")
			ContextActionService:BindAction("ShiftLOCK", function(_ActionName, InputState)
				if InputState ~= Enum.UserInputState.Begin then
					return
				end

				touchShiftLockJanitor:Cleanup()
				touchShiftLockEnabled = not touchShiftLockEnabled;
				(KeybindInputController :: any):ToggleTouchShiftLock(touchShiftLockEnabled)
			end, true)

			local button = ContextActionService:GetButton("ShiftLOCK")
			if button then
				local position, size = self:GetMobileButtonPositionAndSize("ShiftLock")
				ContextActionService:SetPosition("ShiftLOCK", position)
				ContextActionService:SetImage("ShiftLOCK", "rbxasset://textures/ui/mouseLock_off@2x.png")
				button.Parent = CONTEXT_GUI
				button.AnchorPoint = Vector2.new(0.5, 1)
				button.Size = size
				KeybindInputController:ApplyBackgroundFrame(button)
			end
		else
			ContextActionService:UnbindAction("ShiftLOCK")
			touchShiftLockJanitor:Cleanup()
		end
	end)
end

function KeybindInputController:ApplyBackgroundFrame(Button: ImageButton)
	Button.Image = "http://www.roblox.com/asset/?id=8886028282"
	Button.ImageColor3 = Color3.fromRGB(200, 200, 200)

	Button:GetPropertyChangedSignal("Image"):Connect(function()
		Button.Image = "http://www.roblox.com/asset/?id=8886028282"
	end)

	--[[local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	frame.Size = UDim2.fromScale(1, 1)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 0, 0)

	local actionIcon = Button:FindFirstChildOfClass("ImageLabel")
	if actionIcon then
		actionIcon.ZIndex = 2
	end

	frame.Parent = Button
	corner.Parent = frame
	stroke.Parent = frame--]]
end

function KeybindInputController:GetMobileButtonPositionAndSize(ButtonName: string): (UDim2, UDim2)
	local TouchGui = PlayerGui:WaitForChild("TouchGui")
	local TouchControlFrame = TouchGui:WaitForChild("TouchControlFrame")
	local JumpButton = TouchControlFrame:WaitForChild("JumpButton")

	local buttonData = TOUCH_INPUT_BUTTONS[ButtonName]
	local order = buttonData.Order

	-- Get absolute size and position of button
	local absSizeX, absSizeY = JumpButton.AbsoluteSize.X, JumpButton.AbsoluteSize.Y
	local absPositionX, absPositionY = JumpButton.AbsolutePosition.X, JumpButton.AbsolutePosition.Y

	-- we want the button to be 80% of the size of the jump button.
	local size = UDim2.fromOffset(absSizeX * 0.56, absSizeY * 0.56)
	-- we want the buttons to form a circle around the jump button. we use the radius and angle to calculate the position.

	-- the angle is the order of the button * 2pi / the number of buttons. but the buttons can only take up around 60% of the circle, so we multiply by 0.6.
	local Angle = (order * 2 * math.pi / 5) * 0.52

	-- start the circle slightly to the right of the top of the jump button.

	Angle = Angle + math.pi / 2 + math.pi / 10

	-- make the circle spiral inwards very slightly.

	Angle = Angle + order * math.pi / 110

	-- the radius is the size of the jump button times 2
	local Radius = absSizeX

	-- add the radius of the button to the total radius.
	Radius = Radius + absSizeX * 0.1

	-- the position is the center of the jump button + the radius * the sin/cos of the angle.
	local position = UDim2.fromOffset(
		absPositionX + absSizeX / 2 + Radius * math.cos(Angle),
		absPositionY + absSizeY / 2 + Radius * math.sin(Angle)
	)

	return position, size
end

function KeybindInputController:ToggleTouchShiftLock(Toggle: boolean)
	local char = LocalPlayer.Character
	if Toggle then
		local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
		if char and char:FindFirstChildOfClass("Humanoid") then
			char:FindFirstChildOfClass("Humanoid").AutoRotate = false
		end
		ContextActionService:SetImage("ShiftLOCK", "rbxasset://textures/ui/mouseLock_on@2x.png")
		touchShiftLockJanitor:Add(
			RunService.RenderStepped:Connect(function()
				if not humanoidRootPart or humanoidRootPart:IsDescendantOf(workspace) == false then
					return
				end
				humanoidRootPart.CFrame = CFrame.new(
					humanoidRootPart.Position,
					Vector3.new(
						Camera.CFrame.LookVector.X * 900000,
						humanoidRootPart.Position.Y,
						Camera.CFrame.LookVector.Z * 900000
					)
				)
				Camera.CFrame = Camera.CFrame * CFrame.new(1.7, 0, 0)
			end),
			"Disconnect"
		)
	else
		Camera.CFrame = Camera.CFrame * CFrame.new(-1.7, 0, 0)
		ContextActionService:SetImage("ShiftLOCK", "rbxasset://textures/ui/mouseLock_off@2x.png")
		if char and char:FindFirstChildOfClass("Humanoid") then
			char:FindFirstChildOfClass("Humanoid").AutoRotate = true
		end
	end
end

function KeybindInputController:Bind(
	Name: string,
	Binds: { Enum.KeyCode | Enum.UserInputType },
	ActionHandler: (ActionName: string, InputState: Enum.UserInputState, InputObject: any) -> nil
)
	ContextActionService:UnbindAction(Name)
	self.Bound[Name] = { Timestamp = DoubleTapThresholdMillis * 3, EndedSignal = nil }
	local BoundData = self.Bound[Name]
	ContextActionService:BindActionAtPriority(Name, function(ActionName, InputState, InputObject)
		if not Enabled then
			return Enum.ContextActionResult.Pass
		end
		BoundData.Timestamp = DateTime.now().UnixTimestampMillis
		task.defer(ActionHandler, ActionName, InputState, InputObject)

		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, unpack(Binds))
end

function KeybindInputController:BindAction(
	ActionInputData: Types.ActionSettingsData,
	Binds: { Enum.KeyCode | Enum.UserInputType | Enum.SwipeDirection },
	ActionHandler: (
		ActionName: string,
		InputState: Enum.UserInputState,
		InputObject: any
	) -> nil
)
	local ActionReadableName = ActionInputData.Name

	-- Unbind the previous action if there was one.
	self:UnbindAction(ActionInputData)

	self.Bound[ActionReadableName] = {
		Timestamp = DoubleTapThresholdMillis * 3,
		EndedSignal = ActionInputData.Held and Signal.new() or nil,
		BoundJanitor = Janitor.new(),
	}
	local BoundData = self.Bound[ActionReadableName]

	-- The only actions requiring touch input are run, block, heavy attack, light attack.
	local touchButtonData = TOUCH_INPUT_BUTTONS[ActionReadableName]

	local hasTouchInputBind = table.find(Binds, Enum.UserInputType.Touch) ~= nil
	if hasTouchInputBind then
		-- For touch input, we want to bind the action to UserInputService.TouchTapInWorld.
		-- This is because we want to be able to tap on the screen to move, but not do an action while using the joystick.
		self.Bound[ActionReadableName].BoundJanitor:Add(
			UserInputService.TouchTapInWorld:Connect(function(Position, Processed)
				if not Enabled or Processed then
					return
				end
				BoundData.Timestamp = DateTime.now().UnixTimestampMillis
				task.defer(ActionHandler, ActionInputData.Name, Enum.UserInputState.Begin, {
					UserInputType = Enum.UserInputType.Touch,
					Position = Position,
				})
			end),
			"Disconnect"
		)
		table.remove(Binds, table.find(Binds, Enum.UserInputType.Touch)) -- Don't apply touch input to ContextActionService.
	end

	local hasSwipeDirectionBind = false
	for _, SwipeDirection in SWIPE_DIRECTIONS do
		if table.find(Binds, SwipeDirection) ~= nil then
			hasSwipeDirectionBind = true
			break
		end
	end

	if hasSwipeDirectionBind then
		self.Bound[ActionReadableName].BoundJanitor:Add(
			UserInputService.TouchSwipe:Connect(function(Direction, NumberOfTouches, Processed)
				if not Enabled or Processed then
					return
				end
				BoundData.Timestamp = DateTime.now().UnixTimestampMillis
				task.defer(ActionHandler, ActionInputData.Name, Enum.UserInputState.Begin, {
					UserInputType = Enum.UserInputType.Touch,
					SwipeDirection = Direction,
					NumberOfTouches = NumberOfTouches,
				})
			end),
			"Disconnect"
		)
		for _, SwipeDirection in SWIPE_DIRECTIONS do
			if table.find(Binds, SwipeDirection) ~= nil then
				table.remove(Binds, table.find(Binds, SwipeDirection)) -- Don't apply swipe input to ContextActionService.
			end
		end
	end

	ContextActionService:BindActionAtPriority(ActionReadableName, function(ActionName, InputState, InputObject)
		if not Enabled then
			return Enum.ContextActionResult.Pass
		end

		local Last = BoundData.Timestamp
		if InputState == Enum.UserInputState.End or InputState == Enum.UserInputState.Cancel then
			if BoundData.EndedSignal then
				local shouldFireEnded = typeof(ActionInputData.Held) == "table"
						and table.find(ActionInputData.Held, InputObject.KeyCode) ~= nil
					or ActionInputData.Held == true
					or false
				if shouldFireEnded then
					BoundData.EndedSignal:Fire()
				end
			end
			return Enum.ContextActionResult.Pass
		elseif
			InputState == Enum.UserInputState.Begin -- we only need the timestamp for valid double tap input. without this, you can press ctrl, then press w and it will count as a double tap. (e.g in the run action)
			and ActionInputData.DoubleTap
			and table.find(ActionInputData.DoubleTap, InputObject.KeyCode)
		then
			-- If we just started new input, this is when we want to set our last timestamp.
			BoundData.Timestamp = DateTime.now().UnixTimestampMillis
		elseif InputState == Enum.UserInputState.Change or InputState == Enum.UserInputState.None then
			-- If we're changing input, we don't want to do anything.
			return Enum.ContextActionResult.Pass
		end

		if
			ActionInputData.DoubleTap
			and table.find(ActionInputData.DoubleTap, InputObject.KeyCode)
			and ((BoundData.Timestamp - Last) > DoubleTapThresholdMillis)
			and KeybindInputController:GetPreferredInput() == "MouseKeyboard" -- we only want to double tap on mouse and keyboard, not CAS/touch buttons.
		then
			return Enum.ContextActionResult.Pass
		end

		task.defer(ActionHandler, ActionName, InputState, InputObject)

		return Enum.ContextActionResult.Pass
	end, touchButtonData ~= nil, Enum.ContextActionPriority.High.Value, unpack(Binds))

	if touchButtonData then
		local button = ContextActionService:GetButton(ActionReadableName)
		if button then
			local position, size = self:GetMobileButtonPositionAndSize(ActionReadableName)
			ContextActionService:SetImage(ActionReadableName, touchButtonData.Image)
			ContextActionService:SetPosition(ActionReadableName, position)
			button.Parent = CONTEXT_GUI
			button.AnchorPoint = Vector2.new(0.5, 1)
			button.Size = size
			KeybindInputController:ApplyBackgroundFrame(button)
		end
	end
end

function KeybindInputController:UnbindAction(ActionHandlerData: Types.ActionSettingsData)
	local ActionReadableName = ActionHandlerData.Name
	if not self.Bound[ActionHandlerData.Name] then
		return -- This action was never bound.
	end
	ContextActionService:UnbindAction(ActionReadableName)
	self.Bound[ActionReadableName].BoundJanitor:Destroy()
	self.Bound[ActionReadableName] = nil
end

function KeybindInputController:GetBindEndedSignal(ReadableName: string): RBXScriptSignal
	return self.Bound[ReadableName].EndedSignal
end

function KeybindInputController:GetPreferredInput()
	return PreferredInput.Current
end

function KeybindInputController:SetEnabled(isEnabled: boolean)
	Enabled = isEnabled
end

function KeybindInputController:IsEnabled()
	return Enabled
end

function KeybindInputController:IsKeyDown(Key: Enum.KeyCode): boolean
	return UserInputService:IsKeyDown(Key)
end

function KeybindInputController:IsShiftLocked(): boolean
	local mouseBehavior = UserInputService.MouseBehavior
	return mouseBehavior == Enum.MouseBehavior.LockCenter
end

function KeybindInputController:IsHoldingAny(Keys: { Enum.KeyCode }): boolean
	for _, Key in pairs(Keys) do
		if KeybindInputController:IsKeyDown(Key) then
			return true
		end
	end
	return false
end

return KeybindInputController
