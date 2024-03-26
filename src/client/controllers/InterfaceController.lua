-- Interface Controller
-- Nick
-- January 21st, 2024

-- // Variables \\

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages
local Components = ReplicatedStorage.components
local PlayerScripts = LocalPlayer.PlayerScripts
local Rodux = PlayerScripts.rodux

local Promise = require(Packages.Promise)
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local ReactRodux = require(Packages.ReactRodux)
local Signal = require(Packages.Signal)

local e = React.createElement
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- // Controller Variables \\

local InterfaceController = {
	Name = "InterfaceController",
	ScaleRatioChanged = Signal.new(),
	ScaleRatio = 1,
	AppLoaded = Signal.new(),
	InterfaceChanged = Signal.new(),
	IsAppLoaded = false,
}

-- // Functions \\

function InterfaceController:Init()
	self.Store = require(Rodux.Store)
	-- Disable appropriate core guis.
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	InterfaceController.AppLoaded:Connect(function()
		self.IsAppLoaded = true
	end)
end

function InterfaceController:WaitForAppLoaded()
	if self.IsAppLoaded then
		return Promise.resolve()
	end
	return Promise.fromEvent(InterfaceController.AppLoaded, function()
		return true
	end)
end

function InterfaceController:Start()
	self.Root = ReactRoblox.createRoot(Instance.new("Folder"))
	self.App = require(Components.App.App) :: any
	self.GameApp = e(ReactRodux.Provider, {
		store = self.Store,
	}, {
		game = e(self.App),
	})
	self.Root:render(ReactRoblox.createPortal({ self.GameApp }, PlayerGui))
end

function InterfaceController:GetCurrentInterface(): string?
	return self.Store:getState().CurrentInterface
end

function InterfaceController:GetScaleRatio()
	return self.ScaleRatio
end

return InterfaceController
