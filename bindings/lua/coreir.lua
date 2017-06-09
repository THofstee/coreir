--- Lua bindings to CoreIR.
-- @module coreir
-- @todo change all arrays to be 1-based
-- @todo remove returning the length as a second parameter from functions
local coreir = {}

local ffi = require('ffi')

local header_path = './'
local lib_path = '../../lib/'

--- Makes the first character in a string uppercase.
-- @lfunction first_to_upper
-- @tparam string str input
-- @treturn string the new string
local function first_to_upper(str)
    return (str:gsub("^%l", string.upper))
end

--- Return the whole contents of a file as a string.
-- The file is assumed to not be in binary format.
-- @lfunction read_file
-- @tparam string file path to the file
-- @treturn string contents of file
local function read_file(file)
   local f = assert(io.open(file, "r"), "Could not open " .. file .. " for reading")
   local content = f:read("*a")
   f:close()
   return content
end

--- Writes the string to a file
-- @lfunction write_file
-- @tparam string file path to the file
-- @tparam string data contents to write
local function write_file(file, data)
   local f = assert(io.open(file, "w"), "Could not open " .. file .. " for writing")
   f:write(data)
   f:close()
end

--- Convert a cdata array into a (0-based) lua array.
-- @todo change this to return a 1-based array
-- @lfunction to_lua_arr
-- @tparam cdata ptr pointer to C array
-- @tparam int num_elems length of array
-- @tparam[opt] function(cdata) fun transformation to apply on cdata elements
-- @return a lua array containing the data from ptr
local function to_lua_arr(ptr, num_elems, fun)
   local arr = {}
   for i=0,num_elems-1 do
	  if fun == nil then
		 arr[i] = ptr[i]
	  else
		 arr[i] = fun(ptr[i])
	  end
   end
   return arr
end

