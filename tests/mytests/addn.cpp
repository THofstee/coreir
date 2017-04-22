#include <sstream>

#include "rigel.hpp"

// CoreIR Context
#include "context.hpp"

// Libraries
#include "stdlib.hpp"

// Compiler Passes
#include "passes.hpp"

using namespace CoreIR;

int main() {
	// New context
	Context* c = newContext();
	// Namespace* g = c->getGlobal();
	// Namespace* stdlib = getStdlib(c);

	// Declare parameters and types we need
	int n = 13;
	int bits = 8;

	Rigel::Rigel rigel (c);
	
	Module* addn_m = rigel.addn(n, bits);
	
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
