--!strict

local AutomaticScrollingFrame = require("@ui/components/frames/AutomaticScrollingFrame")
local CategoryTemplate = require("@ui/components/settings/CategoryTemplate")
local CloseButton = require("@ui/components/buttons/CloseButton")
local DropdownTemplate = require("@ui/components/settings/DropdownTemplate")
local Freeze = require("@packages/Freeze")
local InputTemplate = require("@ui/components/settings/InputTemplate")
local InterfaceController = require("@controllers/InterfaceController")
local KeybindTemplate = require("@ui/components/settings/KeybindTemplate")
local Net = require("@packages/Net")
local React = require("@packages/React")
local Remotes = require("@network/Remotes")
local SettingsContext = require("@ui/contexts/SettingsContext")
local SettingsController = require("@controllers/SettingsController")
local SettingsInfo = require("@constants/Settings")
local SliderTemplate = require("@ui/components/settings/SliderTemplate")
local ToggleTemplate = require("@ui/components/settings/ToggleTemplate")
local Types = require("@constants/Types")
local animateCurrentInterface = require("@ui/hooks/animateCurrentInterface")
local createNextOrder = require("@ui/hooks/createNextOrder")

local SettingsNamespace = Remotes.Client:GetNamespace("Settings")
local ChangeSetting = SettingsNamespace:Get("ChangeSetting") :: Net.ClientAsyncCaller

local e = React.createElement
local useContext = React.useContext
local useState = React.useState
local useCallback = React.useCallback

local SETTING_TO_ELEMENT = {
	Input = InputTemplate,
	Slider = SliderTemplate,
	Toggle = ToggleTemplate,
	Keybind = KeybindTemplate,
	Dropdown = DropdownTemplate,
} :: { [Types.SettingType]: React.React_Component<any, any> }

type SettingsProps = {}

local function Settings(_props: SettingsProps)
	local settingsState = useContext(SettingsContext)
	local nextOrder = createNextOrder()

	local listeningForKeybind, setListeningForKeybind = useState(nil)

	local _shouldRender, styles =
		animateCurrentInterface("Settings", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.5, 2))

	local changeSetting = useCallback(function(settingName: string, settingValue: Types.SettingValue)
		local oldSettingsState = settingsState
		local newSettingsState = table.clone(settingsState)
		local newSetting = newSettingsState[settingName] and table.clone(newSettingsState[settingName])
			or {} :: Types.SettingInternal
		newSetting.Value = settingValue
		newSettingsState[settingName] = newSetting

		SettingsController.SettingsChanged:Fire(newSettingsState, oldSettingsState)
		ChangeSetting:CallServerAsync(settingName, settingValue)
			:andThen(function(response: Types.NetworkResponse)
				if response.Success == false then
					warn(response.Message)
					SettingsController.SettingsChanged:Fire(oldSettingsState, newSettingsState)
				end
			end)
			:catch(function(err)
				warn("Failed to change setting", tostring(err))
				SettingsController.SettingsChanged:Fire(oldSettingsState, newSettingsState)
			end)
	end, { settingsState })

	local settings = SettingsController:FillInSettings(settingsState)

	local elements = {} :: { [string]: any }
	for _, category in SettingsController.Categories do
		elements[category.Name] = e(CategoryTemplate, {
			name = category.Name,
			description = category.Description,
			layoutOrder = nextOrder(),
		})
		for settingName, settingInternal in settings do
			local settingInfo = SettingsInfo[settingName]
			if settingInfo.Category == category.Name then
				local element = SETTING_TO_ELEMENT[settingInfo.Type]
				if not element then
					continue
				end
				elements[settingName] = e(
					element,
					Freeze.Dictionary.merge(SettingsController:BuildSettingProps(settingName, settingInternal), {
						name = settingName,
						key = settingName,
						description = settingInfo.Description,
						size = UDim2.fromOffset(799, 71),
						layoutOrder = nextOrder(),
						changeSetting = changeSetting,

						-- for KeybindTemplate
						onToggle = settingInfo.Type == "Keybind" and setListeningForKeybind,
						listeningForInput = listeningForKeybind == settingName,
						setListeningForInput = setListeningForKeybind,
					})
				)
			end
		end
	end

	return e("ImageLabel", {
		Image = "rbxassetid://18199906444",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = styles.position,
		Size = UDim2.fromOffset(846, 606),
	}, {
		topbar = e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(846, 84),
		}, {
			background = e("ImageLabel", {
				Image = "rbxassetid://18199923487",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(846, 84),
			}),

			gridPattern = e("ImageLabel", {
				Image = "rbxassetid://18199923599",
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(846, 84),
			}),

			title = e("TextLabel", {
				FontFace = Font.new(
					"rbxasset://fonts/families/GothamSSm.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Text = "Settings",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(62, 33),
				ZIndex = 2,
				Size = UDim2.fromOffset(96, 21),
			}),

			close = e(CloseButton, {
				position = UDim2.fromScale(0.947, 0.512),
				size = UDim2.fromOffset(43, 43),
				zIndex = 2,
				onActivated = function()
					InterfaceController.InterfaceChanged:Fire(nil)
				end,
			}),

			settingsIcon2 = e("ImageLabel", {
				Image = "rbxassetid://18199923885",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(29, 37),
				ZIndex = 2,
				Size = UDim2.fromOffset(10, 10),
			}),

			settingsIcon = e("ImageLabel", {
				ZIndex = 2,
				Image = "rbxassetid://18199923977",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(22, 30),
				Size = UDim2.fromOffset(24, 24),
			}),
		}),

		scrollingFrame = e(AutomaticScrollingFrame, {
			scrollBarThickness = 9,
			active = true,
			backgroundTransparency = 1,
			borderSizePixel = 0,
			position = UDim2.fromScale(0.014, 0.153),
			size = UDim2.fromOffset(828, 500),
		}, {
			listLayout = e("UIListLayout", {
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 7),
				PaddingTop = UDim.new(0, 5),
			}),

			elementList = e(React.Fragment, nil, elements),
		}),
	})
end

return Settings
