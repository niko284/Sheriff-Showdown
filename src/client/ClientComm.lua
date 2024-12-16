--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.packages

local ClientComm = require(Packages.Comm).ClientComm

return ClientComm.new(ReplicatedStorage:FindFirstChild("comm") :: Folder, false, "GameComm")
