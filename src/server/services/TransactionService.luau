--!strict

--[[

    Handles all game transactions.

    TransactionService:VerifyPlayerExists(ReceiptInfo: table): Promise<T>
    TransactionService:VerifyProductPurchaseId(Player: Player, PlayerProfile: table, PurchaseId: number, OnPurchase: function): Promise<T>
	TransactionService:OnDeveloperProductPurchased(Callback: (Player: Player, ProductId: number) -> void): RBXScriptConnection

--]]

local MarketPlaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.packages
local Constants = ReplicatedStorage.constants
local Services = ServerScriptService.services

local PlayerDataService = require(Services.PlayerDataService)
local Promise = require(Packages.Promise)
local Sift = require(ReplicatedStorage.packages.Sift)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local MAXIMUM_PURCHASEID_LOGS = 50

-- // Service Variables \\

local TransactionService = {
	Name = "TransactionService",
	DeveloperProductPurchased = Signal.new() :: Signal.Signal<Player, number>,
	OnProductPurchasedPromises = {} :: { [number]: { (player: Player) -> any } },
}

-- // Functions \\

function TransactionService:OnInit()
	MarketPlaceService.ProcessReceipt = function(ReceiptInfo: Types.ProductReceipt)
		local resolved, purchaseDecision = TransactionService:VerifyPlayerExists(ReceiptInfo)
			:andThen(function(player: Player)
				return PlayerDataService:AwaitDocument(player)
			end)
			:andThen(function(playerDocument: PlayerDataService.Document)
				local player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
				if not player then
					return Promise.reject(`Player of user id {ReceiptInfo.PlayerId} was not found.`)
				end
				return TransactionService:VerifyProductPurchaseId(
					player,
					playerDocument,
					ReceiptInfo.PurchaseId,
					function()
						-- Fire signal indicating that the player has purchased a developer product.
						TransactionService.DeveloperProductPurchased:Fire(player, ReceiptInfo.ProductId)

						local purchasePromises = {}
						local promiseFns = TransactionService.OnProductPurchasedPromises[ReceiptInfo.ProductId]

						if promiseFns then
							for _, promiseFn in promiseFns do
								table.insert(purchasePromises, promiseFn(player))
							end
						end

						local ok = Promise.all(purchasePromises):await()

						return ok
					end
				)
			end)
			:await()

		if resolved then
			return purchaseDecision
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
end

function TransactionService:VerifyPlayerExists(ReceiptInfo: Types.ProductReceipt)
	return Promise.new(function(resolve: (Player) -> (), reject: (string) -> (), _onCancel: (() -> ()) -> ())
		local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
		if not Player then
			reject("Failed to get player of user id: " .. ReceiptInfo.PlayerId)
		else
			resolve(Player)
		end
	end)
end

function TransactionService:VerifyProductPurchaseId(
	Player: Player,
	PlayerDocument: PlayerDataService.Document,
	PurchaseId: string,
	OnPurchase: (Player) -> boolean
)
	return Promise.new(
		function(resolve: (Enum.ProductPurchaseDecision) -> (), _reject: (string) -> (), _onCancel: (() -> ()) -> ())
			local data = PlayerDocument:read()

			if table.find(data.ReceiptHistory, PurchaseId) then
				-- if the docs are correct, you could return PurchaseGranted here
				local ok = PlayerDocument:save():await()

				if ok then
					resolve(Enum.ProductPurchaseDecision.PurchaseGranted)
					return
				else
					resolve(Enum.ProductPurchaseDecision.NotProcessedYet)
					return
				end
			end

			-- PRODUCTS[productId] returns a function that returns the new data
			local grantedOk = OnPurchase(Player)

			if not grantedOk then
				resolve(Enum.ProductPurchaseDecision.NotProcessedYet)
				return
			end

			local receiptHistory = table.clone(data.ReceiptHistory)
			table.insert(receiptHistory, PurchaseId)

			data = PlayerDocument:read()

			PlayerDocument:write(Sift.Dictionary.merge(data, {
				ReceiptHistory = if #receiptHistory >= MAXIMUM_PURCHASEID_LOGS
					then Sift.Array.shift(receiptHistory, #receiptHistory - MAXIMUM_PURCHASEID_LOGS + 1)
					else receiptHistory,
			}))

			local saveOk = PlayerDocument:save():await()
			if not saveOk then
				resolve(Enum.ProductPurchaseDecision.NotProcessedYet)
				return
			end

			resolve(Enum.ProductPurchaseDecision.PurchaseGranted)
		end
	)
end

function TransactionService:PlayerOwnsGamepass(Player: Player, GamepassId: number): boolean
	local playerProfile = PlayerDataService:GetDocument(Player)
	if playerProfile then
		if table.find(playerProfile.Data.Resources.GamepassesGifted, GamepassId) then
			return true -- Player owns the gamepass, it was gifted to them.
		end
	end
	local Success, Result = pcall(function()
		return MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, GamepassId)
	end)
	if Success and Result then
		return Result
	end
	return false
end

function TransactionService:OnDeveloperProductPurchased(ProductId: number, Callback: (Player) -> any)
	local productPromises = TransactionService.OnProductPurchasedPromises[ProductId]
	if not productPromises then
		local callbacks = {}
		TransactionService.OnProductPurchasedPromises[ProductId] = callbacks
		productPromises = callbacks
	end
	table.insert(productPromises, Callback)
end

return TransactionService
