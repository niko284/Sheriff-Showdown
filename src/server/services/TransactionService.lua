--!strict

-- Transaction Service
-- June 6th, 2022
-- Nick

--[[

    Handles all game transactions.

    TransactionService:VerifyPlayerExists(ReceiptInfo: table): Promise<T>
    TransactionService:VerifyProductPurchaseId(Player: Player, PlayerProfile: table, PurchaseId: number, OnPurchase: function): Promise<T>
	TransactionService:OnDeveloperProductPurchased(Callback: (Player: Player, ProductId: number) -> void): RBXScriptConnection

--]]

-- // Variables \\

local MarketPlaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local Crates = require(Constants.Crates)
local DataService = require(Services.DataService)
local Gamepasses = require(Constants.Gamepasses)
local InventoryService = require(Services.InventoryService)
local ItemService = require(Services.ItemService)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.Remotes)
local ResourceService = require(Services.ResourceService)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local TransactionsNamespace = Remotes.Server:GetNamespace("Transactions")

local PurchaseCrates = TransactionsNamespace:Get("PurchaseCrates")

local MAXIMUM_PURCHASEID_LOGS = 35

-- // Service Variables \\

local TransactionService = {
	Name = "TransactionService",
	Client = {},
	DeveloperProductPurchased = Signal.new(),
}

-- // Functions \\

function TransactionService:Init()
	PurchaseCrates:SetCallback(
		function(Player: Player, CrateType: Types.CrateType, PurchaseType: Types.PurchaseType, AmountOfCrates: number)
			return TransactionService:PurchaseCratesRequest(Player, CrateType, PurchaseType, AmountOfCrates)
		end
	)

	MarketPlaceService.ProcessReceipt = function(ReceiptInfo: Types.ProductReceipt)
		self:VerifyPlayerExists(ReceiptInfo)
			:andThen(function(Player: Player)
				return DataService:AwaitData(Player)
			end)
			:andThen(function()
				local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
				local PlayerProfile = DataService:GetData(Player)
				return self:VerifyProductPurchaseId(Player, PlayerProfile, ReceiptInfo.PurchaseId, function()
					-- Fire signal indicating that the player has purchased a developer product.
					self.DeveloperProductPurchased:Fire(Player, ReceiptInfo.ProductId)
				end)
			end)
			:catch(function(error: any)
				warn(tostring(error))
			end)
	end
end

function TransactionService:GetGamepassByName(GamepassName: string): Types.GamepassInfo
	local GamepassInfo = nil
	for _, Gamepass in Gamepasses do
		if Gamepass.Name == GamepassName then
			GamepassInfo = Gamepass
			break
		end
	end
	return GamepassInfo
end

function TransactionService:PurchaseCratesRequest(
	Player: Player,
	CrateType: Types.CrateType,
	PurchaseType: Types.PurchaseType,
	AmountOfCrates: number
): Types.NetworkResponse
	local crateInfo = Crates[CrateType]
	if not crateInfo then
		return {
			Success = false,
			Response = "Invalid crate type.",
		}
	end

	AmountOfCrates = math.round(AmountOfCrates)

	if AmountOfCrates > 1 then
		-- verify the player owns the multiple crate gamepass
		local multipleCratesPass = TransactionService:GetGamepassByName("Multiple Crates")
		if not TransactionService:PlayerOwnsGamepass(Player, multipleCratesPass.GamepassId) then
			return {
				Success = false,
				Response = "You must own the multiple crates gamepass to purchase multiple crates.",
			}
		end
	end

	-- verify the player has enough currency to purchase the crates, and that this is a valid method of purchasing crates, (only through currency)\
	local purchaseInfo = nil
	for _, purchaseData in crateInfo.PurchaseInfo do
		if purchaseData.PurchaseType == PurchaseType then
			purchaseInfo = purchaseData
			break
		end
	end
	if not purchaseInfo or purchaseInfo.PurchaseType == "Robux" then
		return {
			Success = false,
			Response = "Invalid purchase type.",
		}
	end

	-- check we have enough currency to purchase the crates
	local totalAmount = (purchaseInfo.Price :: number) * AmountOfCrates
	local playerAmount = ResourceService:GetResource(Player, purchaseInfo.PurchaseType)

	if playerAmount < totalAmount then
		return {
			Success = false,
			Response = "You do not have enough currency to purchase this.",
		}
	end

	-- remove the currency from the player
	ResourceService:IncrementResource(Player, purchaseInfo.PurchaseType, -totalAmount)

	-- generate the items rolled from the crates (one each) and add to the player's inventory, then return the items to the client to display
	local crateItems = ItemService:RollItemsFromCrate(CrateType, AmountOfCrates)

	-- add the items to the player's inventory
	InventoryService:AddItems(Player, crateItems)

	return {
		Success = true,
		Response = crateItems,
	}
