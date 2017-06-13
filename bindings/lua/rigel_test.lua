package.path = "/home/hofstee/rigel/?.lua;/home/hofstee/rigel/src/?.lua;/home/hofstee/rigel/examples/?.lua;" .. package.path

local ffi = require 'ffi'
local inspect = require 'inspect'
local coreir = require 'coreir'
local rs = require 'rigelSimple'

--- Test 3 -- a hardcoded convolution module and generating rigel code
-- Construct the convolve unit in CoreIR
local bpp = 8
local mat_w = 4
local mat_h = 4

local linebuffer_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.bit_in, bpp),
   ["out"] = coreir.array(coreir.array(coreir.array(coreir.bit_out, bpp), mat_w), mat_h),
   -- @todo use generators and make the linebuffer output every single value, and then just rely on the passes to eliminate the unconnected outputs?
}

local conv_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.array(coreir.array(coreir.bit_in, bpp), mat_w), mat_h),
   ["out"] = coreir.array(coreir.bit_out, bpp),
}

local const_seq_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["out"] = coreir.array(coreir.array(coreir.array(coreir.bit_out, bpp), mat_w), mat_h),
}

local mult_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in_1"] = coreir.array(coreir.array(coreir.array(coreir.bit_in, bpp), mat_w), mat_h),
   ["in_2"] = coreir.array(coreir.array(coreir.array(coreir.bit_in, bpp), mat_w), mat_h),
   ["out"] = coreir.array(coreir.bit_out, bpp),
}

local stream_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.bit_in, bpp),
   ["out"] = coreir.array(coreir.bit_out, bpp),
}

local mult = coreir.primitive_from("mult", mult_t)
local const_seq = coreir.primitive_from("const_seq", const_seq_t)
local linebuf = coreir.primitive_from("line_buffer", linebuffer_t)
local conv = coreir.module_from("conv", conv_t)
local stream = coreir.module_from("stream", stream_t)

-- Create a small dictionary to look up unknown module contents
-- @todo this should probably be in coreir.lua somewhere
local module_dict = {}
module_dict.linebuf = linebuf
module_dict.conv = conv
module_dict.stream = stream

-- @todo definitely need the generator available on C api...
local linebuf_args = {
   ["w"] = mat_w,
   ["h"] = mat_h,
}

local conv_args = {
   ["weights"] = {
	  { 4, 14, 14,  4},
	  {14, 32, 32, 14},
	  {14, 32, 32, 14},
	  { 4, 14, 14,  4},
   },
}

local const_seq_args = {
   ["weights"] = conv_args.weights,
   ["w"] = linebuf_args.w,
   ["h"] = linebuf_args.h,
}

local mult_args = linebuf_args

-- Flatten an n*m table into a 1*(n*m) table
local function flatten_mat(m)
   local idx = 0
   local res = {}
   
   for h,row in ipairs(m) do
	  for w,elem in ipairs(row) do
		 idx = idx + 1
		 res[idx] = elem
	  end
   end
   
   return res
end

-- @todo also need a way to run generators in the C api...
coreir.add_instance(conv, const_seq, const_seq_args, "const_seq")
coreir.add_instance(conv, mult, mult_args, "mult")
coreir.connect(conv, conv["clk"], conv.const_seq["clk"])
coreir.connect(conv, conv["rst_b"], conv.const_seq["rst_b"])
coreir.connect(conv, conv["clk"], conv.mult["clk"])
coreir.connect(conv, conv["rst_b"], conv.mult["rst_b"])
coreir.connect(conv, conv["in"], conv.mult["in_1"])
coreir.connect(conv, conv.const_seq["out"], conv.mult["in_2"])
coreir.connect(conv, conv.mult["out"], conv["out"])

-- Make the top stream module
coreir.add_instance(stream, linebuf, linebuf_args, "line_buffer")
coreir.add_instance(stream, conv, conv_args, "conv")

coreir.connect(stream, stream["clk"], stream.line_buffer["clk"])
coreir.connect(stream, stream["rst_b"], stream.line_buffer["rst_b"])
coreir.connect(stream, stream["clk"], stream.conv["clk"])
coreir.connect(stream, stream["rst_b"], stream.conv["rst_b"])

coreir.connect(stream, stream["in"], stream.line_buffer["in"])

coreir.connect(stream, stream.line_buffer["out"], stream.conv["in"])

coreir.connect(stream, stream.conv["out"], stream["out"])

-- coreir.print_module(stream)
-- print(coreir.inspect(stream))

local err = ffi.new("COREBool[1]")
coreir.lib.COREFlatten(coreir.ctx, getmetatable(stream).module, err)

coreir.print_module(stream)
print(coreir.get_inst_ref_name(stream.conv)) -- new feature!
print(coreir.inspect(stream))

coreir.save_module(stream, "_conv.json")
local stream_dup = coreir.load_module("_conv.json")
-- coreir.print_module(stream_dup)
-- print(coreir.inspect(coreir.parse_module(stream_dup)))

local _created = coreir.inspect(coreir.parse_module(getmetatable(stream).module))
local _loaded = coreir.inspect(coreir.parse_module(stream_dup))
if _created ~= _loaded then
   local function write_file(file, data)
	  local f = assert(io.open(file, "w"), "Could not open " .. file .. " for writing")
	  f:write(data)
	  f:close()
   end

   print("Parsing generated module differs from parsing loaded module.")
   write_file("_created.json", _created)
   write_file("_loaded.json", _loaded)
