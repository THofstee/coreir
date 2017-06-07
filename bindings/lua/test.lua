local inspect = require 'inspect'
local coreir = require 'coreir'

-- The following doesn't really work right now... no way to get config strings
-- local interface = coreir.lib.COREModuleDefGetInterface(test_gen_defs)
-- local arg = coreir.lib.COREGetConfigValue("arg_here")
-- local arg_type = coreir.lib.COREGetArgKind(arg)
-- local arg_str = coreir.lib.COREArgStringGet(arg)
-- local arg_int = coreir.lib.COREArgIntGet(arg)

-- @todo Need to add some sort of way of specifying modules from a namespace
-- @todo Want to add something to the API where you can pass in a lua function for generator_funcs
-- @todo Need to add generators to the C API.
-- @todo Want to add a nice type construction method to Lua.

--- Test 1 -- loading a module from a file and parsing it
local test_gen = coreir.load_module("_add4.json")
coreir.print_module(test_gen)

local representation = coreir.parse_module(test_gen)
print(inspect(representation, coreir.inspect_options))

--- Test 2 -- constructing a simple module with a definition
local typ = {
	  ["in"] = coreir.array(coreir.bit_in, 24),
	  ["out"] = coreir.array(coreir.bit_out, 24),
}
local t = coreir.module_from("test_module", typ)
coreir.add_instance(t, t)
coreir.connect(t, t["in"], t.test_module1["in"])
coreir.connect(t, t.test_module1["out"], t["out"])

coreir.print_module(t)
print(inspect(t, coreir.inspect_options))
