--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Utils = ReplicatedStorage.utils
local Hooks = ReplicatedStorage.react.hooks

local DependencyArray = require(Utils.DependencyArray)
local Janitor = require(Packages.Janitor)
local MathUtils = require(Utils.MathUtils)
local React = require(Packages.React)
local Sift = require(Packages.Sift)
local Types = require(Constants.Types)
local useHookWithRefCallback = require(Hooks.useHookWithRefCallback)

local e = React.createElement
local useRef = React.useRef
local useState = React.useState
local useBinding = React.useBinding
local useCallback = React.useCallback
local useEffect = React.useEffect

local MAX_ANGLE_STEP = math.rad(10)

type ViewportModelProps = {
	model: Model?,
	useDirectly: boolean,
	angle: Vector3?,
	distance: number?,
	worldModel: boolean,
	offset: Vector3?,
	spinSpeed: number?,
	scrollToZoom: boolean?,
	children: any,
	rotationMode: "CameraRotates" | "ModelRotates"?,
	draggable: boolean,
	pitchLimits: NumberRange?,
	onModelCreated: (Model) -> ()?,
	yawLimits: NumberRange?,
	listenForDescendants: boolean?,
}
local defaultProps = {
	useDirectly = false,
	angle = Vector3.new(0, 0, -1),
	distance = 1,
	offset = Vector3.new(0, 0, 0),
	rotationMode = "CameraRotates",
	spinSpeed = nil,
	worldModel = false,
	draggable = false,
	pitchLimits = NumberRange.new(math.rad(-60), math.rad(60)),
	yawLimits = nil,
	model = nil,
}

-- // Viewport Model \\

