#include "coreir.h"
#include "coreir-lib/stdlib.hpp"
#include "rigel.hpp"
#include "coreir-pass/passes.hpp"

using namespace CoreIR;

int main() {
	// New context
	Context* c = newContext();
	Rigel::Rigel rigel (c);

	// Define a pixel
	int bpp = 8;
	int width = 3;
	int height = 3;

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
