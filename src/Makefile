.SUFFIXES:

CC = clang++
CFLAGS = -std=c++11 -Wall -ferror-limit=5 -g

#DEPS = coreir.hpp typedcoreir.hpp enums.hpp types.hpp typecache.hpp toFile.hpp
DEPS = common.hpp types.hpp typecache.hpp context.hpp 
#OBJS = verilog.o typedcoreir.o helpers.o compiler.o coreir.o compiler.o typeconstructors.o types.o typecache.o toFile.o
OBJS = namespace.o instantiable.o context.o types.o genargs.o typecache.o common.o

all: context.a

run: addtree.run

clean:
	-@rm *.o *.a *.run

context.a: $(OBJS)
	ar rcs $@ $^

%.o: %.cpp $(DEPS)
	$(CC) $(CFLAGS) -c -o $@ $<

%.run: %.o $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

fuck:
	echo $(CFLAGS)
	echo $(CXX)
