--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Codes = require(script.Codes)
local Net = require(ReplicatedStorage.packages.Net)
local PlayerDataService = require(ServerScriptService.services.PlayerDataService)
local Remotes = require(ReplicatedStorage.network.Remotes)
local Types = require(ReplicatedStorage.constants.Types)

local ShopNamespace = Remotes.Server:GetNamespace("Shop")
local SubmitCode = ShopNamespace:Get("SubmitCode") :: Net.ServerAsyncCallback

local ShopService = { Name = "ShopService" }

function ShopService:OnInit()
	SubmitCode:SetCallback(function(Player: Player, Code: string)
		return ShopService:SubmitCodeNetworkRequest(Player, Code)
	end)
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
