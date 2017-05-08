COREIR_LIB_DIR = ../../lib/

all: lib lua

lib:
	gcc -E ../../include/coreir-c/coreir.h | sed '/^#/ d' > coreir-single.h

lua: lib
	env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit coreir.lua

debug: lib
	strace -e open env LD_LIBRARY_PATH=$(COREIR_LIB_DIR) luajit coreir.lua

clean:
	rm coreir-single.h