end

-- @todo flesh out the conv to mimic rigel
-- @todo flesh out other rigel primitives
-- @todo use analysis on the table to generate the rigel module

-- Analyze the module and generate Rigel module
local rate = 1/4

local inSize = {1920, 1080}
local padSize = {1920+16, 1080+3}

local input = rs.input(rs.HS(rs.array(rs.uint8, bpp/8)))
local padded = rs.connect{
   input = input,
   toModule = rs.HS(rs.modules.padSeq{
					   type = rs.uint8,
					   V = 1,
					   size = inSize,
					   pad = {8, 8, 2, 1},
					   value = 0
   })
}

local function analyze(i)
   local m_type = i.module

   if m_type == "line_buffer" then
	  return rs.HS(rs.modules.linebuffer{
					  type = rs.uint8,
					  V = 1, -- ???
					  size = padSize, -- @todo this needs to change
					  stencil = {-(i.args.w-1), 0, -(i.args.h-1), 0}
	  })
   elseif m_type == "const_seq" then
	  return rs.modules.constSeq{
		 type = rs.array2d(rs.uint8, i.args.w, i.args.h),
		 P = rate, -- @todo
		 value = flatten_mat(i.args.mat)
	  }
   end
end

local stenciled = rs.connect{
   input = padded,
   toModule = analyze(getmetatable(stream).instances.line_buffer)
}

local partialStencil = rs.connect{
   input = stenciled,
   toModule = rs.HS(rs.modules.devectorize{
					   type = rs.uint8,
					   H = 4,
					   V = 1/rate
   })
}

function makePartialConvolve()
  local convolveInput = rs.input( rs.array2d(rs.uint8,4*rate,4) )

  local filterCoeff = rs.connect{ input=nil, toModule =
    rs.modules.constSeq{ type=rs.array2d(rs.uint8,4,4), P=rate, value = 
      { 4, 14, 14,  4,
        14, 32, 32, 14,
        14, 32, 32, 14,
        4, 14, 14,  4} } }
                                   
  local merged = rs.connect{ input = rs.concat{ convolveInput, filterCoeff }, 
    toModule = rs.modules.SoAtoAoS{ type={rs.uint8,rs.uint8}, size={4*rate,4} } }
  
  local partials = rs.connect{ input = merged, toModule =
    rs.modules.map{ fn = rs.modules.mult{ inType = rs.uint8, outType = rs.uint32}, 
                   size={4*rate,4} } }
  
  local sum = rs.connect{ input = partials, toModule =
    rs.modules.reduce{ fn = rs.modules.sum{ inType = rs.uint32, outType = rs.uint32 }, 
                      size={4*rate,4} } }
  
  return rs.defineModule{ input = convolveInput, output = sum }
end


local partialConvolved = rs.connect{
   input = partialStencil,
   toModule = rs.HS(makePartialConvolve())
}

local summedPartials = rs.connect{
   input = partialConvolved,
   toModule = rs.HS(rs.modules.reduceSeq{
					   fn = rs.modules.sumAsync{
									 inType = rs.uint32,
									 outType = rs.uint32
					   },
					   V = 1/rate
   })
}


local convolved = rs.connect{
   input = summedPartials,
   toModule = rs.HS(rs.modules.shiftAndCast{
					   inType = rs.uint32,
					   outType = rs.uint8,
					   shift = 8
   })
}

local output = rs.connect{
   input = convolved,
   toModule = rs.HS(rs.modules.cropSeq{
					   type = rs.uint8,
					   V = 1,
					   size = padSize,
					   crop = {9, 7, 3, 0}
   })
}
	  
local conv_func = rs.defineModule{ input = input, output = output}

rs.harness{
   fn = conv_func,
   inFile = "1080p.raw", inSize = inSize,
   outFile = "convolve_slow", outSize = inSize,
}

--- TEST

local namespace = coreir.global
local module_name = ffi.new("char[?]", #"aeiou"+1, "aeiou")
local module_type = coreir.bit_in

local param_str = ffi.new("char*[1]")
param_str[0] = ffi.new("char[?]", #"test"+1, "test")

local param_types = ffi.new("COREParam[1]")
param_types[0] = ffi.new("COREParam", "COREIntParam")

local config_params = coreir.lib.CORENewMap(coreir.ctx, param_str, param_types, 1, ffi.new("COREMapKind", "STR2PARAM_MAP"))

local m = coreir.lib.CORENewModule(namespace, module_name, module_type, config_params)

local m_def = coreir.lib.COREModuleNewDef(m)
coreir.lib.COREModuleSetDef(m, m_def)

local arg_str = ffi.new("char*[1]")
arg_str[0] = ffi.new("char[?]", #"test"+1, "test")

local arg_val = ffi.new("COREArg*[1]")
arg_val[0] = coreir.lib.COREArgInt(coreir.ctx, 42)

local arg_map = coreir.lib.CORENewMap(coreir.ctx, arg_str, arg_val, 1, ffi.new("COREMapKind", "STR2ARG_MAP"))
local module_inst = coreir.lib.COREModuleDefAddModuleInstance(m_def, ffi.new("char[?]", #"asdf"+1, "asdf"), m, arg_map)

local module_cstr = ffi.new("char[?]", #"_test.json"+1, "_test.json")
local err = ffi.new("COREBool[1]")
coreir.lib.CORESaveModule(m, module_cstr, err)
   
