function read_file(file)
    local f = io.open(file, "rb")
    local content = f:read("*all")
    f:close()
    return content
end

local header_path = './'
local lib_path = '../../lib/'

io.write(package.path .. '\n')
io.write(package.cpath .. '\n')

ffi = require('ffi') -- luajit ffi
ffi.cdef(read_file(header_path .. 'coreir-single.h'))
coreir = ffi.load(lib_path .. 'libcoreir-c.so')

test_gen = read_file('_add4Gen.json')
