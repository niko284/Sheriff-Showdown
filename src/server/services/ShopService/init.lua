--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Codes = require(script.Codes)
local Crates = require(ReplicatedStorage.constants.Crates)
local InventoryService = require(ServerScriptService.services.InventoryService)
local ItemService = require(ServerScriptService.services.ItemService)
local ItemUtils = require(ReplicatedStorage.utils.ItemUtils)
local Net = require(ReplicatedStorage.packages.Net)
local PlayerDataService = require(ServerScriptService.services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ResourceService = require(ServerScriptService.services.ResourceService)
local Types = require(ReplicatedStorage.constants.Types)

local ShopNamespace = Remotes.Server:GetNamespace("Shop")
local SubmitCode = ShopNamespace:Get("SubmitCode") :: Net.ServerAsyncCallback
local PurchaseCrate = ShopNamespace:Get("PurchaseCrate") :: Net.ServerAsyncCallback

local ShopService = { Name = "ShopService" }

function ShopService:OnInit()
	SubmitCode:SetCallback(function(Player: Player, Code: string)
		return ShopService:SubmitCodeNetworkRequest(Player, Code)
	end)
	PurchaseCrate:SetCallback(function(Player: Player, CrateName: Types.Crate, PurchaseMethod: number)
		return ShopService:PurchaseCrateNetworkRequest(Player, CrateName, PurchaseMethod)
	end)
end

function ShopService:PurchaseCrateNetworkRequest(
	Player: Player,
	CrateName: Types.Crate,
	PurchaseMethod: number
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

	local purchaseMethod = crateInfo.PurchaseMethods[PurchaseMethod]
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
