COREIR_LIB_DIR = ../../lib/

all: lib lua

lib:
	make -C ../../ install
	gcc -E ../../include/coreir-c/coreir.h | sed '/^#/ d' > coreir-single.h
	gcc -E -I../../include/ ../../include/coreir-lib/stdlib.h | sed '/^#/ d' > coreir-stdlib.h

lua: lib
	env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit coreir.lua

debug: lib
	strace env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit coreir.lua

intercept:
	gcc -fPIC -shared -I../../include/coreir-c intercept.c -o intercept.so -ldl -L $(COREIR_LIB_DIR) -lcoreir-c

clean:
	rm coreir-single.h
	rm coreir-stdlib.h

clean-all: clean
	make -C ../../ clean
