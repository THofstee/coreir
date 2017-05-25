#include "ctypes.h"
#include "coreir.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

const char* ICEPTGetInstRefName(COREInstance* iref) {
	printf("COREGetInstRefName() call intercepted\n");
	const char* s = COREGetInstRefName(iref);
	return s;
}
