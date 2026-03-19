local KEYS = {
	"Example",
}

return function(registry)
	registry:RegisterType("exampleType", registry.Cmdr.Util.MakeEnumType("Example type", KEYS))
end
