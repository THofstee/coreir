--- Lua bindings to CoreIR.
-- @module coreir
local coreir = {}

local ffi = require('ffi')

local header_path = './'
local lib_path = '../../lib/'

--- Makes the first character in a string uppercase.
-- @tparam string str input
-- @treturn string the new string
local function first_to_upper(str)
    return (str:gsub("^%l", string.upper))
end

--- Return the whole contents of a file as a string.
-- The file is assumed to not be in binary format.
-- @tparam string file path to the file
-- @treturn string contents of file
local function read_file(file)
   local f = assert(io.open(file), "Could not open " .. file .. " for reading")
   local content = f:read("*a")
   f:close()
   return content
end

--- Convert a cdata array into a lua array.
-- @tparam cdata ptr pointer to C array
-- @tparam int num_elems length of array
-- @return a lua array containing the data from ptr
local function to_lua_arr(ptr, num_elems)
   local arr = {}
   for i=0,num_elems-1 do
	  arr[i] = ptr[i]
   end
   return arr
end

---

--- Loads a CoreIR library.
-- The loaded library can then be accessed as 'coreir.lib'
-- @function load_lib
-- @tparam string lib library name
-- @return nothing
local function load_lib(lib)
   ffi.cdef("CORENamespace* CORELoadLibrary_" .. lib .. "(COREContext* c);")
   coreir["__" .. lib] = ffi.load(lib_path .. 'libcoreir-' .. lib .. '.so')
   coreir[lib] = coreir["__" .. lib]["CORELoadLibrary_" .. lib](coreir.ctx)
end
coreir.load_lib = load_lib

--- Initializes the coreir module.
-- This function is called internally to initialize the coreir module by
-- loading the libcoreir-c shared library, creating a context, and a
-- global namespace. This function also loads coreir-stdlib.
local function init()
   ffi.cdef(read_file(header_path .. 'coreir-single.h'))
   coreir.lib = ffi.load(lib_path .. 'libcoreir-c.so')

   coreir.ctx = coreir.lib.CORENewContext()
   coreir.global = coreir.lib.COREGetGlobal(coreir.ctx)

   load_lib('stdlib')
end
init()

---

