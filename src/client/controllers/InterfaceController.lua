--!strict

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local jecs = require("@packages/jecs")
local React = require("@packages/React")
local ReactRoblox = require("@packages/ReactRoblox")
local Signal = require("@packages/Signal")
local Types = require("@constants/Types")

local e = React.createElement
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local InterfaceController = {
	Name = "InterfaceController",
	InterfaceChanged = Signal.new() :: Signal.Signal<Types.Interface?>,
	UpdateShopState = Signal.new(),
	ViewCrateContents = Signal.new() :: Signal.Signal<Types.Crate>,
	WorldCreated = Signal.new() :: Signal.Signal<jecs.World>,
	HideHUD = Signal.new() :: Signal.Signal<boolean>,
	World = nil :: jecs.World?,
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
	self.App = require("@ui/components/App") :: any
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
