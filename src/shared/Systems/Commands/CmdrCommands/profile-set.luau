-- Set a profile data value for a player (numeric keys only).
return {
	Name = "profile-set",
	Aliases = { "pset", "profileset" },
	Description = "Sets a profile data value for a player. Use for numeric keys (e.g. Coins, Logs).",
	Group = "DefaultUtil",
	Args = {
		{
			Type = "player",
			Name = "Player",
			Description = "The player whose profile to change.",
		},
		{
			Type = "profileKey",
			Name = "Key",
			Description = "The profile key (e.g. Coins, Logs).",
		},
		{
			Type = "number",
			Name = "Value",
			Description = "The value to set.",
		},
	},
}
