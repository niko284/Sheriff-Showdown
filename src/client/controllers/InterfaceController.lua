--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.react.components

local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Signal = require(Packages.Signal)
local Types = require(ReplicatedStorage.constants.Types)

local e = React.createElement
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local InterfaceController = {
	Name = "InterfaceController",
	InterfaceChanged = Signal.new() :: Signal.Signal<Types.Interface?>,
	UpdateShopState = Signal.new(),
	ViewCrateContents = Signal.new() :: Signal.Signal<Types.Crate>,
}

-- // Functions \\

function InterfaceController:OnInit()
	-- Disable appropriate core guis.
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end

function InterfaceController:OnStart()
	self.Root = ReactRoblox.createRoot(Instance.new("Folder"))
	self.App = require(Components.App) :: any
	self.GameApp = e(self.App)
	self.Root:render(ReactRoblox.createPortal({ self.GameApp }, PlayerGui))
end

function InterfaceController:GetCurrentInterface(): string?
	return self.Store:getState().CurrentInterface
end

function InterfaceController:GetScaleRatio()
	return self.ScaleRatio
end

return InterfaceController
