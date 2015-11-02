; Unit tests modules

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "tests.h"
.include "static-random.inc"

.export	TestModuleTable
.export	TestModuleTable_End

.setcpu "65816"

.segment "TEST_MODULE_TABLE"
TestModuleTable:
.code

	; ::TODO autogenerate::
	.include	"common/math.asm"
	.include	"common/string.asm"

.segment "TEST_MODULE_TABLE"
TestModuleTable_End:

