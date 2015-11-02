
.include "common/math.h"

.setcpu "65816"

.module UnitTest_Math

	UnitTestHeader Math
		UnitTest	Divide_U16Y_U8A
		UnitTest	Divide_U16Y_U16X
		UnitTest	Divide_S16Y_U16X
		UnitTest	Divide_U16Y_S16X
		UnitTest	Divide_S16Y_S16X
		UnitTest	Divide_U32_U32
		UnitTest	Divide_S32_S32
		UnitTest	Divide_U32_U8A
		UnitTest	Negate32
	EndUnitTestHeader


.define MATH_REPEAT 10

.segment "SHADOW"
	tmp:		.res 4

tablePos := tmp

.code


.A8
.I16
.routine Divide_U16Y_U8A
	.repeat	2
		STATIC_RANDOM_MIN_MAX dividend, $FF, $FFFF
		STATIC_RANDOM_MIN_MAX divisor, 0, $FF

		LDY	#dividend
		LDA	#divisor
		JSR	Math::Divide_U16Y_U8A

		CPY	#dividend / divisor
		BNE	Failure

		CPX	#dividend .mod divisor
		BNE	Failure
	.endrepeat

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine



.struct Divide_16_Table
	dividend	.addr
	divisor		.addr
	result		.addr
	remainder	.addr
.endstruct


.macro	Process_Divide_16_Table routine, table
	.local Failure

	REP	#$30
.A16
.I16
	LDA	#(MATH_REPEAT - 1) * .sizeof(Divide_16_Table)

	REPEAT
		STA	tablePos
		TAX

		LDA	f:table + Divide_16_Table::dividend, X
		TAY
		LDA	f:table + Divide_16_Table::divisor, X
		TAX

		JSR	routine

		TXA
		LDX	tablePos
		CMP	f:table + Divide_16_Table::remainder, X
		BNE	Failure

		TYA
		CMP	f:table + Divide_16_Table::result, X
		BNE	Failure

		TXA
		SUB	#.sizeof(Divide_16_Table)
	UNTIL_MINUS

	SEC
	RTS

Failure:
	CLC
	RTS
.endmacro


.A8
.I16
.routine Divide_U16Y_U16X
	Process_Divide_16_Table Math::Divide_U16Y_U16X, Table

.segment "BANK2"
Table:
	; Test that divisors < 256 work
	STATIC_RANDOM_MIN_MAX dividend, 0, $FFFF
	STATIC_RANDOM_MIN_MAX divisor, 1, $FF

	.word	dividend, divisor
	.word	dividend / divisor, dividend .mod divisor

	; Test that divisors > 256 work
	STATIC_RANDOM_MIN_MAX dividend, 0, $FFFF
	STATIC_RANDOM_MIN_MAX divisor, 1, $FF

	.word	dividend, divisor
	.word	dividend / divisor, dividend .mod divisor

	; More tests
	.repeat	MATH_REPEAT - 2
		STATIC_RANDOM_MIN_MAX dividend, $1000, $FFFF
		STATIC_RANDOM_MIN_MAX divisor, 1, $1FFF

		.word	dividend, divisor
		.word	dividend / divisor, dividend .mod divisor
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Divide_S16Y_U16X
	Process_Divide_16_Table Math::Divide_S16Y_U16X, Table

.segment "BANK2"
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, -$7FFF, $7FFF
		STATIC_RANDOM_MIN_MAX divisor, 1, $2FFF

		.word	.loword(dividend)
		.word	.loword(divisor)
		.word	.loword(dividend / divisor)
		.if dividend .mod divisor > 0
			.word	.loword(dividend .mod divisor)
		.else
			.word	.loword(-(dividend .mod divisor))
		.endif

	.endrepeat
.code
.endroutine


.A8
.I16
.routine Divide_U16Y_S16X
	Process_Divide_16_Table Math::Divide_U16Y_S16X, Table

.segment "BANK2"
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, $FF, $FFFF
		STATIC_RANDOM_MIN_MAX divisor, -$2FF, $2FF

		.if divisor = 0
			divisor .set $100
		.endif

		.word	.loword(dividend)
		.word	.loword(divisor)
		.word	.loword(dividend / divisor)
		.if dividend .mod divisor > 0
			.word	.loword(dividend .mod divisor)
		.else
			.word	.loword(-(dividend .mod divisor))
		.endif
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Divide_S16Y_S16X
	Process_Divide_16_Table Math::Divide_S16Y_S16X, Table

.segment "BANK2"
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, -$7FFF, $7FFF
		STATIC_RANDOM_MIN_MAX divisor, -$2FF, $2FF

		.if divisor = 0
			divisor .set $100
		.endif

		.word	.loword(dividend)
		.word	.loword(divisor)
		.word	.loword(dividend / divisor)
		.if dividend .mod divisor > 0
			.word	.loword(dividend .mod divisor)
		.else
			.word	.loword(-(dividend .mod divisor))
		.endif
	.endrepeat
.code
.endroutine

.delmacro Process_Divide_16_Table

.struct Divide_32_Table
	dividend32	.dword
	divisor32	.dword
	result32	.dword
	remainder32	.dword
