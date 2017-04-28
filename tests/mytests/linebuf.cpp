#include "coreir.h"
#include "rigel.hpp"
#include "coreir-pass/passes.hpp"

using namespace CoreIR;

int main() {
	// New context
	Context* c = newContext();
	Rigel::Rigel rigel(c);

	// Define a pixel
	int bpp = 8;

	// Define our input/weight matrices
	int width = 3;
	int height = 3;
	int im_width = 640;
	int im_height = 480;

	Module* linebuf_m = rigel.linebuf(width, height, im_width, im_height, bpp);

	cout << "Checking Errors" << endl;
	c->checkerrors();
	linebuf_m->print();

	bool err = false;
	cout << "Typechecking!" << endl;
	typecheck(c, linebuf_m, &err);
	if (err) c->die();

	cout << "Checking saving and loading pregen" << endl;
	saveModule(linebuf_m, "_conv.json", &err);
	if (err) {
		cout << "Could not save to json!!" << endl;
		c->die();
	}

	Module* m = loadModule(c, "_conv.json", &err);
	if (err) {
		cout << "Could not load from json!!" << endl;
		c->die();
	}
	m->print();


	// Link v1 of library
	//cout << "Linking stdlib!" << endl;
	//Namespace* stdlib_v1 = getStdlib_v1(c);
	//cout << "Linking!";
	//c->linkLib(stdlib_v1, stdlib);

	rungenerators(c, linebuf_m, &err);
	if (err) c->die();

	linebuf_m->print();
	typecheck(c, linebuf_m, &err);
	if (err) c->die();

	cout << "Checking saving and loading postgen" << endl;
	saveModule(linebuf_m, "_convGen.json", &err);
	if (err) {
		cout << "Could not save to json!!" << endl;
		c->die();
	}

	m = loadModule(c, "_convGen.json", &err);
	if (err) {
		cout << "Could not load from json!!" << endl;
		c->die();
	}
	m->print();

	deleteContext(c);

	return 0;
}
