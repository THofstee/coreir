#include "coreir.h"
#include <cassert>

using namespace CoreIR;

int main() {
  Context* c = newContext();

  // TODO should test a bunch of other permutations
  Args g1 = {{"a",c->argInt(5)},{"b",c->argString("ross")}};
  Args g2 = {{"a",c->argInt(5)},{"b",c->argString("ross")}};
  Args g3 = {{"c",c->argInt(5)},{"b",c->argString("ross")}};
  Args g4 = {{"a",c->argInt(5)},{"b",c->argString("ross")},{"c",c->argType(c->BitIn())}};
  assert(g1 == g2);
  assert(checkArgs(g1,{{"a",AINT},{"b",ASTRING}}));
  assert(g1 != g3);
  assert(g1 != g4);
  assert(checkArgs(g4,{{"a",AINT},{"b",ASTRING},{"c",ATYPE}}));
  deleteContext(c);
  return 0;
}
