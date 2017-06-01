#include "typegen.hpp"

#include "common.hpp"
#include "context.hpp"

using namespace std;

namespace CoreIR {
	Type* TypeGen::getType(Args args) {
		checkArgsAreParams(args,params);
		Type* t = this->createType(ns->getContext(),args);//HERE #2
		return flipped ? t->getFlipped() : t;
	}
}
