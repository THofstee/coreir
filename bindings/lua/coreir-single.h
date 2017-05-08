



typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;

typedef long int int64_t;







typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;

typedef unsigned int uint32_t;



typedef unsigned long int uint64_t;
typedef signed char int_least8_t;
typedef short int int_least16_t;
typedef int int_least32_t;

typedef long int int_least64_t;






typedef unsigned char uint_least8_t;
typedef unsigned short int uint_least16_t;
typedef unsigned int uint_least32_t;

typedef unsigned long int uint_least64_t;
typedef signed char int_fast8_t;

typedef long int int_fast16_t;
typedef long int int_fast32_t;
typedef long int int_fast64_t;
typedef unsigned char uint_fast8_t;

typedef unsigned long int uint_fast16_t;
typedef unsigned long int uint_fast32_t;
typedef unsigned long int uint_fast64_t;
typedef long int intptr_t;


typedef unsigned long int uintptr_t;
typedef long int intmax_t;
typedef unsigned long int uintmax_t;








typedef uint32_t u32;

typedef struct COREContext COREContext;
typedef struct CORENamespace CORENamespace;
typedef struct COREType COREType;
typedef struct COREModule COREModule;
typedef struct COREModuleDef COREModuleDef;
typedef struct COREWireable COREWireable;
typedef struct COREInstance COREInstance;
typedef struct COREInterface COREInterface;
typedef struct CORESelect CORESelect;
typedef struct COREConnection COREConnection;
typedef struct COREWirePath COREWirePath;
typedef struct COREArg COREArg;

typedef enum {
    STR2TYPE_ORDEREDMAP = 0,
    STR2PARAM_MAP = 1,
    STR2ARG_MAP = 2
} COREMapKind;


void* CORENewMap(COREContext* c, void* keys, void* values, u32 len, COREMapKind kind);


extern COREContext* CORENewContext();
extern void COREDeleteContext(COREContext*);


extern COREType* COREAny(COREContext* CORE);
extern COREType* COREBitIn(COREContext* CORE);
extern COREType* COREBit(COREContext* CORE);
extern COREType* COREArray(COREContext* CORE, u32 len, COREType* elemType);
extern COREType* CORERecord(COREContext* c, void* recordparams);


extern const char* COREArg2Str(COREArg* a, 
                                          _Bool
                                              * err);
extern int COREArg2Int(COREArg* a, 
                                  _Bool
                                      * err);
extern COREArg* COREInt2Arg(COREContext* c,int i);
extern COREArg* COREStr2Arg(COREContext* c,char* str);

extern void COREPrintType(COREType* t);


extern COREModule* CORELoadModule(COREContext* c, char* filename, 
                                                                 _Bool
                                                                     * err);



extern void CORESaveModule(COREModule* module, char* filename, 
                                                              _Bool
                                                                  * err);

extern CORENamespace* COREGetGlobal(COREContext* c);


extern const char* COREGetInstRefName(COREInstance* iref);



extern COREModule* CORENewModule(CORENamespace* ns, char* name, COREType* type, void* configparams);


extern void COREPrintModule(COREModule* m);
extern COREModuleDef* COREModuleNewDef(COREModule* m);
extern COREModuleDef* COREModuleGetDefs(COREModule* m);
void COREModuleAddDef(COREModule* module, COREModuleDef* module_def);



extern COREInstance* COREModuleDefAddModuleInstance(COREModuleDef* module_def, char* name, COREModule* module, void* config);
extern COREInterface* COREModuleDefGetInterface(COREModuleDef* m);
extern COREArg* COREGetConfigValue(COREInstance* i, char* s);




extern void COREModuleDefWire(COREModuleDef* module_def, COREWireable* a, COREWireable* b);
extern CORESelect* COREInstanceSelect(COREInstance* instance, char* field);
extern CORESelect* COREInterfaceSelect(COREInterface* interface, char* field);
extern COREInstance** COREModuleDefGetInstances(COREModuleDef* m, u32* numInstances);
extern COREConnection** COREModuleDefGetConnections(COREModuleDef* m, int* numWires);
extern COREWireable* COREConnectionGetFirst(COREConnection* c);
extern COREWireable* COREConnectionGetSecond(COREConnection* c);
extern COREWireable** COREWireableGetConnectedWireables(COREWireable* wireable, int* numWireables);
extern CORESelect* COREWireableSelect(COREWireable* w, char* name);
extern COREWireable* COREModuleDefSelect(COREModuleDef* m, char* name);
extern COREModuleDef* COREWireableGetModuleDef(COREWireable* w);
extern COREModule* COREModuleDefGetModule(COREModuleDef* m);
extern const char** COREWireableGetAncestors(COREWireable* w, int* num_ancestors);
extern void COREPrintErrors(COREContext* c);
extern const char* CORENamespaceGetName(CORENamespace* n);