--- Loads a module.
-- Loads a specified json file and returns a handle to the CoreIR module.
-- @function load_module
-- @tparam string filename module file
-- @treturn module
local function load_module(filename)
   local module_cstr = ffi.new("char[?]", #filename+1, filename)
   local err = ffi.new("COREBool[1]")
   local m = coreir.lib.CORELoadModule(coreir.ctx, module_cstr, err)
   assert(err[0] == 0, "Failed to load module: " .. filename)
   return m
end
coreir.load_module = load_module

--- Prints a module to stdout.
-- @function print_module
-- @tparam module m
-- @return nothing
local function print_module(m)
   coreir.lib.COREPrintModule(m)
end
coreir.print_module = print_module

--- Gets the definition of a module.
-- @function module_get_def
-- @tparam module m
-- @treturn module_def
local function module_get_def(m)
   return coreir.lib.COREModuleGetDef(m)
end
coreir.module_get_def = module_get_def

--- Gets the instances of a module definition.
-- @function module_def_get_instances
-- @tparam module_def module_def
-- @treturn {instance,...},int a Lua array of instances and the length
local function module_def_get_instances(module_def)
   local num_insts = ffi.new("unsigned int[1]")
   local instances = coreir.lib.COREModuleDefGetInstances(module_def, num_insts)
   return to_lua_arr(instances, num_insts[0]), num_insts[0]
end
coreir.module_def_get_instances = module_def_get_instances

--- Gets the the name of an inst_ref for an instance.
-- @function get_inst_ref_name
-- @tparam instance inst
-- @treturn string the inst_ref name
local function get_inst_ref_name(inst)
   return ffi.string(coreir.lib.COREGetInstRefName(inst))
end
coreir.get_inst_ref_name = get_inst_ref_name

local function get_io(_direction)
   return function(_module)
	  local direction = first_to_upper(_direction)
	  local directed_module = coreir.lib.COREModuleGetDirectedModule(_module)
	  local num_io = ffi.new("int[1]")
	  local io_ptr = coreir.lib["COREDirectedModuleGet" .. direction](directed_module, num_io)

	  return to_lua_arr(io_ptr,num_io[0]), num_io[0]
   end
end

--- Gets the inputs to a module.
-- @function get_inputs
-- @tparam module m
-- @treturn {directed_connection,...},int array of directed_connections and length
coreir.get_inputs  = get_io("inputs")
coreir.get_outputs = get_io("outputs")
coreir.get_connections = get_io("connections")

local function get_dir_inst(_module)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(_module)
   local num_inst = ffi.new("int[1]")
   local inst_ptr = coreir.lib.COREDirectedModuleGetInstances(directed_module, num_inst)

   return to_lua_arr(inst_ptr, num_inst[0]), num_inst[0]
end
coreir.get_dir_inst = get_dir_inst

local function get_inst_io(_direction)
   return function(_instance)
	  local direction = first_to_upper(_direction)
	  local num_io = ffi.new("int[1]")
	  local io_ptr = coreir.lib["COREDirectedInstanceGet" .. direction](_instance, num_io)

	  return to_lua_arr(io_ptr,num_io[0]), num_io[0]
   end
end
coreir.get_inst_inputs  = get_inst_io("inputs")
coreir.get_inst_outputs = get_inst_io("outputs")

local function parse_type(t)
   assert(type(t) == "cdata", "parse_type requires a COREType* as input")
   local t_kind = coreir.lib.COREGetTypeKind(t)

   local parsed_type = {}
   if     t_kind == ffi.new("CORETypeKind", "COREBitTypeKind") then
	  parsed_type.size = 1
	  parsed_type.type = "bit_out"
   elseif t_kind == ffi.new("CORETypeKind", "COREBitInTypeKind") then
	  parsed_type.size = 1
	  parsed_type.type = "bit_in"
   elseif t_kind == ffi.new("CORETypeKind", "COREArrayTypeKind") then
	  parsed_type.size = coreir.lib.COREArrayTypeGetLen(t)
	  parsed_type.type = parse_type(coreir.lib.COREArrayTypeGetElemType(t))
   elseif t_kind == ffi.new("CORETypeKind", "CORERecordTypeKind") then
	  assert(false, "Not Implemented")
   elseif t_kind == ffi.new("CORETypeKind", "CORENamedTypeKind") then
	  assert(false, "Not Implemented")
   elseif t_kind == ffi.new("CORETypeKind", "COREAnyTypeKind") then
	  assert(false, "Not Implemented")
   else   assert(false, "Invalid Type")
   end

   return parsed_type
end
coreir.parse_type = parse_type

local function type_direction(t)
   assert(type(t) == "cdata", "type_direction requires a COREType* as input")
   local t_kind = coreir.lib.COREGetTypeKind(t)

   local parsed_type = {}
   if     t_kind == ffi.new("CORETypeKind", "COREBitTypeKind") then
	  return "out"
   elseif t_kind == ffi.new("CORETypeKind", "COREBitInTypeKind") then
	  return "in"
   elseif t_kind == ffi.new("CORETypeKind", "COREArrayTypeKind") then
	  return type_direction(coreir.lib.COREArrayTypeGetElemType(t))
   elseif t_kind == ffi.new("CORETypeKind", "CORERecordTypeKind") then
	  assert(false, "Not Implemented")
   elseif t_kind == ffi.new("CORETypeKind", "CORENamedTypeKind") then
	  assert(false, "Not Implemented")
   elseif t_kind == ffi.new("CORETypeKind", "COREAnyTypeKind") then
	  assert(false, "Not Implemented")
   else   assert(false, "Invalid Type")
   end
end
coreir.type_direction = type_direction

local function get_snk(d_c)
   local p_len = ffi.new("int[1]")
   local p_ptr = coreir.lib.COREDirectedConnectionGetSnk(d_c, p_len)
   return p_ptr,p_len[0]
end
coreir.get_snk = get_snk

local function get_src(d_c)
   local p_len = ffi.new("int[1]")
   local p_ptr = coreir.lib.COREDirectedConnectionGetSrc(d_c, p_len)
   return p_ptr,p_len[0]
end
coreir.get_src = get_src

--- Selects a wireable in a module given path.
-- @function module_sel
-- @tparam module m
-- @tparam string|{string,...} path wireable selection strings
-- @todo rewrite using COREModuleDefSelect and COREWireableSelect?
local function module_sel(m, path)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(m)

   if type(path) == 'string' then
	  local cstr_arr = ffi.new("const char*[1]")
	  cstr_arr[0] = ffi.new("char[?]", #path+1, path)
	  return coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, 1)
   elseif type(path) == 'table' then
	  local cstr_arr = ffi.new("const char*[?]", #path)
	  for i,v in ipairs(path) do
		 cstr_arr[i-1] = ffi.new("char[?]", #v+1, v)
	  end
	  return coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, #path)
   else
	  assert(false, "Incompatible path type provided to module_sel")
   end

end
coreir.module_sel = module_sel

local function parse_module(m)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(m)

   local representation = {}

   local dir_inst,num_d_inst = coreir.get_dir_inst(m)
   for i=0,num_d_inst-1 do
	  coreir.get_inst_inputs(dir_inst[i])
	  coreir.get_inst_outputs(dir_inst[i])
	  io.write(i .. '\n')
   end

   -- Takes in a directed instance and returns a string containing the name
   local function get_inst_name(inst)
	  local in_ptr,num_in = coreir.get_inst_inputs(inst)
	  local p_ptr,p_len = coreir.get_snk(in_ptr[0])
	  return ffi.string(p_ptr[0])	  
   end

   -- Takes in a directed instance and returns the COREWireable*
   local function get_inst_wireable(inst)
	  return coreir.module_sel(m, get_inst_name(inst))
   end

   -- Takes in a directed instance and returns a string containing the type
   local function get_inst_type(inst)
	  return coreir.get_inst_ref_name(get_inst_wireable(inst))
   end

   -- Idea: The get_inputs and get_inst_inputs both seem to work decently
   -- We can use the selection path in order to figure out how everything is connected
   -- The first element in the selection path is the module name, so we can get self
   -- Then from there, we do something to get inst ref name
   -- Not sure if we should use the inst inputs or the module inputs
   -- Actually, we need to use both. The module for top level module, then inst internally
   -- Anyhow, from there we can get the wireable from module_sel or equivalent

   -- Parse module
   local module_name = "self"
   representation[module_name] = {}

   local cstr_arr = ffi.new("const char*[1]")

   do
   	  representation[module_name].ports = {}

	  -- Parse module inputs
   	  local inputs,num_in = coreir.get_inputs(m)
   	  for i,input in next,inputs do
   		 local p_ptr,p_len = coreir.get_src(input)

   		 local this = ffi.string(p_ptr[0])
   		 local this2 = ffi.string(p_ptr[1])
		 local wireable = coreir.module_sel(m, {this, this2})
   		 local wireable_type = coreir.lib.COREFlip(coreir.lib.COREWireableGetType(wireable))

   		 representation[module_name].ports[ffi.string(p_ptr[1])] = {}
   		 representation[module_name].ports[ffi.string(p_ptr[1])].type = coreir.parse_type(wireable_type)
   		 representation[module_name].ports[ffi.string(p_ptr[1])].direction = coreir.type_direction(wireable_type)
   	  end

   	  -- Parse module outputs
   	  local outputs,num_out = coreir.get_outputs(m)
   	  for i,output in next,outputs do
   		 local p_ptr,p_len = coreir.get_snk(output)

   		 local this = ffi.string(p_ptr[0])
   		 local this2 = ffi.string(p_ptr[1])
		 local wireable = coreir.module_sel(m, {this,this2})
   		 local wireable_type = coreir.lib.COREFlip(coreir.lib.COREWireableGetType(wireable))
		 
   		 representation[module_name].ports[ffi.string(p_ptr[1])] = {}
   		 representation[module_name].ports[ffi.string(p_ptr[1])].type = coreir.parse_type(wireable_type)
   		 representation[module_name].ports[ffi.string(p_ptr[1])].direction = coreir.type_direction(wireable_type)
   	  end
   end
   
   -- Parse instances
   representation[module_name].instances = {}
   for i=0,num_d_inst-1 do
	  local this = get_inst_name(dir_inst[i])
	  local this_wireable = get_inst_wireable(dir_inst[i])
	  local this_type = get_inst_type(dir_inst[i])
	  
	  io.write(this .. ' : ' .. this_type .. '\n')
	  representation[module_name].instances[this] = {}
	  representation[module_name].instances[this].wireable = this_wireable
	  representation[module_name].instances[this].instance = this_type

	  representation[module_name].instances[this].ports = {}

	  local ports = {}
	  
	  -- Parse inputs
	  local inputs,num_in = coreir.get_inst_inputs(dir_inst[i])
	  for i,input in next,inputs do
		 local p_ptr,p_len = coreir.get_snk(input)

		 local this2 = ffi.string(p_ptr[1])
		 local wireable = coreir.module_sel(m, {this, this2})
		 local wireable_type = coreir.lib.COREWireableGetType(wireable)   

		 ports[this2] = {}
		 ports[this2].type = coreir.parse_type(wireable_type)
		 ports[this2].direction = coreir.type_direction(wireable_type)
	  end

	  -- Parse outputs
	  local outputs,num_out = coreir.get_inst_outputs(dir_inst[i])
	  for i,output in next,outputs do
		 local p_ptr,p_len = coreir.get_src(output)

		 local this2 = ffi.string(p_ptr[1])
		 local wireable = coreir.module_sel(m, {this, this2})
		 local wireable_type = coreir.lib.COREWireableGetType(wireable)   

		 ports[this2] = {}
		 ports[this2].type = coreir.parse_type(wireable_type)
		 ports[this2].direction = coreir.type_direction(wireable_type)
	  end

	  representation[module_name].instances[this].ports = ports
   end

   -- Because we parse the inputs and outputs as individual connections
   -- we also need to grab all the connections. The previous two loops
   -- can't handle the case where one input is connected to multiple
   -- outputs, so we need to do that here instead.
   local cns,num_connections = coreir.get_connections(m)
   print(num_connections)

   -- I can actually also just use the raw cdata as indices to the table
   -- Need to consider the benefits/downsides of doing it each way...
   -- Benefits:
   --   We can just pass around cdata objects everywhere
   --   No need to get strings etc for every single cdata object
   -- Downsides:
   --   Becomes very difficult to serialize, would need to make a serializer
   --   Non readable without serializer
   --   Difficult to debug user code without serializer
   --   There might be a case where 2 different pointers are actually intended to be the same object.
   --   Difficult to make a serializer without type info, and everything in CoreIR is a Wireable* so...
   representation[m] = {}

   return representation
end
coreir.parse_module = parse_module

return coreir