--- Converts a lua string to a C string.
-- @lfunction to_c_str
-- @tparam string s
-- @treturn cdata<char*>
local function to_c_str(s)
   return ffi.new("char[?]", #s+1, s)
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
-- @lfunction init
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
   local module_cstr = to_c_str(filename)
   local err = ffi.new("COREBool[1]")
   local m = coreir.lib.CORELoadModule(coreir.ctx, module_cstr, err)
   assert(err[0] == 0, "Failed to load module: " .. filename)
   return m
end
coreir.load_module = load_module

local function save_module(m, filename)
   local module_cstr = to_c_str(filename)
   local err = ffi.new("COREBool[1]")
   coreir.lib.CORESaveModule(getmetatable(m).module, module_cstr, err)
   assert(err[0] == 0, "Failed to save module: " .. filename)
end
coreir.save_module = save_module

--- Prints a module to stdout.
-- @function print_module
-- @tparam module m
-- @return nothing
local function print_module(m)
   if (type(m) == 'table') then
	  coreir.lib.COREPrintModule(getmetatable(m).module)
   else
	  coreir.lib.COREPrintModule(m)
   end
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

--- Makes a function to get specific i/o from a module.
-- @lfunction get_io
-- @tparam string _direction one of {"inputs","outputs","connections"}
-- @treturn function(module) function that accepts a module and returns what was specified by the string
-- @see get_inputs
-- @see get_outputs
-- @see get_connections
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
coreir.get_inputs = get_io("inputs")

--- Gets the outputs from a module.
-- @function get_outputs
-- @tparam module m
-- @treturn {directed_connection,...},int array of directed_connections and length
coreir.get_outputs = get_io("outputs")

--- Gets the connections of a module.
-- @function get_connections
-- @tparam module m
-- @treturn {directed_connection,...},int array of directed_connections and length
coreir.get_connections = get_io("connections")

--- Gets the directed instances of a module.
-- @function get_dir_inst
-- @tparam module m
-- @treturn {directed_instance,...},int array of directed_instances and length
local function get_dir_inst(_module)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(_module)
   local num_inst = ffi.new("int[1]")
   local inst_ptr = coreir.lib.COREDirectedModuleGetInstances(directed_module, num_inst)

   return to_lua_arr(inst_ptr, num_inst[0]), num_inst[0]
end
coreir.get_dir_inst = get_dir_inst

--- Makes a function to get specific i/o from an instance.
-- @lfunction get_inst_io
-- @tparam string direction one of {"inputs","outputs"}
-- @treturn function(directed_instance) the requested function
-- @see get_io
-- @see get_inst_inputs
-- @see get_inst_outputs
local function get_inst_io(_direction)
   return function(_instance)
	  local direction = first_to_upper(_direction)
	  local num_io = ffi.new("int[1]")
	  local io_ptr = coreir.lib["COREDirectedInstanceGet" .. direction](_instance, num_io)

	  return to_lua_arr(io_ptr,num_io[0]), num_io[0]
   end
end

--- Gets the inputs of a directed_instance.
-- @function get_inst_inputs
-- @tparam directed_instance inst
-- @treturn {directed_connection,...},int array of directed_connections and length
coreir.get_inst_inputs = get_inst_io("inputs")

--- Gets the outputs of a directed_instance.
-- @function get_inst_outputs
-- @tparam directed_instance inst
-- @treturn {directed_connection,...},int array of directed_connections and length
coreir.get_inst_outputs = get_inst_io("outputs")

--- Parses a COREType* into a Lua table.
-- @function parse_type
-- @tparam COREType* t
-- @return Lua table describing the type.
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
	  -- @todo needs some way of walking the records in a type...
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

--- Returns the direction of a COREType*.
-- @function type_direction
-- @tparam COREType* t
-- @treturn string direction of the type
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

--- Gets the sink of a directed_connection.
-- @function get_snk
-- @tparam directed_connection d_c
-- @treturn {string,...},int selection path of the sink and length of path.
local function get_snk(d_c)
   local p_len = ffi.new("int[1]")
   local p_ptr = coreir.lib.COREDirectedConnectionGetSnk(d_c, p_len)
   return to_lua_arr(p_ptr,p_len[0],ffi.string),p_len[0]
end
coreir.get_snk = get_snk

--- Gets the source of a directed_connection.
-- @function get_src
-- @tparam directed_connection d_c
-- @treturn {string,...},int selection path of the source and length of path.
local function get_src(d_c)
   local p_len = ffi.new("int[1]")
   local p_ptr = coreir.lib.COREDirectedConnectionGetSrc(d_c, p_len)
   return to_lua_arr(p_ptr,p_len[0],ffi.string),p_len[0]
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
	  cstr_arr[0] = to_c_str(path)
	  return coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, 1)
   elseif type(path) == 'table' then
	  if path[0] == nil then -- 1-indexed
		 local cstr_arr = ffi.new("const char*[?]", #path)
		 for i,v in pairs(path) do
			cstr_arr[i-1] = to_c_str(v)
		 end
		 return coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, #path)
	  else -- 0-indexed
		 local count = 0
		 for _ in pairs(path) do
			count = count+1
		 end

		 local cstr_arr = ffi.new("const char*[?]", count)
		 for i=0,count-1 do
			cstr_arr[i] = to_c_str(path[i])
		 end

		 return coreir.lib.COREDirectedModuleSel(directed_module, cstr_arr, count)
	  end
   else
	  assert(false, "Incompatible path type provided to module_sel")
   end

end
coreir.module_sel = module_sel

--- Parses a module into a Lua table.
-- @todo this should really generate a table that is similar to what is created by the module construction functions below.
-- @function parse_module
-- @tparam module m
-- @return lua table describing the module
local function parse_module(m)
   local directed_module = coreir.lib.COREModuleGetDirectedModule(m)

   local representation = {}

   local dir_inst,num_d_inst = coreir.get_dir_inst(m)

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
   		 local p_arr,p_len = coreir.get_src(input)

		 local wireable = coreir.module_sel(m, {p_arr[0], p_arr[1]})
   		 local wireable_type = coreir.lib.COREFlip(coreir.lib.COREWireableGetType(wireable))

   		 representation[module_name].ports[ffi.string(p_arr[1])] = {}
   		 representation[module_name].ports[ffi.string(p_arr[1])].type = coreir.parse_type(wireable_type)
   		 representation[module_name].ports[ffi.string(p_arr[1])].direction = coreir.type_direction(wireable_type)
   	  end

   	  -- Parse module outputs
   	  local outputs,num_out = coreir.get_outputs(m)
   	  for i,output in next,outputs do
   		 local p_arr,p_len = coreir.get_snk(output)

		 local wireable = coreir.module_sel(m, {p_arr[0], p_arr[1]})
   		 local wireable_type = coreir.lib.COREFlip(coreir.lib.COREWireableGetType(wireable))
		 
   		 representation[module_name].ports[ffi.string(p_arr[1])] = {}
   		 representation[module_name].ports[ffi.string(p_arr[1])].type = coreir.parse_type(wireable_type)
   		 representation[module_name].ports[ffi.string(p_arr[1])].direction = coreir.type_direction(wireable_type)
   	  end
   end
   
   -- Parse instances
   representation[module_name].instances = {}
   for i=0,num_d_inst-1 do
	  local this = get_inst_name(dir_inst[i])
	  local this_wireable = get_inst_wireable(dir_inst[i])
	  local this_type = get_inst_type(dir_inst[i])
	  
	  representation[module_name].instances[this] = {}
	  representation[module_name].instances[this].wireable = this_wireable
	  representation[module_name].instances[this].instance = this_type

	  local ports = {}
	  
	  -- Parse inputs
	  local inputs,num_in = coreir.get_inst_inputs(dir_inst[i])
	  for i,input in next,inputs do
		 local p_arr,p_len = coreir.get_snk(input)

		 local this2 = p_arr[1]
		 local wireable = coreir.module_sel(m, {this, this2})
		 local wireable_type = coreir.lib.COREWireableGetType(wireable)   

		 ports[this2] = {}
		 ports[this2].type = coreir.parse_type(wireable_type)
		 ports[this2].direction = coreir.type_direction(wireable_type)
	  end

	  -- Parse outputs
	  local outputs,num_out = coreir.get_inst_outputs(dir_inst[i])
	  for i,output in next,outputs do
		 local p_arr,p_len = coreir.get_src(output)

		 local this2 = p_arr[1]
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
   local connections = {}
   
   local cns,num_connections = coreir.get_connections(m)
   for i,connection in next,cns do
	  local src_arr,src_len = coreir.get_src(connection)
	  local snk_arr,snk_len = coreir.get_snk(connection)

	  connections[i] = {}

	  connections[i].src = {}
	  connections[i].src.path = src_arr
	  connections[i].src.wireable = coreir.module_sel(m, src_arr)

	  connections[i].snk = {}
	  connections[i].snk.path = snk_arr
	  connections[i].snk.wireable = coreir.module_sel(m, snk_arr)
   end

   representation[module_name].connections = connections

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

local function bit_in()
   return coreir.lib.COREBitIn(coreir.ctx)
end
coreir.bit_in = bit_in()

local function bit_out()
   return coreir.lib.COREBit(coreir.ctx)
end
coreir.bit_out = bit_out()

--- Creates a COREType array of provided type.
-- @function array
-- @tparam COREType* t
-- @tparam int n length of array
-- @treturn COREType*
local function array(t, n)
   return coreir.lib.COREArray(coreir.ctx, n, t)
end
coreir.array = array

--- Creates a record type from provided table.
-- Accepts a table mapping strings to COREType*.
-- The created record type will be an equivalently named COREType*.
-- @function record
-- @tparam {[string]=COREType*,...} t
-- @treturn COREType*
local function record(t)
   local len = 0
   for _ in pairs(t) do
	  len = len+1
   end
   
   local keys = ffi.new("char*[?]", len)
   local vals = ffi.new("COREType*[?]", len)
   local idx = 0
   for k,v in pairs(t) do
	  keys[idx] = to_c_str(k)
	  vals[idx] = v
	  idx = idx+1
   end
   local params = coreir.lib.CORENewMap(coreir.ctx, keys, vals, len, ffi.new("COREMapKind", "STR2TYPE_ORDEREDMAP"))

   return coreir.lib.CORERecord(coreir.ctx, params)
end
coreir.record = record

--- Creates a module
-- This function creates a module given a name and type signature.
-- The type signature is assumed to be the interface of the module.
-- This function also creates and associates a module_def to the created module.
-- The names specified in the type signature can be used to index the returned module to access the wireables directly.
-- @todo This should really be a class that it returns, with a connect method, etc.
-- @todo Try to figure out a different way than requiring all the arguments, maybe using metatables or something else to figure out the name? Or a _name entry in the table? Using underscored entries means that record parsing above needs to change too.
-- @function module_from
-- @tparam string name
-- @tparam {[string]=COREType*,...} t type signature of the module
-- @tparam[opt=global] ns namespace to put the created module
-- @return an enhanced module to be used with other library functions
local function module_from(name, t, ns)
   local namespace = ns or coreir.global
   local module_name = to_c_str(name)
   local module_type = record(t)
   local config_params = nil

   -- Create the module
   local m = coreir.lib.CORENewModule(namespace, module_name, module_type, config_params)

   -- Set up some metadata and create a module_def
   local metadata = {}
   local res = {}
   setmetatable(res, metadata)
   metadata.name = name
   metadata.module = m
   metadata.def = coreir.lib.COREModuleNewDef(metadata.module)
   coreir.lib.COREModuleSetDef(metadata.module, metadata.def)

   -- Add the wireables to the module
   -- metadata.type = parse_type(module_type)
   metadata.type = t
   metadata.interface = coreir.lib.COREModuleDefGetInterface(metadata.def)
   for k,_ in pairs(t) do
	  res[k] = coreir.lib.COREWireableSelect(metadata.interface, to_c_str(k))
   end

   metadata.instances = {}
   metadata.connections = {}

   return res
end
coreir.module_from = module_from

--- Creates a primitive module
-- This function creates a module given a name and type signature.
-- The type signature is assumed to be the interface of the module.
-- This function does not create a module_def.
-- You should not associate a module_def to these modules.
-- The names specified in the type signature can be used to index the returned module to access the wireables directly.
-- @todo This should really be a class that it returns, with a connect method, etc.
-- @todo Try to figure out a different way than requiring all the arguments, maybe using metatables or something else to figure out the name? Or a _name entry in the table? Using underscored entries means that record parsing above needs to change too.
-- @function module_from
-- @tparam string name
-- @tparam {[string]=COREType*,...} t type signature of the module
-- @tparam[opt=global] ns namespace to put the created module
-- @return an enhanced module to be used with other library functions
local function primitive_from(name, t, ns)
   local namespace = ns or coreir.global
   local module_name = to_c_str(name)
   local module_type = record(t)
   local config_params = nil

   -- Create the module
   local m = coreir.lib.CORENewModule(namespace, module_name, module_type, config_params)

   -- Set up some metadata and create a module_def
   local metadata = {}
   local res = {}
   setmetatable(res, metadata)
   metadata.name = name
   metadata.module = m

   -- Add the wireables to the module
   -- metadata.type = parse_type(module_type)
   metadata.type = t
   metadata.interface = coreir.lib.COREModuleDefGetInterface(metadata.def)
   for k,_ in pairs(t) do
	  res[k] = coreir.lib.COREWireableSelect(metadata.interface, to_c_str(k))
   end

   return res
end
coreir.primitive_from = primitive_from

--- Generates a unique name given a string
-- @lfunction unique_name
local id = 0
local function unique_name(s)
   id = id + 1
   return s .. id
end

--- Adds an instance of a module to the specified module_def
-- @todo this really should probably be refactored into a class
-- @function add_instance
-- @tparam module m enhanced lua module to add the instance to
-- @tparam module inst an enhanced lua module of the instance to be added
-- @tparam[opt] args args arguments to be supplied to the instance
-- @tparam[opt] string inst_name if not supplied, a unique name will be generated
local function add_instance(m, inst, args, inst_name)
   local m_meta = getmetatable(m)
   local inst_meta = getmetatable(inst)
   
   local name = inst_name or unique_name(inst_meta.name)
   local args = args or {}

   local arg_map = coreir.lib.CORENewMap(coreir.ctx, nil, nil, 0, ffi.new("COREMapKind", "STR2ARG_MAP"))
   local module_inst = coreir.lib.COREModuleDefAddModuleInstance(m_meta.def, to_c_str(name), inst_meta.module, arg_map)

   -- @todo it would be nice if you could do both module.instance and module.instance["in"] and have module.instance return the instance wireable, and module.instance["in"] return the wireable of instance->in...
   -- @todo i think the latter is more important, i'm not sure when you would want to directly access the instance wireable, and if we wanted to wire two instances together we could analyze the two tables we get and connect the wireables of the instance connections...?
   -- @todo aha! i can start to do something more like this by putting a metatable in the instance, i think. this should help to some degree.
   m[name] = {}
   for k,_ in pairs(inst_meta.type) do
	  m[name][k] = coreir.lib.COREWireableSelect(module_inst, to_c_str(k))
   end
   
   m_meta.instances[name] = {}
   m_meta.instances[name].module = inst_meta.name
   m_meta.instances[name].wireable = module_inst
   m_meta.instances[name].args = args
end
coreir.add_instance = add_instance

--- Connects a and b inside a module.
-- @todo yeah this really should be a class function, m.connect(a, b)
-- @todo i can do connect(m.in, m.out), but later when i want to do something like get_connections(m.in), it will just return a COREWireable*, instead of something that also can tell you "m.out"... need some way of going backwards from wireables i guess...
-- @todo instead of a list of pairs, maybe this should be a map of connection -> list(connections), and then duplicated for both connections
-- @function connect
-- @tparam module m
-- @tparam COREWireable* a
-- @tparam COREWireable* b
local function connect(m, a, b)
   local m_meta = getmetatable(m)
   coreir.lib.COREModuleDefConnect(m_meta.def, a, b)
   m_meta.connections[#m_meta.connections+1] = { a, b}
end
coreir.connect = connect

local inspect = require 'inspect'

--- Some options to pass in to the lua inspect library
-- @table inspect_options
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
		 if type(i) ~= 'number' then return item end
		 newitem[i+1] = v
	  end
	  return newitem
   else
	  return item
   end
end
coreir.inspect_options = inspect_options

return coreir
