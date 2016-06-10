; Unit tests modules

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "tests/tests.h"
.include "tests/static-random.inc"

.include "common/string.h"

.setcpu "65816"

.module UnitTest_String

	UnitTestHeader String
		UnitTest	IntToString_U8A
		UnitTest	IntToString_U16Y
		UnitTest	IntToString_U32XY
		UnitTest	IntToString_S8A
		UnitTest	IntToString_S16Y
		UnitTest	IntToString_S32XY
	EndUnitTestHeader
.code


.macro ReturnCompareString v
	.local Wrong, len

	PHA
	PLB

	len .set .strlen(.sprintf("%i", v))

	; ::TODO write a strcmp function::
        .repeat len, i
		LDA	a:i, X
		CMP	#.strat(.sprintf("%i", v), i)
		BNE	Wrong
	.endrepeat

	LDA	a:len, X
	BNE	Wrong

	SEC
	RTS

Wrong:
	CLC
	RTS
.endmacro

.A8
.I16
.routine IntToString_U8A
	STATIC_RANDOM_MIN_MAX num, 0, $FF

	LDA	#num
	JSR	String::IntToString_U8A

	ReturnCompareString num
.endroutine


.A8
.I16
.routine IntToString_U16Y
	STATIC_RANDOM_MIN_MAX num, 0, $FFFF

	LDY	#num
	JSR	String::IntToString_U16Y

	ReturnCompareString num
.endroutine


.A8
.I16
.routine IntToString_U32XY
	STATIC_RANDOM_MIN_MAX num, $FFFFF, $FFFFFFF

	LDXY	#num
	JSR	String::IntToString_U32XY

	ReturnCompareString num
.endroutine


.A8
.I16
.routine IntToString_S8A
	STATIC_RANDOM_MIN_MAX num, -127, 127

	LDA	#.lobyte(num)
	JSR	String::IntToString_S8A

	ReturnCompareString num
.endroutine


.A8
.I16
.routine IntToString_S16Y
	STATIC_RANDOM_MIN_MAX num, -$7FFF, $7FFF

	LDY	#.loword(num)
	JSR	String::IntToString_S16Y

	ReturnCompareString num
.endroutine


.A8
.I16
.routine IntToString_S32XY
	STATIC_RANDOM_MIN_MAX num, -$7FFFFFF, $7FFFFFF

	LDXY	#num
	JSR	String::IntToString_S32XY

	ReturnCompareString num
.endroutine


.delmacro ReturnCompareString

.endmodule

; vim: set ft=asm:

