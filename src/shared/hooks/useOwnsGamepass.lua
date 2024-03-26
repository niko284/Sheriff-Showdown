-- Owns Gamepass Hook
-- August 26th, 2023
-- Nick

-- // Variables \\

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Packages = ReplicatedStorage.packages

local React = require(Packages.React)

local useState = React.useState
local useEffect = React.useEffect

-- // Hook \\

local function useOwnsGamepass(GamepassId: number): boolean
	local ownsGamepass, setOwnsGamepass = useState(false)

	local gamepassesGifted = useState({}) -- for the future, this can be a useResource hook to get the gamepasses gifted to the player

	useEffect(function()
		if gamepassesGifted and table.find(gamepassesGifted, GamepassId) then
			setOwnsGamepass(true)
		else
			local success, ownsPass = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, GamepassId)
			end)
			if success then
				setOwnsGamepass(ownsPass)
			end
		end

		local gamepassPurchaseConnection = MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player, gamepassId, wasPurchased)
				if player == LocalPlayer and gamepassId == GamepassId and wasPurchased then
					setOwnsGamepass(true)
				end
			end
		)

		return function()
			gamepassPurchaseConnection:Disconnect()
		end
	end, { gamepassesGifted, setOwnsGamepass, GamepassId } :: { any })

	return ownsGamepass
end

return useOwnsGamepass
