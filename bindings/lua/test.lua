local coreir = require 'coreir'
local ffi = require 'ffi'

-- Load the module from a file
local module_filename = "_add4.json"
local module_cstr = ffi.new("char[?]", #module_filename)
ffi.copy(module_cstr, module_filename)

local test_gen = coreir.lib.CORELoadModule(coreir.ctx, module_cstr, err)
coreir.lib.COREPrintModule(test_gen)

local test_gen_defs = coreir.lib.COREModuleGetDef(test_gen)

local num_insts = ffi.new("int[1]")
local instances = coreir.lib.COREModuleDefGetInstances(test_gen_defs, num_insts)

for i=0,num_insts[0]-1 do
   local inst = instances[i]
   io.write(coreir.get_inst_ref_name(inst) .. '\n')
end

local inputs,num_inputs = coreir.get_inputs(test_gen)
local outputs,num_outputs = coreir.get_outputs(test_gen)

for i,v in ipairs(inputs) do
   io.write(i .. 'e' .. '\n')
end

-- The following doesn't really work right now... no way to get config strings
-- local interface = coreir.lib.COREModuleDefGetInterface(test_gen_defs)
-- local arg = coreir.lib.COREGetConfigValue("arg_here")
-- local arg_type = coreir.lib.COREGetArgKind(arg)
-- local arg_str = coreir.lib.COREArgStringGet(arg)
-- local arg_int = coreir.lib.COREArgIntGet(arg)

local num_connections  = ffi.new("int[1]")
local connections = coreir.lib.COREModuleDefGetConnections(test_gen_defs, num_connections)
io.write("Connections: " .. num_connections[0] .. '\n')
local first = coreir.lib.COREConnectionGetFirst(connections[0])
local first_type = coreir.lib.COREWireableGetType(first)
coreir.lib.COREPrintType(first_type)
