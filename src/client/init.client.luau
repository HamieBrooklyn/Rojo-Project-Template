local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Packages.Loader)

local ClientServices = Loader.LoadDescendants(ReplicatedStorage.Shared.Services.Client, Loader.MatchesName("Service$"))
Loader.SpawnAll(ClientServices, "Init")
Loader.SpawnAll(ClientServices, "Start")

local SharedServices = Loader.LoadDescendants(ReplicatedStorage.Shared.Services.Shared, Loader.MatchesName("Service$"))
Loader.SpawnAll(SharedServices, "Init")
Loader.SpawnAll(SharedServices, "Start")
