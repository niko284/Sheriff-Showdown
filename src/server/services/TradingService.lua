--!strict

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Serde = ReplicatedStorage.network.serde
local Packages = ReplicatedStorage.packages
local Utils = ReplicatedStorage.utils
local Services = ServerScriptService.services
local Constants = ReplicatedStorage.constants

local InventoryService = require(Services.InventoryService)
local ItemTypes = require(Constants.ItemTypes)
local ItemUtils = require(Utils.ItemUtils)
local Net = require(Packages.Net)
local PlayerDataService = require(Services.PlayerDataService)
local PlayerUtils = require(Utils.PlayerUtils)
local Promise = require(Packages.Promise)
local Remotes = require(ReplicatedStorage.network.Remotes)
local ResourceService = require(Services.ResourceService)
local ServerComm = require(ServerScriptService.ServerComm)
local SettingsService = require(Services.SettingsService)
local Sift = require(Packages.Sift)
local TradeSerde = require(Serde.TradeSerde)
local Types = require(Constants.Types)
local UUIDSerde = require(Serde.UUIDSerde)

local TradeData = DataStoreService:GetDataStore("AnimeDungeonsTradeDataOfficial1")
local TradingRemotes = Remotes.Server:GetNamespace("Trading")
local TradeReceived = TradingRemotes:Get("TradeReceived") :: Net.ServerSenderEvent
local SendTradeToPlayer = TradingRemotes:Get("SendTradeToPlayer") :: Net.ServerAsyncCallback
local AcceptTradeRequest = TradingRemotes:Get("AcceptTradeRequest") :: Net.ServerAsyncCallback
local DeclineTradeRequest = TradingRemotes:Get("DeclineTradeRequest") :: Net.ServerAsyncCallback
local AddItemToTrade = TradingRemotes:Get("AddItemToTrade") :: Net.ServerAsyncCallback
local RemoveItemFromTrade = TradingRemotes:Get("RemoveItemFromTrade") :: Net.ServerAsyncCallback
local AcceptTrade = TradingRemotes:Get("AcceptTrade") :: Net.ServerAsyncCallback
local DeclineTrade = TradingRemotes:Get("DeclineTrade") :: Net.ServerAsyncCallback
local ConfirmTrade = TradingRemotes:Get("ConfirmTrade") :: Net.ServerAsyncCallback
local TradeProcessed = TradingRemotes:Get("TradeProcessed") :: Net.ServerSenderEvent

local MAX_PENDING_TRADES = 50
local LOCK_RETRY_ATTEMPTS = 5
local TRADING_LEVEL_REQUIREMENT = 1

local TradingService = {
	Name = "TradingService",
	ActiveTrade = ServerComm:CreateProperty("ActiveTrade", nil) :: Types.ServerRemoteProperty,
	Trades = {} :: { [string]: Types.Trade },
}

function TradingService:OnInit()
	SendTradeToPlayer:SetCallback(function(Player: Player, Receiver: Player)
		return self:SendTradeToPlayerRequest(Player, Receiver)
	end)
	AcceptTradeRequest:SetCallback(function(Player: Player, TradeUUID: string)
		return self:AcceptTradeClientRequest(Player, TradeUUID)
	end)
	DeclineTradeRequest:SetCallback(function(Player: Player, TradeUUID: string)
		return self:DeclineTradeClientRequest(Player, TradeUUID)
	end)
	AddItemToTrade:SetCallback(function(Player: Player, TradeUUID: string, ItemUUID: string)
		return self:AddItemToTradeRequest(Player, TradeUUID, ItemUUID)
	end)
	RemoveItemFromTrade:SetCallback(function(Player: Player, TradeUUID: string, ItemUUID: string)
		return self:RemoveItemFromTradeRequest(Player, TradeUUID, ItemUUID)
	end)
	AcceptTrade:SetCallback(function(Player: Player, TradeUUID: string)
		return self:AcceptTrade(TradeUUID, Player)
	end)
	DeclineTrade:SetCallback(function(Player: Player, TradeUUID: string)
		return self:DeclineTrade(TradeUUID, Player)
	end)
	ConfirmTrade:SetCallback(function(Player: Player, TradeUUID: string)
		return self:ConfirmTrade(TradeUUID, Player)
	end)
