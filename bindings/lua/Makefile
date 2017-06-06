COREIR_LIB_DIR = ../../lib/
TRACE = ltrace -S

all: lib lua

docs:
	ldoc .

lib:
	make -C ../../ install
	gcc -E ../../include/coreir-c/coreir.h | sed '/^#/ d' > coreir-single.h
	gcc -E -I../../include/ ../../include/coreir-lib/stdlib.h | sed '/^#/ d' > coreir-stdlib.h

lib-debug: COREDEBUG=1
lib-debug:
	COREDEBUG=$(COREDEBUG) make -C ../../ install
	gcc -E ../../include/coreir-c/coreir.h | sed '/^#/ d' > coreir-single.h
	gcc -E -I../../include/ ../../include/coreir-lib/stdlib.h | sed '/^#/ d' > coreir-stdlib.h

core: lib
	env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit coreir.lua

core-slow: lib
	env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit -joff coreir.lua

lua: lib
	env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit test.lua

lua-slow: lib
	env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit -joff test.lua

gdb: lib
	gdb --args env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit -joff test.lua

debug-slow: lib-debug
	$(TRACE) env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit -joff test.lua

debug: lib-debug
	$(TRACE) env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit test.lua

core-debug: lib-debug
	$(TRACE) env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit coreir.lua

core-slow-debug: lib-debug
	$(TRACE) env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit -joff coreir.lua

core-gdb: lib
	gdb --args env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit -joff coreir.lua

intercept:
	gcc -fPIC -shared -I../../include/coreir-c intercept.c -o intercept.so -ldl -L $(COREIR_LIB_DIR) -lcoreir-c

clean:
	rm -f coreir-single.h
	rm -f coreir-stdlib.h

clean-all: clean
	make -C ../../ clean
