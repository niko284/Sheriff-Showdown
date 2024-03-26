--!strict

-- Interfaces
-- November 17th, 2022
-- Ron

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Constants = ReplicatedStorage.constants
local Packages = ReplicatedStorage.packages

local Remotes = require(ReplicatedStorage.Remotes)
local Signal = require(Packages.Signal)
local Types = require(Constants.Types)

local IS_SERVER = RunService:IsServer()

local Interfaces: { Client: Types.Interface, Server: Types.Interface, Comm: { [string]: any } } = {
	Comm = {},
	Server = {},
	Client = {},
}

if IS_SERVER then
	local EntityRemotes = Remotes.Server:GetNamespace("Entity")
	Interfaces.Comm = {}
	Interfaces.Comm = {
		ProcessAction = EntityRemotes:Get("ProcessAction"),
		ProcessFX = EntityRemotes:Get("ProcessFX"),
		ProcessHit = EntityRemotes:Get("ProcessHit"),
		FinishedClient = EntityRemotes:Get("FinishedClient"),
		FinishedServer = EntityRemotes:Get("FinishedServer"),
		ProcessServerEffect = EntityRemotes:Get("ProcessServerEffect"),
		StopHits = EntityRemotes:Get("StopHits"),
	}
	Interfaces.Server.InventoryService = require(ServerScriptService.services.InventoryService)
	Interfaces.Server.AudioService = require(ServerScriptService.services.AudioService)
	Interfaces.Server.ProcessHit = Signal.new() -- ask the server to process a hit
	Interfaces.Server.HitProcessed = Signal.new() -- notify that a hit has been processed
else
	local EntityRemotes = Remotes.Client:GetNamespace("Entity")
	Interfaces.Comm = {
		ProcessAction = EntityRemotes:Get("ProcessAction"),
		ProcessFX = EntityRemotes:Get("ProcessFX"),
		StopHits = EntityRemotes:Get("StopHits"),
		ProcessHit = EntityRemotes:Get("ProcessHit"),
		FinishedClient = EntityRemotes:Get("FinishedClient"),
		FinishedServer = EntityRemotes:Get("FinishedServer"),
		ProcessServerEffect = EntityRemotes:Get("ProcessServerEffect"),
	}
end

return Interfaces
