local inspect = require 'inspect'
local coreir = require 'coreir'

-- Load the module from a file
local test_gen = coreir.load_module("_add4.json")
coreir.print_module(test_gen)

-- The following doesn't really work right now... no way to get config strings
-- local interface = coreir.lib.COREModuleDefGetInterface(test_gen_defs)
-- local arg = coreir.lib.COREGetConfigValue("arg_here")
-- local arg_type = coreir.lib.COREGetArgKind(arg)
-- local arg_str = coreir.lib.COREArgStringGet(arg)
-- local arg_int = coreir.lib.COREArgIntGet(arg)

local ffi = require('ffi')

local typ = {
	  ["in"] = coreir.array(coreir.bit_in, 24),
	  ["out"] = coreir.array(coreir.bit_out, 24),
}
local t = coreir.module_from("test_module", typ)
coreir.add_instance(t, t)
coreir.connect(t, t["in"], t.test_module1["in"])
coreir.connect(t, t.test_module1["out"], t["out"])

-- @todo Need to add some sort of way of specifying modules from a namespace
-- @todo Want to add something to the API where you can pass in a lua function for generator_funcs
-- @todo Need to add generators to the C API.
-- @todo Want to add a nice type construction method to Lua.

coreir.print_module(t)
print(inspect(t, coreir.inspect_options))

-- function hex_dump(buf)
--    for byte=1, #buf, 16 do
-- 	  local chunk = buf:sub(byte, byte+15)
-- 	  io.write(string.format('%08X  ',byte-1))
-- 	  chunk:gsub('.', function (c) io.write(string.format('%02X ',string.byte(c))) end)
-- 	  io.write(string.rep(' ',3*(16-#chunk)))
-- 	  io.write(' ',chunk:gsub('%c','.'),"\n") 
--    end
-- end

-- local representation = coreir.parse_module(test_gen)

-- print(inspect(representation, coreir.inspect_options))