.endstruct


.macro	Process_Divide_32_Table routine, table
	.local Failure

	REP	#$30
.A16
.I16
	LDA	#(MATH_REPEAT - 1) * .sizeof(Divide_32_Table)

	REPEAT
		STA	tablePos
		TAX

		LDA	f:table + Divide_32_Table::dividend32, X
		STA	Math::dividend32
		LDA	f:table + Divide_32_Table::dividend32 + 2, X
		STA	Math::dividend32 + 2

		LDA	f:table + Divide_32_Table::divisor32, X
		STA	Math::divisor32
		LDA	f:table + Divide_32_Table::divisor32 + 2, X
		STA	Math::divisor32 + 2

		JSR	routine

		LDX	tablePos
		LDA	Math::result32
		CMP	f:table + Divide_32_Table::result32, X
		BNE	Failure

		LDA	Math::result32 + 2
		CMP	f:table + Divide_32_Table::result32 + 2, X
		BNE	Failure

		LDA	Math::remainder32
		CMP	f:table + Divide_32_Table::remainder32, X
		BNE	Failure

		LDA	Math::remainder32 + 2
		CMP	f:table + Divide_32_Table::remainder32 + 2, X
		BNE	Failure

		TXA
		SUB	#.sizeof(Divide_32_Table)
	UNTIL_MINUS

	SEC
	RTS

Failure:
	CLC
	RTS
.endmacro


.routine Divide_U32_U32
	Process_Divide_32_Table Math::Divide_U32_U32, Table

.segment "BANK2"
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, 1, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX divisor, 1, $FFFFFF

		.dword	dividend & $FFFFFFFF
		.dword	divisor & $FFFFFFFF
		.dword	(dividend / divisor) & $FFFFFFFF
		.dword	(dividend .mod divisor) & $FFFFFFFF
	.endrepeat
.code
.endroutine

.routine Divide_S32_S32
	Process_Divide_32_Table Math::Divide_S32_S32, Table

.segment "BANK2"
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, -$7FFFFFFF, $7FFFFFFF
		STATIC_RANDOM_MIN_MAX divisor, -$2FFFFF, $2FFFFF

		.if divisor = 0
			divisor .set $100
		.endif

		.dword	dividend & $FFFFFFFF
		.dword	divisor & $FFFFFFFF
		.dword	(dividend / divisor) & $FFFFFFFF
		.if dividend .mod divisor > 0
			.dword	(dividend .mod divisor) & $FFFFFFFF
		.else
			.dword	(-(dividend .mod divisor)) & $FFFFFFFF
		.endif
	.endrepeat
.code
.endroutine

.delmacro Process_Divide_32_Table



.struct Divide_32_8_Table
	dividend32	.dword
	divisor		.byte
	result32	.dword
	remainder	.byte
.endstruct


.routine Divide_U32_U8A
	REP	#$30
.A16
.I16
	LDA	#(MATH_REPEAT - 1) * .sizeof(Divide_32_8_Table)

	REPEAT
		STA	tablePos
		TAX

		LDA	f:Table + Divide_32_8_Table::dividend32, X
		STA	Math::dividend32
		LDA	f:Table + Divide_32_8_Table::dividend32 + 2, X
		STA	Math::dividend32 + 2

		SEP	#$20
.A8
		LDA	f:Table + Divide_32_8_Table::divisor, X
		JSR	Math::Divide_U32_U8A

		LDX	tablePos
		CMP	f:Table + Divide_32_8_Table::remainder, X
		BNE	Failure

		REP	#$20
.A16
		LDA	Math::result32
		CMP	f:Table + Divide_32_8_Table::result32, X
		BNE	Failure

		LDA	Math::result32 + 2
		CMP	f:Table + Divide_32_8_Table::result32 + 2, X
		BNE	Failure

		TXA
		SUB	#.sizeof(Divide_32_8_Table)
	UNTIL_MINUS

	SEC
	RTS

Failure:
	CLC
	RTS

.segment "BANK2"
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, 1, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX divisor, 1, $FF

		.dword	dividend
		.byte	divisor
		.dword	(dividend / divisor)
		.byte	(dividend .mod divisor)
	.endrepeat
.code
.endroutine

.A8
.I16
.routine Negate32
	REP	#$30
.A16

	STATIC_RANDOM_MIN_MAX rng, -$7FFFFFFF, $7FFFFFFF

	LDXY	#rng
	STXY	tmp
	Negate32 XY

	BranchIfXyNeConst -rng, Failure

	STATIC_RANDOM_MIN_MAX rng, -$7FFFFFFF, $7FFFFFFF
	LDXY	#rng
	STXY	tmp
	LDXY	#0
	Negate32 tmp

	LDXY	tmp
	BranchIfXyNeConst -rng, Failure


	STATIC_RANDOM_MIN_MAX rng, -$7FFFFFFF, $7FFFFFFF
	LDXY	#rng
	STXY	tmp
	LDX	#.loword(tmp) - 128
	Negate32 128, X

	LDXY	tmp
	BranchIfXyNeConst -rng, Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine

.endmodule

; vim: set ft=asm:

