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
   return ffi.string(ffi.gc(coreir_lib.COREGetInstRefName(inst), ffi.C.free))
end

local test_ctx = ffi.gc(coreir_lib.CORENewContext(), coreir_lib.COREDeleteContext)
local ns_global = coreir_lib.COREGetGlobal(test_ctx)

-- local module_str = "_simple.json"
local module_str = "_add4Gen.json"

local module_cstr = ffi.new("char[?]", #module_str)
ffi.copy(module_cstr, module_str)

local stdlib = coreir_stdlib.CORELoadLibrary_stdlib(test_ctx)
local test_gen = coreir_lib.CORELoadModule(test_ctx, module_cstr, err)
coreir_lib.COREPrintModule(test_gen)

local test_gen_defs = coreir_lib.COREModuleGetDef(test_gen)

-- TODO: Remove
ffi.cdef("const char* ICEPTGetInstRefName(COREInstance* iref);")
local coreir_intercept = ffi.load('./' .. 'intercept.so')

local num_insts = ffi.new("int[1]")
local test_gen_insts = coreir_lib.COREModuleDefGetInstances(test_gen_defs, num_insts)

for i=0,num_insts[0]-1 do
   local inst = test_gen_insts[i]
   io.write(get_inst_ref_name(inst) .. '\n')
end

local num_in  = ffi.new("int[1]")
local num_out = ffi.new("int[1]")

return coreir
