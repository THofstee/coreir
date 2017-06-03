local inspect = require 'inspect'
local coreir = require 'coreir'

-- Load the module from a file
local test_gen = coreir.load_module("_add4.json")
coreir.print_module(test_gen)

local test_gen_defs = coreir.module_get_def(test_gen)

local instances,num_insts = coreir.module_def_get_instances(test_gen_defs)

for i=0,num_insts-1 do
   local inst = instances[i]
   io.write(coreir.get_inst_ref_name(inst) .. '\n')
end

local inputs,num_inputs = coreir.get_inputs(test_gen)
local outputs,num_outputs = coreir.get_outputs(test_gen)

-- The following doesn't really work right now... no way to get config strings
-- local interface = coreir.lib.COREModuleDefGetInterface(test_gen_defs)
-- local arg = coreir.lib.COREGetConfigValue("arg_here")
-- local arg_type = coreir.lib.COREGetArgKind(arg)
-- local arg_str = coreir.lib.COREArgStringGet(arg)
-- local arg_int = coreir.lib.COREArgIntGet(arg)

local dir_inst,num_d_inst = coreir.get_dir_inst(test_gen)
for i=0,num_d_inst-1 do
   coreir.get_inst_inputs(dir_inst[i])
   coreir.get_inst_outputs(dir_inst[i])
   io.write(i .. '\n')
end

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

local representation = {}

-- Idea: The get_inputs and get_inst_inputs both seem to work decently
-- We can use the selection path in order to figure out how everything is connected
-- The first element in the selection path is the module name, so we can get self
-- Then from there, we do something to get inst ref name
-- Not sure if we should use the inst inputs or the module inputs
-- Actually, we need to use both. The module for top level module, then inst internally
-- Anyhow, from there we can get the wireable from COREDirectedModuleSel
for i=0,num_d_inst-1 do
   local num_in = ffi.new("int[1]")
   local in_ptr = coreir.lib.COREDirectedInstanceGetInputs(dir_inst[i], num_in)

   local p_len = ffi.new("int[1]")
   local p_ptr = coreir.lib.COREDirectedConnectionGetSnk(in_ptr[0], p_len)

   local this = ffi.string(p_ptr[0])

   local cstr_arr = ffi.new("const char*[1]")
   cstr_arr[0] = ffi.new("char[?]", #this+1, this)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(test_gen)
   local this_wireable = coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, 1)
   io.write(this .. ' : ' .. coreir.get_inst_ref_name(this_wireable) .. '\n')
   representation[this] = {}
   representation[this].wireable = this_wireable
   representation[this].instance = coreir.get_inst_ref_name(this_wireable)

   local this2 = ffi.string(p_ptr[1])
   local cstr_arr = ffi.new("const char*[2]")
   cstr_arr[0] = ffi.new("char[?]", #this+1, this)
   cstr_arr[1] = ffi.new("char[?]", #this2+1, this2)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(test_gen)
   local wireable = coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, 2)
   local wireable_type = coreir.lib.COREWireableGetType(wireable)   

   representation[this].connections = {}
   representation[this].connections[ffi.string(p_ptr[1])] = {}
   representation[this].connections[ffi.string(p_ptr[1])].type = coreir.parse_type(wireable_type)
end

print(inspect(representation))

-- Trying to iterate through instances and print out the selection paths
-- for i=0,num_insts-1 do
--    local inst = instances[i]
--    local sel_path_len = ffi.new("int[1]")
--    local sel_path = coreir.lib.COREWireableGetSelectPath(inst, sel_path_len)
--    for j=0,sel_path_len[0]-1 do
-- 	  io.write(ffi.string(sel_path[0]) .. ' ')
--    end
--    io.write('\n')
-- end

-- Trying to iterate through instances and figure out what each is connected to
-- Doesn't seem to work...
-- for i=0,num_insts-1 do
--    local num_connected_wireables = ffi.new("int[1]")
--    local connected_wireables = coreir.lib.COREWireableGetConnectedWireables(instances[i], num_connected_wireables)
--    io.write("Num connected wireables to instance " .. i .. " " .. num_connected_wireables[0] .. '\n')
-- end

-- Attempting to iterate through connections and associate the src/snk of each connection to a wireable that we know from our instances list
-- Doesn't seem to work.
-- local num_connections = ffi.new("int[1]")
-- local connections = coreir.lib.COREModuleDefGetConnections(test_gen_defs, num_connections)
-- io.write("Connections: " .. num_connections[0] .. '\n')
-- for i=0,num_connections[0]-1 do
--    local first = coreir.lib.COREConnectionGetFirst(connections[i])
--    local first_type = coreir.lib.COREWireableGetType(first)
--    io.write("First  ")
--    coreir.lib.COREPrintType(first_type)

--    local second = coreir.lib.COREConnectionGetSecond(connections[i])
--    local second_type = coreir.lib.COREWireableGetType(second)
--    io.write("Second ")
--    coreir.lib.COREPrintType(second_type)

--    -- Figure out what instances these connections correspond to
--    -- Except, this doesn't work... maybe the Wireable* has a different meaning?
--    io.write(string.format("0x%x\n", tonumber(ffi.cast("uint64_t", first))))
--    io.write(string.format("0x%x\n", tonumber(ffi.cast("uint64_t", second))))
--    for j=0,num_insts-1 do
-- 	  local inst = instances[j]
-- 	  io.write(string.format("0x%x\n", tonumber(ffi.cast("uint64_t", inst))))

-- 	  if (inst == first) then
-- 		 io.write("Fst Instance: " .. j ..  '\n')
-- 	  end
-- 	  if (inst == second) then
-- 		 io.write("Snd Instance: " .. j ..  '\n')
-- 	  end
--    end
-- end
