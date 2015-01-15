# lua-states-mixin

try:
	if not gSTARTED: print( gSTARTED )
except:
	MODULE = "lua-states-mixin"
	include: "../DMC-Lua-Library/snakemake/Snakefile"

module_config = {
	"name": "lua-states-mixin",
	"module": {
		"files": [
				"lua_states_mix.lua"
		],
		"requires": [
		]
	},
	"tests": {
		"files": [
		],
		"requires": [
		]
	}
}

register( "lua-states-mixin", module_config )

