-- Get a profile data value for a player.
return {
	Name = "profile-get",
	Aliases = { "pget", "profileget" },
	Description = "Gets a profile data value for a player.",
	Group = "DefaultUtil",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose profile to read.",
		},
		{
			Type = "profileKey",
			Name = "Key",
			Description = "The profile key (e.g. Coins, Logs).",
		},
	},
}
