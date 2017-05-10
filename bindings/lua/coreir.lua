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
coreir_lib = init()
coreir_stdlib = load_lib('stdlib')

local test_ctx = coreir_lib.CORENewContext()
local module_str = "_add4Gen.json"
local module_cstr = ffi.new("char[?]", #module_str)
ffi.copy(module_cstr, module_str)

local stdlib = coreir_stdlib.CORELoadLibrary_stdlib(test_ctx)
local test_gen = coreir_lib.CORELoadModule(test_ctx, module_cstr, err)

return coreir