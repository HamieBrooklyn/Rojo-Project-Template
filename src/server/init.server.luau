local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Loader = require(ReplicatedStorage.Packages.Loader)

local ServerServices = Loader.LoadDescendants(ServerScriptService.Server.Services, Loader.MatchesName("Service$"))
Loader.SpawnAll(ServerServices, "Init")
Loader.SpawnAll(ServerServices, "Start")

local SharedServices = Loader.LoadDescendants(ReplicatedStorage.Shared.Services.Shared, Loader.MatchesName("Service$"))
Loader.SpawnAll(SharedServices, "Init")
Loader.SpawnAll(SharedServices, "Start")
