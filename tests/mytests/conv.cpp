#include "context.hpp"
//#include "toFile.hpp"

//#include <fstream>

// Libraries
#include "stdlib.hpp"
#include "rigel.hpp"

//Compiler Passes
#include "passes.hpp"

using namespace CoreIR;

int main() {
	// New context
	Context* c = newContext();
  
	Namespace* g = c->getGlobal();
  
	Namespace* stdlib = getStdlib(c);

	Rigel::Rigel rigel (c);

	// Define a pixel
	int bpp = 8;
	Type* pixel_in = c->Array(bpp, c->BitIn());
	Type* pixel_out = c->Flip(pixel_in);

	// We need a multiply module
	Type* binop_t = c->Record({
			{"a", pixel_in},
			{"b", pixel_in},
			{"out", pixel_out}
		});

	Module* mult_m = g->newModuleDecl("mult", binop_t);
  
	// Define our input/weight matrices
	int width = 3;
	int height = 3;
	Type* mat_wxh_in = c->Array(height,c->Array(width,pixel_in));
	
	int n = width*height;
  
	// Define the type of the convolution
	Type* conv_t = c->Record({
			{"in", mat_wxh_in},
			{"wt", mat_wxh_in},
			{"out", pixel_out}
		});

	Module* conv_m = rigel.conv(width, height, bpp);
  
	cout << "Checking Errors" << endl;
	c->checkerrors();
	conv_m->print();
  
	bool err = false;
	cout << "Typechecking!" << endl;
	typecheck(c,conv_m,&err);
	if (err) c->die();

	cout << "Checking saving and loading pregen" << endl;
	saveModule(conv_m, "_conv.json",&err);
	if (err) {
		cout << "Could not save to json!!" << endl;
		c->die();
	}
  
	Module* m = loadModule(c,"_conv.json", &err);
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
  
	rungenerators(c,conv_m,&err);
	if (err) c->die();
  
	conv_m->print();
	typecheck(c,conv_m,&err);
	if(err) c->die();
 
	cout << "Checking saving and loading postgen" << endl;
	saveModule(conv_m, "_convGen.json",&err);
	if (err) {
		cout << "Could not save to json!!" << endl;
		c->die();
	}
  
	m = loadModule(c,"_convGen.json", &err);
	if(err) {
		cout << "Could not load from json!!" << endl;
		c->die();
	}
	m->print();

	deleteContext(c);
  
	return 0;
}
