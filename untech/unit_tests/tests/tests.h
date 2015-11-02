; Unit test

.ifndef ::_TESTS_H_
::_TESTS_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"

CONFIG TEST_STRING_BANK, "BANK1"

.struct UnitTestRoutineHeader
	name		.addr
	routinePtr	.addr
.endstruct

.struct UnitTestModuleHeader
	name		.addr
	routines	.tag	UnitTestRoutineHeader
.endstruct

.macro UnitTestHeader name
	.local Table, string

	.segment "TEST_MODULE_TABLE"
		.addr	Table

	.segment TEST_STRING_BANK
	string:
		.byte	.string(name), 0

	.rodata
	Table:
		.addr	string
.endmacro

.macro UnitTest	routine
	.local	string

	.segment TEST_STRING_BANK
	string:
		.byte	.string(routine), 0
	.rodata

		.addr	string
		.addr	routine
.endmacro

.macro EndUnitTestHeader
		.addr	0
		.addr	0
	.code
.endmacro

.macro BranchIfXyNeConst n, b
	CPY	#.loword(n)
	BNE	b
	CPX	#.hiword(n)
	BNE	b
.endmacro

.endif

; vim: set ft=asm:

