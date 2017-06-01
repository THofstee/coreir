local coreir = require 'coreir'

-- Load the module from a file
-- local stdlib = coreir.load_lib('stdlib')
local test_gen = coreir.load_module("_add4.json")
-- coreir.print_module(test_gen)

-- local test_gen_defs = coreir.module_get_def(test_gen)

-- local instances,num_insts = coreir.module_def_get_instances(test_gen_defs)

-- for i=0,num_insts-1 do
--    local inst = instances[i]
--    io.write(coreir.get_inst_ref_name(inst) .. '\n')
-- end

-- -- local inputs,num_inputs = coreir.get_inputs(test_gen)
-- local outputs,num_outputs = coreir.get_outputs(test_gen)

-- -- The following doesn't really work right now... no way to get config strings
-- -- local interface = coreir.lib.COREModuleDefGetInterface(test_gen_defs)
-- -- local arg = coreir.lib.COREGetConfigValue("arg_here")
-- -- local arg_type = coreir.lib.COREGetArgKind(arg)
-- -- local arg_str = coreir.lib.COREArgStringGet(arg)
-- -- local arg_int = coreir.lib.COREArgIntGet(arg)

-- local dir_inst,num_d_inst = coreir.get_inst(test_gen)
-- for i=0,num_d_inst do
--    coreir.get_inst_inputs(dir_inst[i])
--    -- coreir.get_inst_outputs(dir_inst[i])
--    io.write(i .. '\n')
-- end

-- local num_connections  = ffi.new("int[1]")
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
--    for i=0,num_insts[0]-1 do
-- 	  local inst = instances[i]
-- 	  if (inst == first) then
-- 		 io.write("Fst Instance: " .. i ..  '\n')
-- 	  end
-- 	  if (inst == second) then
-- 		 io.write("Snd Instance: " .. i ..  '\n')
-- 	  end
--    end
-- end
