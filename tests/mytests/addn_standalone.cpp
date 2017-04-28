#include <sstream>

// CoreIR Context
#include "coreir.h"
#include "coreir-lib/stdlib.hpp"
#include "coreir-pass/passes.hpp"

using namespace CoreIR;

int main() {
	// New context
	Context* c = newContext();
	Namespace* g = c->getGlobal();

	// Declare parameters and types we need
	int n = 13;
	int bits = 8;
	Type* data_in = c->Array(bits, c->BitIn());
	Type* data_out = c->Flip(data_in);
	Type* reduce_t = c->Record({
			{"in", c->Array(n,data_in)},
			{"out", data_out}
		});

	// Declare reduce typegen
	g->newTypeGen(
		"reduce",
		{{"width", AINT}, {"n", AINT}},
		[](Context* c, Args args) -> Type* {
			Type* data_in = c->Array(args.at("width")->arg2Int(), c->BitIn());
			Type* data_out = c->Flip(data_in);
		
			Type* reduce_t = c->Record({
					{"in", c->Array(args.at("n")->arg2Int(), data_in)},
					{"out", data_out}
				});
			
			return reduce_t;
		});

	// Declare addn generator
	Params addn_p = Params({{"width", AINT}, {"n", AINT}});
	Generator* addn_g = g->newGeneratorDecl("addn", addn_p, g->getTypeGen("reduce"));

	auto addn_gen_func = [](ModuleDef* addn_def, Context* c, Type* /*t*/, Args args) -> void {
		Namespace* stdlib = CoreIRLoadLibrary_stdlib(c);
		Namespace* g = c->getGlobal();

		Generator* add2_g = stdlib->getGenerator("add2");
		Generator* addn_g = g->getGenerator("addn");
			
		int n = args.at("n")->arg2Int();
				
		Wireable* self = addn_def->sel("self");

		// Each stage needs n/2 adders
		Wireable** adders = (Wireable**)calloc(n/2, sizeof(Wireable*));

		Args add2_a = {{"width", args.at("width")}};
			
		for (int k = 0; k < n/2; k++) {
			std::ostringstream oss;
			oss << "add2" << "_" << k;
			adders[k] = addn_def->addInstance(oss.str(), add2_g, add2_a);
		}

		// Wire inputs to adder
		Wireable* in = self->sel("in");

		for (int k = 0; k < n/2; k++) {
			addn_def->wire(in->sel(2*k+0), adders[k]->sel("in0"));
			addn_def->wire(in->sel(2*k+1), adders[k]->sel("in1"));
		}

		// Wire outputs
		if (n > 2) {
			// Recurse into another addn
			Args addn_a = {{"width", args.at("width")}, {"n", c->int2Arg(n/2+n%2)}};
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
	};
	
	// addn module definition generator
	auto addn_def = GeneratorDefFromFun(addn_g, addn_gen_func);

	Module* addn_m = g->runGenerator(addn_g, {{"width", c->int2Arg(bits)},{"n", c->int2Arg(n)}}, reduce_t);
	
	// Check for errors
	cout << "Checking Errors" << endl;
	c->checkerrors();
	addn_m->print();
  
	bool err = false;
	typecheck(c,addn_m,&err);
	if (err) c->die();

	cout << "Checking saving and loading pregen" << endl;
	saveModule(addn_m, "_addn.json",&err);
	if (err) {
		cout << "Could not save to json!!" << endl;
		c->die();
	}
  
	Module* m = loadModule(c,"_addn.json", &err);
	if(err) {
		cout << "Could not load from json!!" << endl;
		c->die();
	}
	m->print();

	// Link v1 of library
	//cout << "Linking stdlib!" << endl;
	//Namespace* stdlib_v1 = getStdlib_v1(c);
	//cout << "Linking!";
	//c->linkLib(stdlib_v1, stdlib);
  
	rungenerators(c,addn_m,&err);
	if (err) c->die();
  
	addn_m->print();
	typecheck(c,addn_m,&err);
	if(err) c->die();
 
	cout << "Checking saving and loading postgen" << endl;
	saveModule(addn_m, "_addnGen.json",&err);
	if (err) {
		cout << "Could not save to json!!" << endl;
		c->die();
	}
  
	m = loadModule(c,"_addnGen.json", &err);
	if(err) {
		cout << "Could not load from json!!" << endl;
		c->die();
	}
	m->print();

	deleteContext(c);
	
	return 0;
}
