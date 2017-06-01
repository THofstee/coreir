local ffi = require('ffi')

local coreir = {}

local header_path = './'
local lib_path = '../../lib/'

local function first_to_upper(str)
    return (str:gsub("^%l", string.upper))
end

local function read_file(file)
   local f = assert(io.open(file), "Could not open " .. file .. " for reading")
   local content = f:read("*a")
   f:close()
   return content
end

---

local function init()
   ffi.cdef(read_file(header_path .. 'coreir-single.h'))
   coreir.lib = ffi.load(lib_path .. 'libcoreir-c.so')

   -- Include context and global namespace as a singleton in the module
   -- Not sure if we ever need multiple contexts?
   -- coreir.ctx = ffi.gc(coreir.lib.CORENewContext(), coreir.lib.COREDeleteContext)
   coreir.ctx = coreir.lib.CORENewContext()
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
   coreir["__library" .. lib] = ll
   return ll["CORELoadLibrary_" .. lib](coreir.ctx)
end
coreir.load_lib = load_lib

init()
coreir.stdlib = load_lib('stdlib')

---

local function load_module(filename)
   local module_cstr = ffi.new("char[?]", #filename+1, filename)
   local err = ffi.new("COREBool[1]")
   local m = coreir.lib.CORELoadModule(coreir.ctx, module_cstr, err)
   assert(err[0] == 0, "Failed to load module: " .. filename)
   return m
end
coreir.load_module = load_module

local function print_module(m)
   coreir.lib.COREPrintModule(m)
end
coreir.print_module = print_module

local function module_get_def(m)
   return coreir.lib.COREModuleGetDef(m)
end
coreir.module_get_def = module_get_def

-- local function module_def_get_instances(module_def)
--    local num_insts = ffi.new("unsigned int[1]")
--    local instances = coreir.lib.COREModuleDefGetInstances(module_def, num_insts)
--    return instances, num_insts[0]
-- end
-- coreir.module_def_get_instances = module_def_get_instances

-- local function get_inst_ref_name(inst)
--    return ffi.string(coreir.lib.COREGetInstRefName(inst))
-- end
-- coreir.get_inst_ref_name = get_inst_ref_name

-- local function get_io(direction)
--    return function(module)
-- 	  direction = first_to_upper(direction)
-- 	  local directed_module = coreir.lib.COREModuleGetDirectedModule(module)
-- 	  local num_io = ffi.new("int[1]")
-- 	  local io_ptr = coreir.lib["COREDirectedModuleGet" .. direction](directed_module, num_io)
-- 	  local ios = {}
-- 	  io.write(direction .. num_io[0] .. '\n')
-- 	  for i=0,num_io[0]-1 do
-- 		 local src_len = ffi.new("int[1]")
-- 		 local src = coreir.lib.COREDirectedConnectionGetSrc(io_ptr[i], src_len)
-- 		 for j=0,src_len[0]-1 do
-- 			io.write(ffi.string(src[j]))
-- 			if j ~= src_len[0]-1 then io.write('->') end
-- 		 end
-- 		 io.write(' => ')
-- 		 local snk_len = ffi.new("int[1]")
-- 		 local snk = coreir.lib.COREDirectedConnectionGetSnk(io_ptr[i], snk_len)
-- 		 for j=0,snk_len[0]-1 do
-- 			io.write(ffi.string(snk[j]))
-- 			if j ~= snk_len[0]-1 then io.write('->') end
-- 		 end
-- 		 io.write('\n')

-- 		 local derp = coreir.lib.COREDirectedModuleSel(directed_module, src, src_len[0])
-- 		 io.write("Src ")
-- 		 coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(derp))
-- 		 local herp = coreir.lib.COREDirectedModuleSel(directed_module, snk, snk_len[0])
-- 		 io.write("Snk ")
-- 		 coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(herp))

-- 		 ios[i] = io_ptr[i]
-- 		 -- ios[i] = ffi.new("COREDirectedConnection*", io_ptr[i])
-- 	  end
-- 	  return ios, num_io[0]
--    end
-- end
-- coreir.get_inputs  = get_io("inputs")
-- coreir.get_outputs = get_io("outputs")

function coreir.a()
   return 0
