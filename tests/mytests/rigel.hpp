#ifndef RIGEL_H_
#define RIGEL_H_

#include <mutex>
#include <sstream>

#include "coreir.h"

using namespace CoreIR;

namespace Rigel {
	class Rigel {
	private:
		// Initialize binop typegen
		void init_binop_tg() {
			static std::once_flag initialized;
			std::call_once(initialized, [&]() {
					rigel->newTypeGen(
						"binop",
						{{"bit_width", AINT}},
						[](Context* c, Args args) -> Type* {
							Type* data_in = c->Array(args.at("bit_width")->arg2Int(), c->BitIn());
							Type* data_out = c->Flip(data_in);

							Type* reduce_t = c->Record({
									{"a", data_in},
									{"b", data_in},
									{"out", data_out}
								});

							return reduce_t;
						});
				});
		}

		// Initialize add2 generator
		void init_add2_g() {
			init_binop_tg();

			static std::once_flag initialized;
			std::call_once(initialized, [&]() {
					// Declare the addn generator
					Generator* add2_g = rigel->newGeneratorDecl(
						"add2",
						{{"bit_width", AINT }},
						rigel->getTypeGen("binop"));

					(void)add2_g;
				});
		}

		// Initialize mul2 generator
		void init_mul2_g() {
			init_binop_tg();

			static std::once_flag initialized;
			std::call_once(initialized, [&]() {
					// Declare the addn generator
					Generator* mul2_g = rigel->newGeneratorDecl(
						"mul2",
						{{"bit_width", AINT}},
						rigel->getTypeGen("binop"));

					(void)mul2_g;
				});
		}

		// Initialize stream typegen
		void init_stream_tg() {
			static std::once_flag initialized;
			std::call_once(initialized, [&]() {
					rigel->newTypeGen(
						"stream",
						{{"bit_width", AINT}},
						[](Context* c, Args args) -> Type* {
							Type* data_in = c->Array(args.at("bit_width")->arg2Int(), c->BitIn());
							Type* data_out = c->Flip(data_in);

							Type* stream_t = c->Record({
									{"in", data_in},
									{"out", data_out}
								});

							return stream_t;
						});
				});
		}

		// Initialize reg generator
		void init_reg_g() {
			init_stream_tg();

			static std::once_flag initialized;
			std::call_once(initialized, [&]() {
					// Declare the reg generator
					Generator* reg_g = rigel->newGeneratorDecl(
						"reg",
						{{"bit_width", AINT}},
						rigel->getTypeGen("stream"));

					(void)reg_g;
				});
		}

		// Initialize reduce typegen
		void init_reduce_tg() {
			static std::once_flag initialized;
			std::call_once(initialized, [&](){
					rigel->newTypeGen(
						"reduce",
						{{"bit_width", AINT}, {"n",AINT}},
						[](Context* c, Args args) -> Type* {
							Type* data_in = c->Array(args.at("bit_width")->arg2Int(), c->BitIn());
							Type* data_out = c->Flip(data_in);
		
							Type* reduce_t = c->Record({
									{"in", c->Array(args.at("n")->arg2Int(), data_in)},
									{"out", data_out}
								});
			
							return reduce_t;
						});
				});
		}

		// Initialize addn generator
		void init_addn_g() {
			init_reduce_tg();
			init_add2_g();

			static std::once_flag initialized;
			std::call_once(initialized, [&](){
					// Declare the addn generator
					Generator* addn_g = rigel->newGeneratorDecl(
						"addn",
						{{"bit_width", AINT}, {"n", AINT}},
						rigel->getTypeGen("reduce"));

					// addn definition
					auto addn_def = GeneratorDefFromFun(
						addn_g,
						[](ModuleDef* addn_def, Context* c, Type* /*t*/, Args args) -> void {
							Namespace* rigel = c->getNamespace("rigel");

							Generator* add2_g = rigel->getGenerator("add2");
							Generator* addn_g = rigel->getGenerator("addn");
			
							int n = args.at("n")->arg2Int();
				
							Wireable* self = addn_def->sel("self");

							// Each stage needs n/2 adders
							Wireable** adders = (Wireable**)calloc(n/2, sizeof(Wireable*));

							Args add2_a = {{"bit_width", args.at("bit_width")}};
			
							for (int k = 0; k < n/2; k++) {
								std::ostringstream oss;
								oss << "add2" << "_" << k;
								adders[k] = addn_def->addInstance(oss.str(), add2_g, add2_a);
							}

							// Wire inputs to adder
							Wireable* in = self->sel("in");

							for (int k = 0; k < n/2; k++) {
								addn_def->wire(in->sel(2*k+0), adders[k]->sel("a"));
								addn_def->wire(in->sel(2*k+1), adders[k]->sel("b"));
							}

							// Wire outputs
							if (n > 2) {
								// Recurse into another addn
								Args addn_a = {{"bit_width", args.at("bit_width")}, {"n", c->int2Arg(n/2+n%2)}};
								Wireable* addn_next = addn_def->addInstance("addn", addn_g, addn_a);

								for (int k = 0; k < n/2; k++) {
									addn_def->wire(adders[k]->sel("out"), addn_next->sel("in")->sel(k));
								}
								if (n%2 != 0) {
									addn_def->wire(in->sel(n-1), addn_next->sel("in")->sel(n/2));
								}
							}
							else {
								// Base case 2 inputs
								assert(n == 2);
								addn_def->wire(adders[0]->sel("out"), self->sel("out"));
							}
						});
				});
		}

		// Initialize conv typegen
		void init_conv_tg() {
			static std::once_flag initialized;
			std::call_once(initialized, [&](){
					rigel->newTypeGen(
						"conv",
						{{"width", AINT}, {"height", AINT}, {"bit_width", AINT}},
						[](Context* c, Args args) -> Type* {
							Type* elem_in = c->Array(args.at("bit_width")->arg2Int(), c->BitIn());
		
							Type* conv_t = c->Record({
									{"in", c->Array(args.at("height")->arg2Int(), c->Array(args.at("width")->arg2Int(), elem_in))},
									{"wt", c->Array(args.at("height")->arg2Int(), c->Array(args.at("width")->arg2Int(), elem_in))},
									{"out", c->Flip(elem_in)}
								});
			
							return conv_t;
						});
				});
		}

		// Initialize conv generator
		void init_conv_g() {
			init_addn_g();
			init_mul2_g();
			init_conv_tg();

			static std::once_flag initialized;
			std::call_once(initialized, [&](){
					// Declare the addn generator
					Generator* conv_g = rigel->newGeneratorDecl(
						"conv",
						{{"width", AINT}, {"height", AINT}, {"bit_width", AINT}},
						rigel->getTypeGen("conv"));

					// conv definition
					auto conv_def = GeneratorDefFromFun(
						conv_g,
						[](ModuleDef* conv_def, Context* c, Type* /*t*/, Args args) -> void {
							Namespace* rigel = c->getNamespace("rigel");

							Generator* addn_g = rigel->getGenerator("addn");
							Generator* mul2_g = rigel->getGenerator("mul2");
			
							int height = args.at("height")->arg2Int();
							int width = args.at("width")->arg2Int();
				
							Wireable* self = conv_def->sel("self");

							// Declare all the multipliers we need
							Wireable*** mults = (Wireable***)calloc(height, sizeof(Wireable**));

							for (int h = 0; h < height; h++) {
								mults[h] = (Wireable**)calloc(width, sizeof(Wireable*));
		  
								for(int w = 0; w < width; w++) {
									std::stringstream oss;
									oss << "mult_" << (h*width + w);
									mults[h][w] = conv_def->addInstance(oss.str(), mul2_g, {{"bit_width", args.at("bit_width")}});
								}
							}

							// Sum the multiplied weights/inputs
							Wireable* add_n = conv_def->addInstance("addn", addn_g, {{"bit_width", args.at("bit_width")}, {"n", c->int2Arg(width*height)}});

							// Wire everything together
							Wireable* input = self->sel("in");
							Wireable* weight = self->sel("wt");
							Wireable* output = self->sel("out");
							for (int h = 0; h < height; ++h) {
								Wireable* input_row = input->sel(h);
								Wireable* weight_row = weight->sel(h);
								for (int w = 0; w < width; ++w) {
									conv_def->wire(input_row->sel(w), mults[h][w]->sel("a"));
									conv_def->wire(weight_row->sel(w), mults[h][w]->sel("b"));
									conv_def->wire(mults[h][w]->sel("out"), add_n->sel("in")->sel(h*width+w));
								}
							}
							conv_def->wire(add_n->sel("out"), output);
						});
				});
		}

		// Initialize taps typegen
		void init_taps_tg() {
			static std::once_flag initialized;
			std::call_once(initialized, [&]() {
					rigel->newTypeGen(
						"taps",
						{{"width", AINT}, {"height", AINT}, {"bit_width", AINT}},
						[](Context* c, Args args) -> Type* {
							Type* elem_in = c->Array(args.at("bit_width")->arg2Int(), c->BitIn());
		
							Type* taps_t = c->Record({
									{"in", elem_in},
									{"out", c->Array(args.at("height")->arg2Int(), c->Array(args.at("width")->arg2Int(), c->Flip(elem_in)))}
								});
			
							return taps_t;
						});
				});
		}