local function ViewportModel(props: Types.FrameProps & ViewportModelProps)
	props = Sift.Dictionary.merge(defaultProps, props)

	local dragging = useRef(false)
	local currentModel = useRef(nil :: Model?)
	local currentPitch = useRef(0)
	local currentYaw = useRef(0)
	local cameraCFrame, setCameraCFrame = useBinding(CFrame.new())
	local cameraRef, assignCameraRef = useHookWithRefCallback()
	local viewportRef, assignViewportRef = useHookWithRefCallback()
	local totalSpin = useRef(0)
	local lastMousePosition = useRef(nil :: Vector3?)
	local zoomFactor, setZoomFactor = useState(1)

	local getAngles = useCallback(function(model: Model)
		local angles = nil
		if props.rotationMode == "CameraRotates" and cameraRef.current then
			angles = cameraRef.current.CFrame
		elseif props.rotationMode == "ModelRotates" and model and model.PrimaryPart then
			angles = model.PrimaryPart.CFrame:Inverse()
		end
		return MathUtils.GetCFrameAngles(angles)
	end, DependencyArray(props.rotationMode, cameraRef) :: { any })

	local setAngles = useCallback(function(limitedCFrame: CFrame, model: Model)
		local angles = MathUtils.GetCFrameAngles(limitedCFrame)
		if props.rotationMode == "CameraRotates" and model then
			local minCamDistance = MathUtils.GetModelCornerDistance(model)
			local cameraDistance = minCamDistance
			local cameraCenter, _ = model:GetBoundingBox()
			setCameraCFrame((cameraCenter * angles) * CFrame.new(0, 0, cameraDistance))
		elseif props.rotationMode == "ModelRotates" and model then
			model:PivotTo(CFrame.new() * angles:Inverse())
		end
	end, DependencyArray(setCameraCFrame))

	local rotate = React.None
	rotate = useCallback(
		function(dPitch: number, dYaw: number, model: Model)
			while math.abs(dPitch) > MAX_ANGLE_STEP do
				rotate(MAX_ANGLE_STEP * math.sign(dPitch), 0)
				dPitch -= MAX_ANGLE_STEP * math.sign(dPitch)
			end
			while math.abs(dYaw) > MAX_ANGLE_STEP do
				rotate(0, MAX_ANGLE_STEP * math.sign(dYaw))
				dYaw -= MAX_ANGLE_STEP * math.sign(dYaw)
			end
			local rotatedCFrame = MathUtils.RotateCFrameCameraBehavior(getAngles(model), dPitch, dYaw)

			local fixedPitchLimits = nil
			if props.pitchLimits then
				fixedPitchLimits = props.rotationMode == "CameraRotates" and props.pitchLimits
					or NumberRange.new(-props.pitchLimits.Max, -props.pitchLimits.Min)
			end

			local fixedYawLimits = nil
			if props.yawLimits then
				fixedYawLimits = props.rotationMode == "CameraRotates" and props.yawLimits
					or NumberRange.new(-props.yawLimits.Max, -props.yawLimits.Min)
			end

			-- Limit
			local limitedCFrame = nil
			if props.rotationMode == "CameraRotates" then
				limitedCFrame = MathUtils.ConstrainAngles(rotatedCFrame, fixedPitchLimits, fixedYawLimits)
			else
				limitedCFrame = MathUtils.ConstrainAngles(
					rotatedCFrame * CFrame.Angles(0, math.pi, 0),
					fixedPitchLimits,
					fixedYawLimits
				) * CFrame.Angles(0, math.pi, 0)
			end
			currentPitch.current = dPitch
			currentYaw.current = dYaw
			setAngles(limitedCFrame, model)
		end,
		DependencyArray(
			props.rotationMode,
			props.pitchLimits,
			props.yawLimits,
			rotate,
			setAngles,
			getAngles,
			currentPitch,
			currentYaw
		) :: { any }
	)

	local onDrag = useCallback(function(inputObject: InputObject, model: Model)
		local delta = (lastMousePosition.current or inputObject.Position) - inputObject.Position
		lastMousePosition.current = inputObject.Position
		if props.rotationMode == "ModelRotates" then
			delta = (delta :: any) * Vector2.new(1, -1)
		end
		local dPitch = -delta.Y / 100
		local dYaw = -delta.X / 100
		rotate(dPitch, dYaw, model)
	end, DependencyArray(lastMousePosition, props.rotationMode, rotate) :: { any })

	local getViewportModel = useCallback(function()
		local model = nil
		if props.model and props.useDirectly == false then
			-- If our model is not archivable, we need to make it archivable.
			if props.model.Archivable == false then
				props.model.Archivable = true
			end
			local cloneModel = props.model:Clone()

			props.model.Archivable = false
			model = cloneModel
		elseif props.model and props.useDirectly == true then
			model = props.model
		else
			return nil :: Model?
		end
		return model
	end, { props.model, props.useDirectly } :: { any })

	useEffect(
		function()
			local effectCleaner = Janitor.new()

			local function setUpViewport(): Janitor.Janitor
				local cleaner = Janitor.new()
				local model = getViewportModel()
				if model then
					cleaner:Add(model, "Destroy")
					currentModel.current = model
					local camera = cameraRef.current :: Camera?
					if not camera then
						return cleaner
					else
						local viewport = viewportRef.current :: ViewportFrame?
						if not viewport or not model.PrimaryPart then
							return cleaner
						else
							model:PivotTo(CFrame.new())
							rotate(currentPitch.current, currentYaw.current, model)

							-- inside setAngles, we multiply the cameraCenter by the angles.
							-- we need to pass in a cframe so that the camera is in front of the lookVector facing the model

							setAngles(CFrame.lookAt(model:GetPivot().Position, -model:GetPivot().LookVector), model)
							-- Clear old models

							for _, modelDescendant in viewport:GetDescendants() do
								if modelDescendant:IsA("Model") then
									if modelDescendant:IsA("WorldModel") then
										continue
									end
									modelDescendant:Destroy()
								end
							end

							if props.worldModel and viewport then
								model.Parent = viewport:WaitForChild("worldModel")
							else
								model.Parent = viewport
							end

							if props.onModelCreated then
								props.onModelCreated(model)
							end

							if props.spinSpeed and model and model.PrimaryPart and totalSpin.current then
								local base = model.PrimaryPart.CFrame
								model:PivotTo(base :: any * CFrame.Angles(0, totalSpin.current * props.spinSpeed, 0))
								local spinHeartbeat = nil
								spinHeartbeat = cleaner:Add(
									RunService.Heartbeat:Connect(function(deltaTime: number)
										if (model.PrimaryPart :: any) == nil then
											warn("Model has no primary part")
											spinHeartbeat:Disconnect()
											return
										end
										totalSpin.current += deltaTime
										model:PivotTo(
											base :: any * CFrame.Angles(0, totalSpin.current * props.spinSpeed, 0)
										)
									end),
									"Disconnect"
								)
							end
						end
						if props.draggable then
							cleaner:Add(
								UserInputService.InputChanged:Connect(function(InputObject: InputObject)
									if
										dragging.current == true
										and InputObject.UserInputState ~= Enum.UserInputState.End
									then
										onDrag(InputObject, model :: any)
									elseif InputObject.UserInputState == Enum.UserInputState.End then
										dragging.current = false
									end
								end),
								"Disconnect"
							)
							cleaner:Add(
								UserInputService.InputEnded:Connect(function(InputObject: InputObject)
									if
										InputObject.UserInputType == Enum.UserInputType.MouseButton1
										or InputObject.UserInputType == Enum.UserInputType.Touch
											and dragging.current == true
									then
										dragging.current = false
									end
								end),
								"Disconnect"
							)
						end
					end
				end
				return cleaner
			end

			local latestCleaner = setUpViewport() :: Janitor.Janitor?

			if props.listenForDescendants and props.model then
				effectCleaner:Add(
					props.model.ChildAdded:Connect(function(child: Instance)
						if child:IsA("Accessory") then
							child:WaitForChild("Handle") -- @IMPORTANT: Wait for the handle to load
							task.wait()
							if latestCleaner and Janitor.Is(latestCleaner) then
								latestCleaner:Destroy()
								latestCleaner = nil
							end
							latestCleaner = setUpViewport()
						end
					end),
					"Disconnect"
				)
				effectCleaner:Add(
					props.model.ChildRemoved:Connect(function(child: Instance)
						if child:IsA("Accessory") then
							if latestCleaner then
								latestCleaner:Destroy()
								latestCleaner = nil
							end
							task.wait()
							latestCleaner = setUpViewport()
						end
					end),
					"Disconnect"
				)
			end

			return function()
				effectCleaner:Destroy()
				if latestCleaner then
					latestCleaner:Destroy()
				end
				currentModel.current = nil
			end
		end :: () -> (),
		DependencyArray(
			rotate,
			props.worldModel,
			props.spinSpeed,
			totalSpin,
			props.model,
			currentModel,
			props.draggable,
			props.useDirectly,
			props.listenForDescendants,
			props.onModelCreated,
			getViewportModel,
			onDrag,
			dragging,
			currentPitch,
			currentYaw,
			cameraRef,
			viewportRef,
			setAngles
		)
	)

	return e("ViewportFrame", {
		Active = props.draggable,
		ref = assignViewportRef,
		[React.Event.InputBegan] = function(_rbx: ViewportFrame, input: InputObject)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch and currentModel.current
			then
				lastMousePosition.current = nil -- Prevent a jump when the user starts dragging, so we set our delta to 0
				dragging.current = true
				onDrag(input, currentModel.current)
			end
		end,
		[React.Event.InputChanged] = function(_rbx: ViewportFrame, input: InputObject)
			if props.scrollToZoom and input.UserInputType == Enum.UserInputType.MouseWheel and currentModel.current then
				if input.Position.Z == 0 then
					return
				end
				setZoomFactor(zoomFactor - math.sign(input.Position.Z) * 0.5)
			end
		end,
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = props.backgroundTransparency,
		BackgroundColor3 = props.backgroundColor3,
		Size = props.size,
		Position = props.position,
		CurrentCamera = cameraRef.current,
		ZIndex = props.zIndex,
	}, {
		viewportCamera = e("Camera", {
			CFrame = cameraCFrame:map(function(cframe: CFrame)
				return cframe * CFrame.new(0, 0, zoomFactor)
			end),
			ref = assignCameraRef,
		}),
		worldModel = props.worldModel and e("WorldModel"),
		children = React.createElement(React.Fragment, nil, props.children),
	})
end

return ViewportModel
