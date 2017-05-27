local ffi = require('ffi')

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
   ffi.cdef(read_file(header_path .. 'coreir-single.h'))
   coreir.lib = ffi.load(lib_path .. 'libcoreir-c.so')

   -- Include context and global namespace as a singleton in the module
   -- Not sure if we ever need multiple contexts?
   coreir.ctx = ffi.gc(coreir.lib.CORENewContext(), coreir.lib.COREDeleteContext)
   coreir.global = coreir.lib.COREGetGlobal(coreir.ctx)
end

local function load_lib(lib)
   ffi.cdef("CORENamespace* CORELoadLibrary_" .. lib .. "(COREContext* c);")
   local ll = ffi.load(lib_path .. 'libcoreir-' .. lib .. '.so')

   -- The following is probably totally wrong
   -- But I want to do something like coreir.stdlib = CORELoadLibrary_stdlib etc
   -- and then just access that as coreir.stdlib later on...
   -- coreir[lib] = ll["CORELoadLibrary_" .. lib](coreir.ctx)

   -- For now, just return it.
   return ll["CORELoadLibrary_" .. lib](coreir.ctx)
end
coreir.load_lib = load_lib

init()
coreir.stdlib = load_lib('stdlib')

local function get_inst_ref_name(inst)
   return ffi.string(coreir.lib.COREGetInstRefName(inst))
end
coreir.get_inst_ref_name = get_inst_ref_name

local function get_inputs(module)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(module)
   local num_inputs = ffi.new("int[1]")
   local inputs_ptr = coreir.lib.COREDirectedModuleGetInputs(directed_module, num_inputs)
   local inputs = {}
   io.write("Inputs: " .. num_inputs[0] .. '\n')
   for i=0,num_inputs[0]-1 do
	  local src_len = ffi.new("int[1]")
	  local src = coreir.lib.COREDirectedConnectionGetSrc(inputs_ptr[i], src_len)
	  for j=0,src_len[0]-1 do
		 io.write(ffi.string(src[j]))
		 if j ~= src_len[0]-1 then io.write('->') end
	  end
	  io.write(' => ')
	  local snk_len = ffi.new("int[1]")
	  local snk = coreir.lib.COREDirectedConnectionGetSnk(inputs_ptr[i], snk_len)
	  for j=0,snk_len[0]-1 do
		 io.write(ffi.string(snk[j]))
		 if j ~= snk_len[0]-1 then io.write('->') end
	  end
	  io.write('\n')

	  local derp = coreir.lib.COREDirectedModuleSel(directed_module, src, src_len[0])
	  io.write("Src ")
	  coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(derp))
	  local herp = coreir.lib.COREDirectedModuleSel(directed_module, snk, snk_len[0])
	  io.write("Snk ")
	  coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(herp))
	  
	  inputs[i] = ffi.new("COREDirectedConnection*", inputs_ptr[i])
   end
   return inputs, num_inputs[0]
end
coreir.get_inputs = get_inputs

local function get_outputs(module)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(module)
   local num_outputs = ffi.new("int[1]")
   local outputs_ptr = coreir.lib.COREDirectedModuleGetOutputs(directed_module, num_outputs)
   local outputs = {}
   io.write("Outputs: " .. num_outputs[0] .. '\n')
   for i=0,num_outputs[0]-1 do
	  local src_len = ffi.new("int[1]")
	  local src = coreir.lib.COREDirectedConnectionGetSrc(outputs_ptr[i], src_len)
	  for j=0,src_len[0]-1 do
		 io.write(ffi.string(src[j]))
		 if j ~= src_len[0]-1 then io.write('->') end
	  end
	  io.write(' => ')
	  local snk_len = ffi.new("int[1]")
	  local snk = coreir.lib.COREDirectedConnectionGetSnk(outputs_ptr[i], snk_len)
	  for j=0,snk_len[0]-1 do
		 io.write(ffi.string(snk[j]))
		 if j ~= snk_len[0]-1 then io.write('->') end
	  end
	  io.write('\n')

	  local derp = coreir.lib.COREDirectedModuleSel(directed_module, src, src_len[0])
	  io.write("Src ")
	  coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(derp))
	  local herp = coreir.lib.COREDirectedModuleSel(directed_module, snk, snk_len[0])
	  io.write("Snk ")
	  coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(herp))

	  outputs[i] = ffi.new("COREDirectedConnection*", outputs_ptr[i])
   end
   return outputs, num_outputs[0]
end
coreir.get_outputs = get_outputs

return coreir
