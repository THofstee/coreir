local coreir = {}

local header_path = './'
local lib_path = '../../lib/'

local function read_file(file)
   local f = io.open(file, "rb")
   local content = f:read("*all")
   f:close()
   return content
end

local function init()
   local ffi = require('ffi')
   ffi.cdef(read_file(header_path .. 'coreir-single.h'))
   return ffi.load(lib_path .. 'libcoreir-c.so')
end

local function load_lib(lib)
   local ffi = require('ffi')
   ffi.cdef("CORENamespace* CORELoadLibrary_" .. lib .. "(COREContext* c);")
   return ffi.load(lib_path .. 'libcoreir-' .. lib .. '.so')
end

local ffi = require('ffi') -- luajit ffi

-- C standard library functions
ffi.cdef[[
void free(void* ptr);
]]

local coreir_lib = init()
local coreir_stdlib = load_lib('stdlib')

local function get_inst_ref_name(inst)
   return ffi.string(coreir_lib.COREGetInstRefName(inst))
end

-- local test_ctx = ffi.gc(coreir_lib.CORENewContext(), coreir_lib.COREDeleteContext)
local test_ctx = coreir_lib.CORENewContext()
local ns_global = coreir_lib.COREGetGlobal(test_ctx)

-- local module_str = "_simple.json"
local module_str = "_add4Gen.json"

local module_cstr = ffi.new("char[?]", #module_str)
ffi.copy(module_cstr, module_str)

local stdlib = coreir_stdlib.CORELoadLibrary_stdlib(test_ctx)
local test_gen = coreir_lib.CORELoadModule(test_ctx, module_cstr, err)
coreir_lib.COREPrintModule(test_gen)

local test_gen_defs = coreir_lib.COREModuleGetDef(test_gen)

local num_insts = ffi.new("int[1]")
local test_gen_insts = coreir_lib.COREModuleDefGetInstances(test_gen_defs, num_insts)

for i=0,num_insts[0]-1 do
   local inst = test_gen_insts[i]
   io.write(get_inst_ref_name(inst) .. '\n')
end

local function get_inputs(module)
   local directed_module = coreir_lib.COREModuleGetDirectedModule(module)
   local num_inputs = ffi.new("int[1]")
   local inputs_ptr = coreir_lib.COREDirectedModuleGetInputs(directed_module, num_inputs)
   local inputs = {}
   for i=1,num_inputs[0] do
	  -- local src_len = ffi.new("int[1]")
	  -- local src = coreir_lib.COREDirectedConnectionGetSrc(inputs_ptr[i], src_len)
	  -- io.write('Src: ' .. src_len[0] .. '\n')
	  -- for j=0,src_len[0]-1 do
	  -- 	 io.write(ffi.string(src[j]))
	  -- 	 if j ~= src_len[0]-1 then io.write('->') end
	  -- end
	  -- io.write('\n')
	  -- local snk_len = ffi.new("int[1]")
	  -- local snk = coreir_lib.COREDirectedConnectionGetSnk(inputs_ptr[i], snk_len)
	  -- io.write('Snk: ' .. snk_len[0] .. '\n')
	  -- for j=0,snk_len[0]-1 do
	  -- 	 io.write(ffi.string(snk[j]))
	  -- 	 if j ~= snk_len[0]-1 then io.write('->') end
	  -- end
	  -- io.write('\n')

	  inputs[i] = ffi.new("COREDirectedConnection*", inputs_ptr[i])
   end
   return inputs, num_inputs[0]
end

local function get_outputs(module)
   local directed_module = coreir_lib.COREModuleGetDirectedModule(module)
   local num_outputs = ffi.new("int[1]")
   local outputs_ptr = coreir_lib.COREDirectedModuleGetOutputs(directed_module, num_outputs)
   local outputs = {}
   for i=1,num_outputs[0] do
	  local src_len = ffi.new("int[1]")
	  local src = coreir_lib.COREDirectedConnectionGetSrc(outputs_ptr[i], src_len)
	  io.write('Src: ' .. src_len[0] .. '\n')
	  for j=0,src_len[0]-1 do
		 io.write(ffi.string(src[j]))
		 if j ~= src_len[0]-1 then io.write('->') end
	  end
	  io.write('\n')
	  local snk_len = ffi.new("int[1]")
	  local snk = coreir_lib.COREDirectedConnectionGetSnk(outputs_ptr[i], snk_len)
	  io.write('Snk: ' .. snk_len[0] .. '\n')
	  for j=0,snk_len[0]-1 do
		 io.write(ffi.string(snk[j]))
		 if j ~= snk_len[0]-1 then io.write('->') end
	  end
	  io.write('\n')

	  outputs[i] = ffi.new("COREDirectedConnection*", outputs_ptr[i])
   end
   return outputs, num_outputs[0]
end

local inputs,num_inputs = get_inputs(test_gen)
local outputs,num_outputs = get_outputs(test_gen)

for i,v in ipairs(inputs) do
   io.write(i .. 'e' .. '\n')
end

io.write("Inputs:  " .. num_inputs .. '\n')
io.write("Outputs: " .. num_outputs .. '\n')

local num_connections  = ffi.new("int[1]")
local connections = coreir_lib.COREModuleDefGetConnections(test_gen_defs, num_connections)
io.write("Connections: " .. num_connections[0] .. '\n')

return coreir
