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
}

local conv_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.array(coreir.array(coreir.bit_in, bpp), mat_w), mat_h),
   ["out"] = coreir.array(coreir.bit_out, bpp),
}

local stream_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.bit_in, bpp),
   ["out"] = coreir.array(coreir.bit_out, bpp),
}

local linebuf = coreir.module_from("line_buffer", linebuffer_t)
local conv = coreir.module_from("conv", conv_t)
local stream = coreir.module_from("stream", stream_t)

-- @todo definitely need the generator available on C api...
local conv_args = {
   ["weights"] = {
	  { 4, 14, 14,  4},
	  {14, 32, 32, 14},
	  {14, 32, 32, 14},
	  { 4, 14, 14,  4}
   }
}

-- @todo also need a way to run generators in the C api...
coreir.add_instance(conv, linebuf, {}, "wat")

-- Make the top stream module
coreir.add_instance(stream, linebuf, {}, "line_buffer1")
coreir.add_instance(stream, conv, conv_args, "conv2")

coreir.connect(stream, stream["clk"], stream.line_buffer1["clk"])
coreir.connect(stream, stream["rst_b"], stream.line_buffer1["rst_b"])
coreir.connect(stream, stream["clk"], stream.conv2["clk"])
coreir.connect(stream, stream["rst_b"], stream.conv2["rst_b"])

coreir.connect(stream, stream["in"], stream.line_buffer1["in"])

coreir.connect(stream, stream.line_buffer1["out"], stream.conv2["in"])

coreir.connect(stream, stream.conv2["out"], stream["out"])

local err = ffi.new("COREBool[1]")
coreir.lib.CORERunGenerators(coreir.ctx, getmetatable(stream).module, err)

coreir.print_module(stream)
print(inspect(stream, coreir.inspect_options))

coreir.save_module(stream, "_conv.json")
local stream_dup = coreir.load_module("_conv.json")
coreir.print_module(stream_dup)
print(inspect(coreir.parse_module(stream_dup), coreir.inspect_options))

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

local stenciled = rs.connect{
   input = padded,
   toModule = rs.HS(rs.modules.linebuffer{
					   type = rs.uint8,
					   V = 1,
					   size = padSize,
					   stencil = {-3, 0, -3, 0}
   })
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
