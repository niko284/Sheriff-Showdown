--!strict

-- Combat Controller
-- November 21st, 2022
-- Ron

-- // Variables \\

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local PlayerMouse = LocalPlayer:GetMouse()

local KeybindInputController = {
	Name = "KeybindInputController",
}

function KeybindInputController:OnStart()
	LocalPlayer.PlayerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor
end

function KeybindInputController:SetMouseIcon(Icon: string)
	PlayerMouse.Icon = Icon
end

return KeybindInputController