end

function TradingService:OnStart()
	-- #todo: handle players leaving the game mid trade.
	PlayerDataService.DocumentLoaded:Connect(function(Player: Player, PlayerDocument)
		-- Let's process any pending trades for the player.
		PlayerDataService
			:LockSession(Player)
			:andThen(function()
				local PlayerData = PlayerDocument:read()
				local TradeUUIDs = Sift.Array.map(
					PlayerData.ProcessingTrades,
					function(ProcessingTrade: Types.ProcessingTrade)
						return ProcessingTrade.TradeUUID
					end
				)

				return self:GrantProcessingTrades(Player, TradeUUIDs)
			end)
			:catch(function() end) -- We don't care if this fails.
			:finally(function()
				Promise.retryWithDelay(
					PlayerDataService.UnlockSession,
					LOCK_RETRY_ATTEMPTS,
					3,
					PlayerDataService,
					Player
				)
				if Player:IsDescendantOf(Players) == false then
					PlayerDataService:CloseDocument(Player)
				end
			end)
	end)
end

function TradingService:OnPlayerRemoving(Player: Player)
	-- Check if player was in a trade
	local playerTrade: Types.Trade = self:GetActiveTrade(Player)
	if playerTrade and playerTrade.Status == "Started" then -- Active trade
		self.Trades[playerTrade.UUID] = nil -- Clean trade.
		local otherPlayer = playerTrade.Sender == Player and playerTrade.Receiver or playerTrade.Sender;
		(self.ActiveTrade :: Types.ServerRemoteProperty):SetFor(otherPlayer, nil) -- Clear the other player's trade
	end
	-- Get any pending trades the player has
	local pendingTrades = self:GetPendingTradesForPlayer(Player) -- Receiver == Player
	local sentTrades = Sift.Dictionary.filter(self.Trades, function(Trade: Types.Trade) -- Sender == Player
		return Trade.Sender == Player and Trade.Status == "Pending"
	end)
	-- Clean any pending trades.
	for _, trade in sentTrades do
		self.Trades[trade.UUID] = nil
	end
	for _, trade in pendingTrades do
		self.Trades[trade.UUID] = nil
	end
end

function TradingService:CreateTrade(Sender: Player, Receiver: Player)
	local TradeUUID = HttpService:GenerateGUID(false)
	local Trade: Types.Trade = {
		Sender = Sender,
		Receiver = Receiver,
		-- The item offers from each side.
		SenderOffer = {},
		ReceiverOffer = {},
		Accepted = {}, -- Keep track of who accepted the trade
		Confirmed = {}, -- Keep track of who confirmed the trade
		UUID = TradeUUID,
		Status = "Pending",
		MaximumItems = 4,
	}
	-- We add the trade to the trades table with a unique identifier as its key.
	self.Trades[TradeUUID] = Trade
	TradeReceived:SendToPlayer(Receiver, TradeSerde.Serialize(Trade))
end

function TradingService:GetTrade(TradeUUID: string): Types.Trade
	return self.Trades[TradeUUID]
end

function TradingService:GetPendingTradesForPlayer(Receiver: Player): { [string]: Types.Trade }
	return Sift.Dictionary.filter(self.Trades, function(Trade: Types.Trade)
		return Trade.Receiver == Receiver and Trade.Status == "Pending"
	end)
end

function TradingService:TradeAlreadySent(Sender: Player, Receiver: Player): boolean
	local tradeAlreadySent = false
	for _, Trade in TradingService.Trades do
		if Trade.Sender == Sender and Trade.Receiver == Receiver and Trade.Status == "Pending" then
			tradeAlreadySent = true
			break
		end
	end
	return tradeAlreadySent
end

