--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local InputLib = require(ReplicatedStorage.packages.Input)
local React = require(ReplicatedStorage.packages.React)
local Settings = require(ReplicatedStorage.constants.Settings)
local Types = require(ReplicatedStorage.constants.Types)

local PreferredInput = InputLib.PreferredInput

local e = React.createElement
local useEffect = React.useEffect

type KeybindTemplateProps = Types.FrameProps & {
	listeningForInput: boolean,
	keybindMap: Types.KeybindMap,
	setListeningForInput: (newValue: string?) -> (),
	changeSetting: (settingName: string, settingValue: Types.SettingValue) -> (),
	description: string,
	name: string,
}

local validInputTypes = {
	Enum.UserInputType.Keyboard,
	Enum.UserInputType.Gamepad1,
}

local function KeybindTemplate(props: KeybindTemplateProps)
	useEffect(function()
		local inputBegan = UserInputService.InputBegan:Connect(function(Input, Processed)
			if props.listeningForInput and not Processed and table.find(validInputTypes, Input.UserInputType) then
				local inputType = PreferredInput.Current :: any
				local newKeybindMap = table.clone(props.keybindMap)

				for device: Types.DeviceType, keybind in newKeybindMap do
					if keybind == Input.KeyCode.Name then
						newKeybindMap[device] = "None" -- avoid duplicate keybinds
					end
				end

				newKeybindMap[inputType] = Input.KeyCode.Name

				props.changeSetting(props.name, newKeybindMap)
				props.setListeningForInput(nil)
			end
		end)
		return function()
			inputBegan:Disconnect()
		end
	end, { props.listeningForInput, props.keybindMap, props.name, props.changeSetting } :: { any })

	local settingInfo = Settings[props.name]
	local defaultKeybinds = settingInfo.Default :: Types.KeybindMap -- we might need to display the default keybind for the current device if the user has not set a keybidn for it.

	local currentKeybind = props.keybindMap[PreferredInput.Current :: Types.DeviceType]
		or defaultKeybinds[PreferredInput.Current :: Types.DeviceType]

	return e("Frame", {
		BackgroundColor3 = Color3.fromRGB(72, 72, 72),
		BackgroundTransparency = 0.64,
		LayoutOrder = props.layoutOrder,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = props.size,
	}, {
		corner = e("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),

		stroke = e("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 1,
			Transparency = 0.67,
		}),

		description = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Medium,
				Enum.FontStyle.Normal
			),
			Text = props.description,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 12,
			TextTransparency = 0.38,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 42),
			Size = UDim2.fromOffset(200, 11),
		}),

		name = e("TextLabel", {
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Bold,
				Enum.FontStyle.Normal
			),
			Text = props.name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 19),
			Size = UDim2.fromOffset(115, 16),
		}),

		inputBox = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.89,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.907, 0.507),
			Size = UDim2.fromOffset(122, 36),
		}, {
			corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),

			stroke = e("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 1.4,
				Transparency = 0.69,
			}),

			inputRequestButton = e("TextButton", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = ((not props.listeningForInput and currentKeybind) or "Press a key") :: string,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				TextScaled = true,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.86, 0.6),
				[React.Event.Activated] = function()
					-- if we're not listening for input, set it to the setting name, otherwise we pressed the button to stop listening for input
					props.setListeningForInput(not props.listeningForInput and props.name or nil)
				end,
			}),
		}),
	})
end

return React.memo(KeybindTemplate)
