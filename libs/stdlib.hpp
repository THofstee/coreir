#ifndef STDLIB_HPP_
#define STDLIB_HPP_

#include "context.hpp"

//#include "stdlib_defaults.hpp"
#include "stdlib_convert.hpp"

using namespace CoreIR;


inline void stdlib_convert(Context* c, Namespace* stdlib);
inline void stdlib_bitwise(Context* c, Namespace* stdlib);

Namespace* getStdlib(Context* c) {
  
  Namespace* stdlib = c->newNamespace("stdlib");
 
  /////////////////////////////////
  // Stdlib Types
  /////////////////////////////////
  Params widthparam = Params({{"width",AINT}});

  //Single bit types
  stdlib->newNamedType("clk","clkIn",c->BitOut());
  stdlib->newNamedType("rst","rstIn",c->BitOut());
  
  //Array types
  TypeGen arrtypegen(
    widthparam,
    [](Context* c, Args args) {
      return c->Array(args.at("width")->arg2Int(),c->BitOut());
    }
  );
 
  stdlib->newNamedType("int","intIn",arrtypegen);
  stdlib->newNamedType("uint","uintIn",arrtypegen);
  
  
  //Create stdtype
  TypeGen primtypegen(
      {{"in",ATYPE},{"out",ATYPE},{"clk",ABOOL},{"rst",ABOOL}},
      [](Context* c, Args args) {
        RecordParams rparams;
        if (args.at("clk")->arg2Bool()) {
          rparams["clkIn"] = c->getNamedType("stdlib","clkIn");
        }
        if (args.at("rst")->arg2Bool()) {
          rparams["rstIn"] = c->getNamedType("stdlib","rstIn");
        }
        Type* inType = args.at("in");
        Type* outType = args.at("out");
        //Make sure that inType is always in and outtype is always out
        if (!inType->isKind(ANY)) {
          assert(!c->Flip(inType)->hasInput())
          rparams["in"] = inType;
        }
        if (!outType->isKind(ANY)) {
          assert(!outType->hasInput())
          rparams["out"] = outType;
        }
        return c->Record(rparams);
      }
  )

  stdlib->addTypeGen("primtype",primtypegen);
 
  /////////////////////////////////
  // Stdlib convert primitives
  //   slice,concat,cast,strip
  /////////////////////////////////
  stdlib_convert(c,stdlib);

  /////////////////////////////////
  // Stdlib bitwise primitives
  //   not,and,or,xor,andr,orr,xorr,shift
  /////////////////////////////////
  stdlib_bitwise(c,stdlib);

  /////////////////////////////////
  // Stdlib Arithmetic primitives
  //   dshift,add,sub,mul,div,lt,leq,gt,geq,eq,neq,neg
  /////////////////////////////////
  //TODO

  /////////////////////////////////
  // Stdlib stateful primitives
  //   reg, ram, rom
  /////////////////////////////////
  stdlib_state(c,stdlib);

  //declare new add2 generator
  stdlib->newGeneratorDecl("add2",widthparam,stdlib->getTypeGen("binop"));

  //TODO Hack to get rid of
  Type* binop16 = c->Record({
      {"in0",c->Array(16,c->BitIn())},
      {"in1",c->Array(16,c->BitIn())},
      {"out",c->Array(16,c->BitOut())}
  });
  
  Type* outType = c->Record({
    {"out",c->Array(16,c->BitOut())}
  });

  Type* inType = c->Record({
    {"in",c->Array(16,c->BitIn())}
  });

  stdlib->newModuleDecl("add2_16",binop16);
  stdlib->newModuleDecl("mult2_16",binop16);
  stdlib->newModuleDecl("const_16",outType,{{"value",AINT}});
  stdlib->newModuleDecl("GPI_16",outType);
  stdlib->newModuleDecl("GPO_16",inType);
  return stdlib;
}

#endif //STDLIB_HPP_