		// Initialize linebuf generator
		void init_linebuf_g() {
			init_reg_g();
			init_taps_tg();

			static std::once_flag initialized;
			std::call_once(initialized, [&](){
					// Declare the addn generator
					Generator* linebuf_g = rigel->newGeneratorDecl(
						"linebuf",
						{{"width", AINT}, {"height", AINT}, {"im_width", AINT}, {"im_height", AINT}, {"bit_width", AINT}},
						rigel->getTypeGen("taps"));

					// conv definition
					auto linebuf_def = GeneratorDefFromFun(
						linebuf_g,
						[](ModuleDef* linebuf_def, Context* c, Type* /*t*/, Args args) -> void {
							Namespace* rigel = c->getNamespace("rigel");

							Generator* reg_g = rigel->getGenerator("reg");
			
							int height = args.at("height")->arg2Int();
							int width = args.at("width")->arg2Int();
							int im_height = args.at("im_height")->arg2Int();
							int im_width = args.at("im_width")->arg2Int();
							(void)im_height;
							
							Wireable* self = linebuf_def->sel("self");

							// We need (height-1)*im_width + width registers
							int buf_size = (height-1)*im_width + width;
							Wireable** registers = (Wireable**)calloc(buf_size, sizeof(Wireable*));

							Args reg_a = {{"bit_width", args.at("bit_width")}};

							for (int k = 0; k < buf_size; k++) {
								std::ostringstream oss;
								oss << "reg" << "_" << k;
								registers[k] = linebuf_def->addInstance(oss.str(), reg_g, reg_a);
							}

							// Wire up the registers in a chain
							for (int k = 1; k < buf_size; k++) {
								linebuf_def->wire(registers[k]->sel("out"), registers[k-1]->sel("in"));
							}

							// Wire inputs
							linebuf_def->wire(self->sel("in"), registers[buf_size-1]->sel("in"));

							// Wire outputs
							for (int h = 0; h < height; h++) {
								for(int w = 0; w < width; w++) {
									linebuf_def->wire(registers[h*im_width+w]->sel("out"), self->sel("out")->sel(h)->sel(w));
								}
							}
						});
				});
		}
	public:
		Context* ctx;
		Namespace* rigel;

		Rigel(Context* c) {
			ctx = c;
			if (ctx->hasNamespace("rigel")) {
				// Should this be an error?
				//TODO: if this is the case, then all the singleton init functions will break because we'll have 2 instances of a Rigel class in one context, with each having its own copies of the static init flags.
				//TODO: possible solution: put the flags in the rigel namespace, so then they will be shared across all rigel classes
				//TODO: issue: if we put the flags in the rigel namespace, multiple rigel classes using different contexts will not be initialized correctly?
				rigel = ctx->getNamespace("rigel");
			}
			else {
				rigel = ctx->newNamespace("rigel");
			}
		}
		Rigel(Rigel const&) = delete;
		void operator=(Rigel const&) = delete;

		Module* addn(size_t n, size_t bit_width) {
			//TODO: replace bit_width with a Type* and then overload the adds/mults with the type (float/binary)
			std::cout << "ayy" << std::endl;
			init_addn_g();
			init_reduce_tg();

			Args args = Args({
					{"bit_width", ctx->int2Arg(bit_width)},
					{"n", ctx->int2Arg(n)}
				});
			
			return rigel->runGenerator(
				rigel->getGenerator("addn"),
				args,
				// nullptr);
				ctx->BitIn());
		}

		Module* conv(size_t width, size_t height, size_t bit_width) {
			//TODO: replace bit_width with a Type* and then overload the adds/mults with the type (float/binary)
			init_conv_g();
			init_conv_tg();

			Args args = Args({
					{"width", ctx->int2Arg(width)},
					{"height", ctx->int2Arg(height)},
					{"bit_width", ctx->int2Arg(bit_width)}
				});
			
			return rigel->runGenerator(
				rigel->getGenerator("conv"),
				args,
				// nullptr);
				ctx->BitIn());
		}

		Module* linebuf(size_t width, size_t height, size_t im_width, size_t im_height, size_t bit_width) {
			//TODO: replace bit_width with a Type* and then overload the adds/mults with the type (float/binary)
			init_linebuf_g();
			init_taps_tg();

			Args args = Args({
					{"width", ctx->int2Arg(width)},
					{"height", ctx->int2Arg(height)},
					{"im_width", ctx->int2Arg(im_width)},
					{"im_height", ctx->int2Arg(im_height)},
					{"bit_width", ctx->int2Arg(bit_width)}
				});

			return rigel->runGenerator(
				rigel->getGenerator("linebuf"),
				args,
				// nullptr);
				ctx->BitIn());
		}
	};
}

#endif
