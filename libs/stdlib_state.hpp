/////////////////////////////////
// Stdlib stateful primitives
//   reg, ram, rom
/////////////////////////////////

inline void stdlib_state(Context* c, Namespace* stdlib) {
  
  //Template
  /* Name: 
   * GenParams: 
   *    <Argname>: <Argtype>, <description>
   * Type: 
   * Fun: 
   * Argchecks: 
   */
   
  /* Name: reg
   * GenParams: 
   *    regType: TYPE, Type of register
   *    en: BOOL, has enable?
   *    clr: BOOL, has clr port
   *    rst: BOOL, has asynchronous reset
   * ConfigParams
   *    resetval: UINT, value at reset
   * Type: {'in':regType
   * Fun: out <= (rst|clr) ? resetval : en ? in : out;
   * Argchecks: 
   */
  auto regFun = [](Context* c, Args args) { 
    uint width = args.at("width");
    return c->Record({
        {"in",c->Array(width,c->BitIn())},
        {"out",c->Array(width,c->BitOut())}
    });
  } 
  Params regParams({
    {"width",UINT},
    {"en",BOOL},
    {"clr",BOOL},
    {"rst",BOOL}
  });
  Params regConfigParams({{"resetval",UINT}});
  TypeGen regTypeGen(regParams,regFun);
  stdlib->newGeneratorDecl("reg",regParams,regTypeGen,configParams);

  /* Name: rom
   * GenParams: 
   *    TODO
   * ConfigParams
   *    TODO
   * Type: TODO
   * Fun: TODO
   * Argchecks: 
   */

}