end

function TransactionService:VerifyPlayerExists(ReceiptInfo: Types.ProductReceipt)
	return Promise.new(function(resolve: (Player) -> (), reject: (string) -> (), _onCancel: (() -> ()) -> ())
		local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
		if not Player then
			reject("Failed to get player of user id: " .. ReceiptInfo.PlayerId)
		end
		resolve(Player)
	end)
end

function TransactionService:VerifyProductPurchaseId(
	Player: Player,
	PlayerProfile: DataService.PlayerProfile,
	PurchaseId: string,
	OnPurchase: (Player) -> ()
)
	return Promise.new(
		function(resolve: (Enum.ProductPurchaseDecision) -> (), reject: (string) -> (), _onCancel: (() -> ()) -> ())
			if not PlayerProfile:IsActive() then
				reject("Player profile is not active for user id: " .. Player.UserId)
			else
				local MetaData = PlayerProfile.MetaData
				local ReceiptPurchaseIds = MetaData.MetaTags.ReceiptPurchaseIds
				if not ReceiptPurchaseIds then
					ReceiptPurchaseIds = {}
					MetaData.MetaTags.ReceiptPurchaseIds = {}
				end
				if not table.find(ReceiptPurchaseIds, PurchaseId) then
					while #ReceiptPurchaseIds > MAXIMUM_PURCHASEID_LOGS do
						table.remove(ReceiptPurchaseIds, 1)
					end
					table.insert(ReceiptPurchaseIds, PurchaseId)
					coroutine.wrap(OnPurchase)(Player)
				end
				local SavedToDataResult = nil
				local function CheckLatestMetaTags()
					local SavedReceiptPurchaseIds = MetaData.MetaTagsLatest.ReceiptPurchaseIds
					if SavedReceiptPurchaseIds and table.find(SavedReceiptPurchaseIds, PurchaseId) then
						SavedToDataResult = true
					end
				end
				CheckLatestMetaTags()
				local MetaTagsUpdated = PlayerProfile.MetaTagsUpdated:Connect(function()
					CheckLatestMetaTags()
					if not PlayerProfile:IsActive() and SavedToDataResult == nil then
						SavedToDataResult = false
					end
				end)
				while not SavedToDataResult do
					task.wait()
				end
				MetaTagsUpdated:Disconnect()
				local productPurchaseDecision = nil
				if SavedToDataResult then
					productPurchaseDecision = Enum.ProductPurchaseDecision.PurchaseGranted
				else
					productPurchaseDecision = Enum.ProductPurchaseDecision.NotProcessedYet
				end
				resolve(productPurchaseDecision)
			end
		end
	)
end

function TransactionService:OnDeveloperProductPurchased(Callback: (Player, number) -> ())
	return self.DeveloperProductPurchased:Connect(Callback)
end

function TransactionService:PlayerOwnsGamepass(Player: Player, GamepassId: number): boolean
	--[[local playerProfile = DataService:GetData(Player)
	if playerProfile then
		if table.find(playerProfile.Data.Resources.GamepassesGifted, GamepassId) then
			return true -- Player owns the gamepass, it was gifted to them.
		end
	end--]]
	local Success, Result = pcall(function()
		return MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, GamepassId)
	end)
	if Success and Result then
		return Result
	end
	return false
end

return TransactionService
