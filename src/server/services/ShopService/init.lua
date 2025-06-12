--!strict

local Players = game:GetService("Players")

local Codes = require("@self/Codes")
local Crates = require("@constants/Crates")
local Currencies = require("@constants/Currencies")
local Freeze = require("@packages/Freeze")
local Gamepasses = require("@constants/Gamepasses")
local InventoryService = require("@services/InventoryService")
local ItemService = require("@services/ItemService")
local ItemUtils = require("@utilities/ItemUtils")
local Net = require("@packages/Net")
local PlayerDataService = require("@services/PlayerDataService")
local Promise = require("@packages/Promise")
local Remotes = require("@network/Remotes")
local ResourceService = require("@services/ResourceService")
local TransactionService = require("@services/TransactionService")
local Types = require("@constants/Types")

local ShopNamespace = Remotes.Server:GetNamespace("Shop")
local SubmitCode = ShopNamespace:Get("SubmitCode") :: Net.ServerAsyncCallback
local PurchaseCrate = ShopNamespace:Get("PurchaseCrate") :: Net.ServerAsyncCallback
local SetGiftPlayer = ShopNamespace:Get("SetGiftPlayer") :: Net.ServerListenerEvent
local GetGiftedGamepasses = ShopNamespace:Get("GetGiftedGamepasses") :: Net.ServerAsyncCallback

local ShopService = { Name = "ShopService", GiftPlayerMap = {} }

function ShopService:OnInit()
	SubmitCode:SetCallback(function(Player: Player, Code: string)
		return ShopService:SubmitCodeNetworkRequest(Player, Code)
	end)
	PurchaseCrate:SetCallback(function(Player: Player, CrateName: Types.Crate, PurchaseMethodIndex: number)
		return ShopService:PurchaseCrateNetworkRequest(Player, CrateName, PurchaseMethodIndex)
	end)

	SetGiftPlayer:Connect(function(Player: Player, GiftPlayer: Player)
		if Player == GiftPlayer then
			return
		end
		ShopService.GiftPlayerMap[Player] = GiftPlayer
	end)

	GetGiftedGamepasses:SetCallback(function(_Player: Player, GiftPlayer: Player)
		local giftPlayerDocument = PlayerDataService:GetDocument(GiftPlayer)
		if not giftPlayerDocument then
			return {}
		end
		local giftPlayerData = giftPlayerDocument:read()
		return giftPlayerData.GiftedGamepasses
	end)

	-- set up currency dev products

	for currencyName, currencyInfo in Currencies do
		if currencyInfo.CanPurchase then
			for _, pack in currencyInfo.Packs do
				TransactionService:OnDeveloperProductPurchased(pack.ProductId, function(player: Player)
					local playerDocument = PlayerDataService:GetDocument(player)
					if not playerDocument then
						return Promise.reject("Player document not found.")
					end
					ResourceService:IncrementResource(player, currencyName, pack.Amount)
					return Promise.resolve()
				end)
			end
		end
	end

	for _, gamepassInfo in Gamepasses do
		if gamepassInfo.GiftProductId then
			TransactionService:OnDeveloperProductPurchased(gamepassInfo.GiftProductId, function(player: Player)
				local giftPlayer = ShopService.GiftPlayerMap[player]
				if not giftPlayer or giftPlayer:IsDescendantOf(Players) == false then
					return Promise.reject("No gift player found.")
				end
				local giftPlayerDocument = PlayerDataService:GetDocument(giftPlayer)
				if not giftPlayerDocument then
					return Promise.reject("Gift player document not found.")
				end

				local giftPlayerData = giftPlayerDocument:read()
				local newGiftedGamepasses = table.clone(giftPlayerData.GiftedGamepasses)

				if table.find(newGiftedGamepasses, gamepassInfo.GamepassId) then
					return Promise.reject("Already gifted")
				end

				table.insert(newGiftedGamepasses, gamepassInfo.GamepassId)

				local newGiftPlayerData = Freeze.Dictionary.set(giftPlayerData, "GiftedGamepasses", newGiftedGamepasses)

				giftPlayerDocument:write(newGiftPlayerData)

				return Promise.resolve()
			end)
		end
	end
end

function ShopService:PurchaseCrateNetworkRequest(
	Player: Player,
	CrateName: Types.Crate,
	PurchaseMethodIndex: number
): Types.NetworkResponse
	local crateInfo = Crates[CrateName]
	if not crateInfo then
		return { Success = false, Message = "Invalid crate" }
	end

	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return { Success = false, Message = "Player data not found" }
	end

	local playerData = playerDocument:read()
	local resources = playerData.Resources

	local purchaseMethod = crateInfo.PurchaseMethods[PurchaseMethodIndex]
	if not purchaseMethod then
		return { Success = false, Message = "Invalid purchase method" }
	end

	if purchaseMethod.Price == nil then
		return { Success = false, Message = "Invalid purchase method" }
	end

	if resources[purchaseMethod.Type] < purchaseMethod.Price then
		return { Success = false, Message = "Insufficient funds" }
	end

	local itemInfo = ItemUtils.GetItemInfoFromName(CrateName)
	if not itemInfo then
		return { Success = false, Message = "Invalid crate item" }
	end

	ItemService:GenerateItem(itemInfo.Id):tap(function(Item: Types.Item)
		InventoryService:AddItem(Player, Item, true)
		ResourceService:SetResource(Player, purchaseMethod.Type, resources[purchaseMethod.Type] - purchaseMethod.Price)
	end)

	return { Success = true, Message = "Crate purchased" }
end

function ShopService:SubmitCodeNetworkRequest(Player: Player, Code: string): Types.NetworkResponse
	local CodeData = Codes[Code]
	if not CodeData then
		return { Success = false, Message = "Invalid code" }
	end

	local playerDocument = PlayerDataService:GetDocument(Player)
	if not playerDocument then
		return { Success = false, Message = "Player data not found" }
	end

	local playerData = playerDocument:read()
	local codesRedeemed = playerData.CodesRedeemed

	if table.find(codesRedeemed, Code) then
		return { Success = false, Message = "Code already redeemed" }
	end

	if CodeData.ExpirationTime and os.time() > CodeData.ExpirationTime then
		return { Success = false, Message = "Code expired" }
	end

	local newData = table.clone(playerData)
	local newCodesRedeemed = table.clone(codesRedeemed)
	table.insert(newCodesRedeemed, Code)
	newData.CodesRedeemed = newCodesRedeemed

	playerDocument:write(newData)

	CodeData.Redeem(Player)
	return { Success = true, Message = "Code redeemed" }
end

return ShopService