end
-- coreir.get_inputs = function(m) return {}, 0 end
   -- local directed_module = coreir.lib.COREModuleGetDirectedModule(module)
   -- local num_io = ffi.new("int[1]")
   -- local io_ptr = coreir.libCOREDirectedModuleGetInputs(directed_module, num_io)
   -- local ios = {}
   -- io.write(direction .. num_io[0] .. '\n')
   -- for i=0,num_io[0]-1 do
   -- 	  local src_len = ffi.new("int[1]")
   -- 	  local src = coreir.lib.COREDirectedConnectionGetSrc(io_ptr[i], src_len)
   -- 	  for j=0,src_len[0]-1 do
   -- 		 io.write(ffi.string(src[j]))
   -- 		 if j ~= src_len[0]-1 then io.write('->') end
   -- 	  end
   -- 	  io.write(' => ')
   -- 	  local snk_len = ffi.new("int[1]")
   -- 	  local snk = coreir.lib.COREDirectedConnectionGetSnk(io_ptr[i], snk_len)
   -- 	  for j=0,snk_len[0]-1 do
   -- 		 io.write(ffi.string(snk[j]))
   -- 		 if j ~= snk_len[0]-1 then io.write('->') end
   -- 	  end
   -- 	  io.write('\n')

   -- 	  local derp = coreir.lib.COREDirectedModuleSel(directed_module, src, src_len[0])
   -- 	  io.write("Src ")
   -- 	  coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(derp))
   -- 	  local herp = coreir.lib.COREDirectedModuleSel(directed_module, snk, snk_len[0])
   -- 	  io.write("Snk ")
   -- 	  coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(herp))

   -- 	  ios[i] = io_ptr[i]
   -- 	  -- ios[i] = ffi.new("COREDirectedConnection*", io_ptr[i])
   -- end
   -- return ios, num_io[0]
   -- return {},0
-- end

-- local function get_inst(module)
--    local directed_module = coreir.lib.COREModuleGetDirectedModule(module)
--    local num_inst = ffi.new("int[1]")
--    local inst_ptr = coreir.lib.COREDirectedModuleGetInstances(directed_module, num_inst)
--    local inst = {}
--    for i=0,num_inst[0]-1 do		 
--    	  inst[i] = inst_ptr[i]
--    end
--    return inst, num_inst[0]-1
-- end
-- coreir.get_inst = get_inst

-- local function get_inst_io(direction)
--    return function(instance)
-- 	  direction = first_to_upper(direction)
-- 	  local num_io = ffi.new("int[1]")
-- 	  local io_ptr = coreir.lib["COREDirectedInstanceGet" .. direction](instance, num_io)
-- 	  local ios = {}
-- 	  -- io.write(direction .. num_io[0] .. '\n')
-- 	  -- for i=0,num_io[0]-1 do
-- 	  -- 	 local src_len = ffi.new("int[1]")
-- 	  -- 	 local src = coreir.lib.COREDirectedConnectionGetSrc(io_ptr[i], src_len)
-- 	  -- 	 for j=0,src_len[0]-1 do
-- 	  -- 		io.write(ffi.string(src[j]))
-- 	  -- 		if j ~= src_len[0]-1 then io.write('->') end
-- 	  -- 	 end
-- 	  -- 	 io.write(' => ')
-- 	  -- 	 local snk_len = ffi.new("int[1]")
-- 	  -- 	 local snk = coreir.lib.COREDirectedConnectionGetSnk(io_ptr[i], snk_len)
-- 	  -- 	 for j=0,snk_len[0]-1 do
-- 	  -- 		io.write(ffi.string(snk[j]))
-- 	  -- 		if j ~= snk_len[0]-1 then io.write('->') end
-- 	  -- 	 end
-- 	  -- 	 io.write('\n')

-- 	  -- 	 local derp = coreir.lib.COREDirectedModuleSel(directed_module, src, src_len[0])
-- 	  -- 	 io.write("Src ")
-- 	  -- 	 coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(derp))
-- 	  -- 	 local herp = coreir.lib.COREDirectedModuleSel(directed_module, snk, snk_len[0])
-- 	  -- 	 io.write("Snk ")
-- 	  -- 	 coreir.lib.COREPrintType(coreir.lib.COREWireableGetType(herp))

-- 	  -- 	 ios[i] = io_ptr[i]
-- 	  -- end
-- 	  -- return ios, num_io[0]
-- 	  return {},0
--    end
-- end
-- coreir.get_inst_inputs  = get_inst_io("inputs")
-- -- coreir.get_inst_outputs = function(i) return {},0 end -- get_inst_io("outputs")

-- init()
-- coreir.stdlib = load_lib('stdlib')

return coreir
