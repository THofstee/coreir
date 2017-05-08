all: lib lua

lib:
	gcc -E ../../include/coreir-c/coreir.h | sed '/^#/ d' > coreir-single.h

lua:
	luajit coreir.lua

debug:
	strace -e open luajit coreir.lua

clean:
	rm coreir-single.h
