--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage.react.components

local React = require(ReplicatedStorage.packages.React)
local Slideshow = require(Components.frames.Slideshow)
local Types = require(ReplicatedStorage.constants.Types)
local useProductInfoFromIds = require(ReplicatedStorage.react.hooks.useProductInfoFromIds)

local useRef = React.useRef
local e = React.createElement

type GamepassSlideshowProps = Types.FrameProps & {
	gamepasses: {
		{
			id: number, -- The ID of the gamepass
		}
	},
}

local function GamepassSlideshow(props: GamepassSlideshowProps)
	local gamepasses = useRef({}) :: { current: { [number]: Enum.InfoType } }
	for _, gamepass in props.gamepasses do
		gamepasses.current[gamepass.id] = Enum.InfoType.GamePass
	end

	local gamepassProductInfo = useProductInfoFromIds(gamepasses.current)

	local gamepassSlides = {}
	for _, gamepass in ipairs(props.gamepasses) do
		local productInfo = gamepassProductInfo[gamepass.id]
		if productInfo then
			table.insert(gamepassSlides, {
				key = gamepass.id,
				icon = string.format("rbxassetid://%d", productInfo.IconImageAssetId),
				slideName = productInfo.Name,
				price = productInfo.PriceInRobux,
				description = string.format("Buy %s for %d Robux", productInfo.Name, productInfo.PriceInRobux),
			})
		end
	end

	return e(Slideshow, {
		slides = gamepassSlides,
		position = props.position,
		size = props.size,
	})
end

return React.memo(GamepassSlideshow)
