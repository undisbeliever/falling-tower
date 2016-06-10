; Unit test

.ifndef ::_TESTS_H_
::_TESTS_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"


.global _Tests_tmp1
.global _Tests_tmp2
.global _Tests_tmp3
.global _Tests_tmp4
.global _Tests_tmp5
.global _Tests_tmp6

tmp1 := _Tests_tmp1
tmp2 := _Tests_tmp2
tmp3 := _Tests_tmp3
tmp4 := _Tests_tmp4
tmp5 := _Tests_tmp5
tmp6 := _Tests_tmp6


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