function TradingService:AddItemToTrade(ItemUUID: string, TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found.",
		}
	end
	if Trade.Status ~= "Started" then
		return {
			Success = false,
			Message = "Trade not started.",
		}
	end
	if Trade.Receiver ~= Player and Trade.Sender ~= Player then
		return {
			Success = false,
			Message = "You are not a part of this trade.",
		}
	end
	-- Check if the item is owned by the player and is stored in their inventory. (Not equipped)

	local item = InventoryService:GetItemOfUUID(Player, ItemUUID) :: Types.Item
	if item == nil then
		return {
			Success = false,
			Message = "Item not found in inventory.",
		}
	end
	-- Make sure the item is not already in the trade

	-- cannot call non-function workaround?
	local PlayerOffer = nil
	if Trade.Receiver == Player then
		PlayerOffer = Trade.ReceiverOffer
	else
		PlayerOffer = Trade.SenderOffer
	end

	for _, ItemOffered in PlayerOffer do
		if ItemOffered.UUID == ItemUUID then
			return {
				Success = false,
				Message = "Item already in trade.",
			}
		end
	end
	-- Make sure the item is not locked.
	if item.Locked == true then
		return {
			Success = false,
			Message = "Item is locked.",
		}
	end
	-- Make sure the maximum amount of items allowed in the trade have not been reached.
	if #PlayerOffer >= Trade.MaximumItems then
		return {
			Success = false,
			Message = "Maximum amount of items in trade reached.",
		}
	end
	-- Make sure that both players have not already accepted the trade.
	if #Trade.Accepted == 2 then
		return {
			Success = false,
			Message = "Trade already accepted.",
		}
	end
	local itemInfo = ItemUtils.GetItemInfoFromId(item.Id) :: Types.ItemInfo
	local itemTypeInfo = ItemTypes[itemInfo.Type] :: Types.ItemTypeInfo
	-- Check if the item is allowed to be traded.
	if itemTypeInfo.CanTrade == false or itemInfo.CanTrade == false then
		return {
			Success = false,
			Message = "Item cannot be traded.",
		}
	end
	-- IMPORTANT: Make sure this item is not part of one of our processing trades.
	local PlayerDocument = PlayerDataService:GetDocument(Player)
	local PlayerData = PlayerDocument:read()

	local ProcessingTrades = PlayerData.ProcessingTrades :: { Types.ProcessingTrade }
	for _, trade in ProcessingTrades do
		for _, giving in trade.Giving do
			if giving.UUID == ItemUUID then
				return {
					Success = false,
					Message = "Item is part of a processing trade.",
				}
			end
		end
	end
	-- If any of the players have already accepted the trade, un-accept it.
	if #Trade.Accepted > 0 then
		table.clear(Trade.Accepted)
		Trade.CooldownEnd = math.floor(workspace:GetServerTimeNow()) + 10 -- Cooldown for 10 seconds.
	end
	-- If none of these checks have returned false, it's safe to say that we can add this item to the trade.
	table.insert(PlayerOffer, item)
	local otherPlayer = Trade.Sender == Player and Trade.Receiver or Trade.Sender
	self.ActiveTrade:SetFor(otherPlayer, TradeSerde.Serialize(Trade))
	self.ActiveTrade:SetFor(Player, TradeSerde.Serialize(Trade)) -- note: can remove this and use client side state to update the UI.
	return {
		Success = true,
		Message = "Item added to trade.",
	}
end

function TradingService:RemoveItemFromTrade(ItemUUID: string, TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found.",
		}
	end
	if Trade.Status ~= "Started" then
		return {
			Success = false,
			Message = "Trade not started.",
		}
	end
	if Trade.Receiver ~= Player and Trade.Sender ~= Player then
		return {
			Success = false,
			Message = "You are not a part of this trade.",
		}
	end
	-- Make sure that both players have not already accepted the trade.
	if #Trade.Accepted == 2 then
		return {
			Success = false,
			Message = "Trade already accepted.",
		}
	end
	local PlayerOffer = nil
	if Trade.Receiver == Player then
		PlayerOffer = Trade.ReceiverOffer
	else
		PlayerOffer = Trade.SenderOffer
	end
	-- Check if the item is in the trade. If it is, remove it. If not, return false since it was not found.
	for Index, ItemOfferred: Types.Item in PlayerOffer do
		if ItemOfferred.UUID == ItemUUID then
			-- If any of the players have already accepted the trade, un-accept it.
			if #Trade.Accepted > 0 then
				Trade.CooldownEnd = math.floor(workspace:GetServerTimeNow()) + 10 -- Cooldown for 10 seconds.
				table.clear(Trade.Accepted)
			end
			table.remove(PlayerOffer, Index)
			--local otherPlayer = Trade.Sender == Player and Trade.Receiver or Trade.Sender
			self.ActiveTrade:SetForList({ Trade.Sender, Trade.Receiver }, TradeSerde.Serialize(Trade)) -- @note: can also use client-side state for the person removing the item.
			return {
				Success = true,
				Message = "Item removed from trade.",
			}
		end
	end
	return {
		Success = false,
		Message = "Item not found in trade.",
	}
end

function TradingService:AcceptTradeRequest(TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found",
		}
	end
	if Trade.Status ~= "Pending" then
		return {
			Success = false,
			Message = "Trade is not pending",
		}
	end
	if Trade.Receiver ~= Player then
		return {
			Success = false,
			Message = "Player is not the receiver of the trade!",
		}
	end
	-- If these checks pass, we can start the trade.
	local isInTradeSender = self:GetActiveTrade(Trade.Sender)
	local isInTradeReceiver = self:GetActiveTrade(Trade.Receiver)
	if isInTradeSender or isInTradeReceiver then
		return {
			Success = false,
			Message = "One of the players is already in a trade.",
		}
	end
	Trade.Status = "Started"
	self.ActiveTrade:SetForList({ Trade.Sender, Trade.Receiver }, TradeSerde.Serialize(Trade))
	return {
		Success = true,
		Message = "Trade started!",
	}
end

function TradingService:DeclineTradeRequest(TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found",
		}
	end
	if Trade.Status ~= "Pending" then
		return {
			Success = false,
			Message = "Trade is not pending",
		}
	end
	if Trade.Receiver ~= Player then
		return {
			Success = false,
			Message = "Player is not the receiver of the trade!",
		}
	end
	-- If these checks pass, we can decline the trade.
	self.Trades[TradeUUID] = nil
	return {
		Success = true,
		Message = "Trade declined",
	}
end

function TradingService:IsInTrade(Player: Player): boolean
	for _, Trade in self.Trades do
		if Trade.Sender == Player or Trade.Receiver == Player then
			return true
		end
	end
	return false
end

function TradingService:GetActiveTrade(Player: Player): Types.Trade?
	for _, Trade in self.Trades do
		if (Trade.Receiver == Player or Trade.Sender == Player) and Trade.Status ~= "Pending" then
			return Trade
		end
	end
	return nil
end

function TradingService:AcceptTrade(TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found",
		}
	end
	if Trade.Receiver ~= Player and Trade.Sender ~= Player then
		return {
			Success = false,
			Message = "Player not in this trade",
		}
	end
	local alreadyAccepted = table.find(Trade.Accepted, Player)
	if alreadyAccepted then
		return {
			Success = false,
			Message = "Trade already accepted",
		}
	end
	if Trade.CooldownEnd and Trade.CooldownEnd > os.time() then
		return {
			Success = false,
			Message = "Trade is on cooldown",
		}
	end
	-- We can accept the trade for this player
	table.insert(Trade.Accepted, Player)
	if #Trade.Accepted == 2 then -- If both players accepted the trade, it's time to confirm.
		Trade.Status = "Confirming"
	end
	self.ActiveTrade:SetForList({ Trade.Sender, Trade.Receiver }, TradeSerde.Serialize(Trade))
	return {
		Success = true,
		Message = "Trade accepted",
	}
end

function TradingService:ConfirmTrade(TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found",
		}
	end
	if Trade.Receiver ~= Player and Trade.Sender ~= Player then
		return {
			Success = false,
			Message = "Player not in this trade",
		}
	end
	if Trade.Status ~= "Confirming" then
		return {
			Success = false,
			Message = "Trade is not in the confirming stage",
		}
	end
	-- Has player confirmed trade?
	if table.find(Trade.Confirmed, Player) then
		return {
			Success = false,
			Message = "You already confirmed the trade!",
		}
	end
	table.insert(Trade.Confirmed, Player)
	local otherPlayer = Trade.Sender == Player and Trade.Receiver or Trade.Sender
	if #Trade.Confirmed == 2 then
		-- Both players confirmed the trade, it is complete.
		Trade.Status = "Completed"
		self.ActiveTrade:SetFor(otherPlayer, TradeSerde.Serialize(Trade))
		print("COMPLETING TRADES")
		self:CompleteTrade(TradeUUID)
			:finally(function()
				-- Unlock our session locks.
				PlayerDataService:UnlockSession(Trade.Sender)
				PlayerDataService:UnlockSession(Trade.Receiver)
				-- If our players left the game, let's release the profiles.
				local tradeSenderProfile = PlayerDataService:GetDocument(Trade.Sender)
				local tradeReceiverProfile = PlayerDataService:GetDocument(Trade.Receiver)
				print("PROCESSED")
				if tradeSenderProfile and Trade.Sender:IsDescendantOf(Players) == false then
					PlayerDataService:CloseDocument(Trade.Sender)
				else
					TradeProcessed:SendToPlayer(Trade.Sender, UUIDSerde.Serialize(TradeUUID))
				end
				if tradeReceiverProfile and Trade.Receiver:IsDescendantOf(Players) == false then
					PlayerDataService:CloseDocument(Trade.Receiver)
				else
					TradeProcessed:SendToPlayer(Trade.Receiver, UUIDSerde.Serialize(TradeUUID))
				end
				self.Trades[TradeUUID] = nil -- Clean up the trade.
			end)
			:catch(function(err: any)
				warn(tostring(err))
			end)
		return {
			Success = true,
			Message = "Trade confirmed!",
		}
	end
	self.ActiveTrade:SetFor(otherPlayer, TradeSerde.Serialize(Trade))
	return {
		Success = true,
		Message = "Trade confirmed!",
	}
end

function TradingService:CompleteTrade(TradeUUID: string)
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return Promise.reject("Trade not found")
	end
	if Trade.Status ~= "Completed" then
		return Promise.reject("Trade is not completed")
	end
	local ReceiverProcessingTrade: Types.ProcessingTrade = {
		Giving = Trade.ReceiverOffer,
		Receiving = Trade.SenderOffer,
		TradeUUID = TradeUUID,
	}
	local SenderProcessingTrade: Types.ProcessingTrade = {
		Giving = Trade.SenderOffer,
		Receiving = Trade.ReceiverOffer,
		TradeUUID = TradeUUID,
	}
	self.Trades[TradeUUID] = nil -- Wipe trade from trades
	print("All promising")
	return Promise
		.all({
			PlayerDataService:LockSession(Trade.Receiver),
			PlayerDataService:LockSession(Trade.Sender),
			self:AddProcessingTrade(Trade.Receiver, TradeUUID, ReceiverProcessingTrade),
			self:AddProcessingTrade(Trade.Sender, TradeUUID, SenderProcessingTrade),
		})
		:andThen(function()
			return Promise.retry(self.IndicateTradeComplete, 5, self, TradeUUID)
		end) -- At this point, the trade is complete. We just need to give the players their items.
		:andThen(function()
			return Promise.allSettled({ -- Wait for an attempt to process the trade to complete.
				Promise.retry(self.GrantProcessingTrades, 5, self, Trade.Receiver, { TradeUUID }),
				Promise.retry(self.GrantProcessingTrades, 5, self, Trade.Sender, { TradeUUID }),
			})
		end)
		:catch(function(error: any)
			warn(tostring(error))
		end)
end

function TradingService:GrantProcessingTrades(Player: Player, TradeUUIDs: { string })
	return Promise.new(function(resolve: (...any) -> nil, reject: (...any) -> nil)
		local PlayerDocument = PlayerDataService:GetDocument(Player)
		if not PlayerDocument then
			reject("Player profile not found")
			return
		end

		local PlayerData = PlayerDocument:read()

		local ProcessingTradesNew = table.clone(PlayerData.ProcessingTrades)

		print("Granting processing")
		-- Give the player their items for each trade.

		for _i, uuid in TradeUUIDs do
			local success, wasTradeComplete = pcall(function()
				return TradeData:GetAsync(uuid) -- This is only true if both the receiver and sender have the trade in their data. If one of them doesn't, this is nil.
			end)

			local processingTrade, index = TradingService:FindProcessingTrade(ProcessingTradesNew, uuid)

			if success and not wasTradeComplete then
				-- the trade was not completed by the other player, so we should remove it from the player's processing trades, we don't want to give them the items.
				warn("Trade not complete")
				continue
			elseif not processingTrade then
				warn("Processing trade not found?! CRITICAL SIDE CASE!")
				-- @note: this would lead to duping (the other player might have already processed the trade and received their items)
				continue
			elseif not success then -- might be a roblox api error, we'll retry next time the player joins.
				warn("Failed to get trade data: " .. tostring(wasTradeComplete))
				continue
			end

			-- Give player their receiving items, and take items they gave.
			local giving = processingTrade.Giving
			local receiving = processingTrade.Receiving

			for _, item in giving do
				InventoryService:RemoveItem(Player, item, false)
			end

			for _, item in receiving do
				InventoryService:AddItem(Player, item, false)
			end

			table.remove(ProcessingTradesNew, index) -- after giving the player their items, we remove the trade from their processing trades.
		end

		-- Save the player's profile to propagate the changes.
		PlayerDocument:write(Sift.Dictionary.merge(PlayerData, {
			ProcessingTrades = ProcessingTradesNew,
		}))

		local saveOk = PlayerDocument:save():await()

		if saveOk then
			resolve()
		else
			reject("Failed to save player document")
		end
	end)
end

function TradingService:IndicateTradeComplete(TradeUUID: string)
	print("indicating completion")
	return Promise.new(function(resolve, reject)
		local Success, Message = pcall(function()
			TradeData:SetAsync(TradeUUID, true) -- Indicate that both players saved the trade in their data.
		end)
		if Success then
			resolve()
		else
			reject(Message)
		end
	end)
end

function TradingService:FindProcessingTrade(
	ProcessingTrades: { Types.ProcessingTrade },
	TradeUUID: string
): (Types.ProcessingTrade?, number?)
	for index, processingTrade in ProcessingTrades do
		if processingTrade.TradeUUID == TradeUUID then
			return processingTrade, index
		end
	end
	return nil
end

function TradingService:AddProcessingTrade(Player: Player, TradeUUID: string, ProcessingTrade: Types.ProcessingTrade)
	local PlayerDocument = PlayerDataService:GetDocument(Player)
	if not PlayerDocument then
		return Promise.reject("Player document not found")
	end

	return Promise.new(function(resolve: (boolean, {}?) -> nil, reject: (Message: string) -> nil)
		local PlayerData = PlayerDocument:read()

		-- Add the trade to the player's pending trades, if it's not already there.

		local processingTradesList = PlayerData.ProcessingTrades
		local isNotProcessing = TradingService:FindProcessingTrade(processingTradesList, TradeUUID) == nil

		print("adding processing trade")

		if isNotProcessing then
			processingTradesList = Sift.Array.push(processingTradesList, ProcessingTrade)
			PlayerDocument:write(Sift.Dictionary.merge(PlayerData, {
				ProcessingTrades = if #processingTradesList >= MAX_PENDING_TRADES
					then Sift.Array.shift(processingTradesList, #processingTradesList - MAX_PENDING_TRADES + 1)
					else processingTradesList,
			}))
		end

		local saveOk = PlayerDocument:save():await()

		if saveOk then
			resolve(true)
		else
			reject("Failed to save player document")
		end
	end)
end

function TradingService:DeclineTrade(TradeUUID: string, Player: Player): Types.NetworkResponse
	local Trade: Types.Trade = self:GetTrade(TradeUUID)
	if not Trade then
		return {
			Success = false,
			Message = "Trade not found",
		}
	end
	if Trade.Receiver ~= Player and Trade.Sender ~= Player then
		return {
			Success = false,
			Message = "Player not in this trade",
		}
	end
	if Trade.Status == "Completed" then
		return {
			Success = false,
			Message = "Trade is already completed",
		}
	end
	self.Trades[TradeUUID] = nil
	self.ActiveTrade:SetForList({ Trade.Sender, Trade.Receiver }, nil)
	return {
		Success = true,
		Message = "Trade declined",
	}
end

function TradingService:SendTradeToPlayerRequest(Sender: Player, Receiver: Player): Types.NetworkResponse
	local isInTradeReceiver = self:GetActiveTrade(Receiver)
	local isInTradeSender = self:GetActiveTrade(Sender)
	local senderLevel = ResourceService:GetResource(Sender, "Level")
	local receiverLevel = ResourceService:GetResource(Receiver, "Level")
	if not senderLevel or (senderLevel and senderLevel < TRADING_LEVEL_REQUIREMENT) then
		return {
			Success = false,
			Message = string.format("You must be level %d to trade.", TRADING_LEVEL_REQUIREMENT),
		}
	end
	if not receiverLevel or (receiverLevel and receiverLevel < TRADING_LEVEL_REQUIREMENT) then
		return {
			Success = false,
			Message = string.format("%s must be level %d to trade.", Receiver.Name, TRADING_LEVEL_REQUIREMENT),
		}
	end
	if isInTradeReceiver or isInTradeSender then
		return {
			Success = false,
			Message = "Player(s) are already in a trade!",
		}
	end
	if Sender == Receiver then
		return {
			Success = false,
			Message = "You cannot send a trade to yourself!",
		}
	end

	if TradingService:TradeAlreadySent(Sender, Receiver) then
		return {
			Success = false,
			Message = "Trade already sent!",
		}
	end

	-- Check if the receiver has trade requests enabled in their settings.
	local receiverSettings = SettingsService:GetSettings(Receiver)
	if not receiverSettings then
		return {
			Success = false,
			Message = "Player settings not found",
		}
	else
		local tradeRequestSetting = receiverSettings["Trade Requests"]
		if tradeRequestSetting then
			if tradeRequestSetting.Value == "Nobody" then
				return {
					Success = false,
					Message = string.format("%s has trade requests disabled!", Receiver.Name),
				}
			elseif tradeRequestSetting.Value == "Friends" then
				-- Check if the player is friends with the invitee
				local ok, friends = PlayerUtils.GetFriendsAsync(Receiver.UserId):await()
				if not ok then
					return {
						Success = false,
						Message = "An error occurred while checking if you are friends with this player.",
					}
				end
				if not PlayerUtils.IsFriendsWith(friends, Sender.UserId) then
					return {
						Success = false,
						Message = string.format("%s is not your friend!", Receiver.Name),
					}
				end
			end
		end
		-- We can send the trade here
		self:CreateTrade(Sender, Receiver)
		return {
			Success = true,
			Message = "Trade sent.",
		}
	end
end

function TradingService:AcceptTradeClientRequest(Receiver: Player, TradeUUID: string)
	return self:AcceptTradeRequest(TradeUUID, Receiver)
end

function TradingService:DeclineTradeClientRequest(Receiver: Player, TradeUUID: string)
	return self:DeclineTradeRequest(TradeUUID, Receiver)
end

function TradingService:AddItemToTradeRequest(Player: Player, TradeUUID: string, ItemUUID: string)
	return self:AddItemToTrade(ItemUUID, TradeUUID, Player)
end

function TradingService:RemoveItemFromTradeRequest(Player: Player, TradeUUID: string, ItemUUID: string)
	return self:RemoveItemFromTrade(ItemUUID, TradeUUID, Player)
end

return TradingService
