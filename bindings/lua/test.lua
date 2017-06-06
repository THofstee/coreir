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

function hex_dump(buf)
   for byte=1, #buf, 16 do
	  local chunk = buf:sub(byte, byte+15)
	  io.write(string.format('%08X  ',byte-1))
	  chunk:gsub('.', function (c) io.write(string.format('%02X ',string.byte(c))) end)
	  io.write(string.rep(' ',3*(16-#chunk)))
	  io.write(' ',chunk:gsub('%c','.'),"\n") 
   end
end

local representation = coreir.parse_module(test_gen)

local inspect_options = {}
inspect_options.process = function(item, path)
   if type(item) == 'cdata' then
	  -- Stringify cdata
	  return tostring(item)
   elseif type(item) == 'table' and item[0] ~= nil then
	  -- Convert 0-based arrays to 1-based arrays
	  local newitem = {}
	  for i,v in pairs(item) do
		 -- Make sure it's not just a random table with 0 as a key
		 if type(i) ~= 'int' then return item end
		 newitem[i+1] = v
	  end
	  return newitem
   else
	  return item
   end
end
print(inspect(representation, inspect_options))

