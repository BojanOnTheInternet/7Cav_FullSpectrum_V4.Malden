//#define TEST
//#define TEST_COUNTERATTACK

#include "..\OO\oo.h"

// Must be globals or the macros won't see them
SPM_CHANGES_RETIRE = 0;
SPM_CHANGES_REINSTATE = 1;
SPM_CHANGES_CALLUP = 2;
SPM_CHANGES_RESERVES = 3;
#define CHANGES(array, item) ((array) select SPM_CHANGES_##item)