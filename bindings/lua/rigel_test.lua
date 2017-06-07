package.path = "/home/hofstee/rigel/?.lua;/home/hofstee/rigel/src/?.lua;/home/hofstee/rigel/examples/?.lua;" .. package.path

local inspect = require 'inspect'
local coreir = require 'coreir'
local rigel_simple = require 'rigelSimple'

--- Test 3 -- a hardcoded convolution module and generating rigel code
-- Construct the convolve unit in CoreIR
local linebuffer_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.bit_in, 24),
   ["out"] = coreir.array(coreir.array(coreir.array(coreir.bit_out, 24), 3), 3),
}

local conv_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.array(coreir.array(coreir.bit_in, 24), 3), 3),
   ["out"] = coreir.array(coreir.bit_out, 24),
}

local stream_t = {
   ["clk"] = coreir.bit_in,
   ["rst_b"] = coreir.bit_in,
   ["in"] = coreir.array(coreir.bit_in, 24),
   ["out"] = coreir.array(coreir.bit_out, 24),
}

local linebuf = coreir.module_from("line_buffer", linebuffer_t)
local conv = coreir.module_from("conv", conv_t)
local stream = coreir.module_from("stream", stream_t)

coreir.add_instance(stream, linebuf)
coreir.add_instance(stream, conv)

coreir.connect(stream, stream["clk"], stream.line_buffer1["clk"])
coreir.connect(stream, stream["rst_b"], stream.line_buffer1["rst_b"])
coreir.connect(stream, stream["clk"], stream.conv2["clk"])
coreir.connect(stream, stream["rst_b"], stream.conv2["rst_b"])

coreir.connect(stream, stream["in"], stream.line_buffer1["in"])

coreir.connect(stream, stream.line_buffer1["out"], stream.conv2["in"])

coreir.connect(stream, stream.conv2["out"], stream["out"])

coreir.print_module(stream)
print(inspect(stream, coreir.inspect_options))

coreir.save_module(stream, "_conv.json")
local stream_dup = coreir.load_module("_conv.json")
coreir.print_module(stream_dup)
print(inspect(coreir.parse_module(stream_dup), coreir.inspect_options))

-- Analyze the module and generate Rigel module
local rate = 1/3


local test = { ["src"] = {[0] = "a", [1] = "b"} }
-- print(inspect(
