--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)

local DistractionViewport = require(Components.round.DistractionViewport)

local e = React.createElement

local function App()
	return e("ScreenGui", {
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 1,
		-- selene: allow(roblox_incorrect_roact_usage)
		Name = "App",
	}, {
		distractionViewport = e(DistractionViewport),
	})
end

return App
