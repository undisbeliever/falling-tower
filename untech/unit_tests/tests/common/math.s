; Unit tests modules

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "tests/tests.h"
.include "tests/static-random.inc"

.include "common/math.h"

.setcpu "65816"

.module UnitTest_Math

	UnitTestHeader Math
		UnitTest	Multiply_U8Y_U8X_UY
		UnitTest	Multiply_U16Y_U8A_U16Y
		UnitTest	Multiply_U16Y_U8A_U32XY
		UnitTest	Multiply_U16Y_U16X_U16Y
		UnitTest	Multiply_U16Y_S16X_16Y
		UnitTest	Multiply_S16Y_U16X_16Y
		UnitTest	Multiply_S16Y_S16X_S16Y
		UnitTest	Multiply_U16Y_U16X_U32XY
		UnitTest	Multiply_S16Y_S16X_S32XY
		UnitTest	Multiply_S32_S16Y_S32XY
		UnitTest	Multiply_U32_S16Y_32XY
		UnitTest	Multiply_U32_U16Y_U32XY
		UnitTest	Multiply_S32_U16Y_S32XY
		UnitTest	Multiply_U32_U32XY_U32XY
		UnitTest	Multiply_U32_S32XY_32XY
		UnitTest	Multiply_S32_U32XY_32XY
		UnitTest	Multiply_S32_S32XY_S32XY
		UnitTest	Multiply_U32XY_U8A_U32XY
		UnitTest	Multiply_S32XY_U8A_S32XY

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


.define MATH_REPEAT 100
.define TABLE_BANK "BANK2"

.segment "SHADOW"
tmp		:= tmp1
 .assert tmp + 2 = tmp2, error, "Bad alignment"
routinePtr	:= tmp3
tablePos	:= tmp4
endTable	:= tmp5




.struct Multiply_16_16_Table
	factorY		.word
	factorX		.word
	result		.word
.endstruct

.struct Multiply_16_32_Table
	factorY		.word
	factorX		.word
	result		.dword
.endstruct

.struct Multiply_32_Table
	factor32	.dword
	XY		.dword
	result		.dword
.endstruct

.struct Divide_16_Table
	dividend	.addr
	divisor		.addr
	result		.addr
	remainder	.addr
.endstruct

.struct Divide_32_8_Table
	dividend32	.dword
	divisor		.byte
	result32	.dword
	remainder	.byte
.endstruct

.struct Divide_32_Table
	dividend32	.dword
	divisor32	.dword
	result32	.dword
	remainder32	.dword
.endstruct

.macro Process_Multiply_16_16_Table routine, table
	LDX	#.loword(table)
	LDY	#.loword(routine)
	JMP	_Process_Multiply_16_16_Table
.endmacro

.macro Process_Multiply_16_32_Table routine, table
	LDX	#.loword(table)
	LDY	#.loword(routine)
	JMP	_Process_Multiply_16_32_Table
.endmacro

.macro Process_Multiply_32_Table routine, table
	LDX	#.loword(table)
	LDY	#.loword(routine)
	JMP	_Process_Multiply_32_Table
.endmacro

.macro	Process_Divide_16_Table routine, table
	LDX	#.loword(table)
	LDY	#.loword(routine)
	JMP	_Process_Divide_16_Table
.endmacro

.macro	Process_Divide_32_Table routine, table
	LDX	#.loword(table)
	LDY	#.loword(routine)
	JMP	_Process_Divide_32_Table
.endmacro


.code


.A8
.I16
.routine Multiply_U8Y_U8X_UY
	.repeat	4
		STATIC_RANDOM_MIN_MAX factorA, 0, $FF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FF

		LDY	#factorA
		LDX	#factorB
		JSR	Math::Multiply_U8Y_U8X_UY

		CPY	#factorA * factorB
		BNE	Failure
	.endrepeat

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine Multiply_U16Y_U8A_U16Y
	.repeat	4
		STATIC_RANDOM_MIN_MAX factorA, 0, $FF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		LDA	#factorA
		LDY	#factorB
		JSR	Math::Multiply_U16Y_U8A_U16Y

		CPY	#.loword(factorA * factorB)
		BNE	Failure
	.endrepeat

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine Multiply_U16Y_U8A_U32XY
	.repeat	4
		STATIC_RANDOM_MIN_MAX factorA, 0, $FF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		LDA	#factorA
		LDY	#factorB
		JSR	Math::Multiply_U16Y_U8A_U32XY

		CPY	#.loword(factorA * factorB)
		BNE	Failure
		CPX	#.hiword(factorA * factorB)
		BNE	Failure
	.endrepeat

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine Multiply_U16Y_U16X_U16Y
	Process_Multiply_16_16_Table Math::Multiply_U16Y_U16X_U16Y, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		.word	factorA
		.word	factorB
		.word	.loword(factorA * factorB)
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U16Y_S16X_16Y
	Process_Multiply_16_16_Table Math::Multiply_U16Y_S16X_16Y, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFF, $7FFF

		.word	.loword(factorA)
		.word	.loword(factorB)
		.word	.loword(factorA * factorB)
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S16Y_U16X_16Y
	Process_Multiply_16_16_Table Math::Multiply_S16Y_U16X_16Y, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFF, $7FFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		.word	.loword(factorA)
		.word	.loword(factorB)
		.word	.loword(factorA * factorB)
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S16Y_S16X_S16Y
	Process_Multiply_16_16_Table Math::Multiply_S16Y_S16X_S16Y, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFF, $7FFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFF, $7FFF

		.word	.loword(factorA)
		.word	.loword(factorB)
		.word	.loword(factorA * factorB)
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U16Y_U16X_U32XY
	Process_Multiply_16_32_Table Math::Multiply_U16Y_U16X_U32XY, Table

.segment TABLE_BANK
Table:
	; This one was caught by the Unit Testing
	.word	.loword($e587)
	.word	.loword($6af2)
	.dword	($e587 * $6af2) & $FFFFFFFF

	; More tests
	.repeat	MATH_REPEAT - 1
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		.word	.loword(factorA)
		.word	.loword(factorB)
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S16Y_S16X_S32XY
	Process_Multiply_16_32_Table Math::Multiply_S16Y_S16X_S32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFF, $7FFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFF, $7FFF

		.word	.loword(factorA)
		.word	.loword(factorB)
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S32_S16Y_S32XY
	Process_Multiply_32_Table Math::Multiply_S32_S16Y_S32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFFFFFF, $7FFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFF, $7FFF

		.dword	factorA & $FFFFFFFF
		.dword	.loword(factorB)
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U32_S16Y_32XY
	Process_Multiply_32_Table Math::Multiply_U32_S16Y_32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFF, $7FFF

		.dword	factorA
		.dword	.loword(factorB)
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U32_U16Y_U32XY
	Process_Multiply_32_Table Math::Multiply_U32_U16Y_U32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		.dword	factorA
		.dword	factorB
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S32_U16Y_S32XY
	Process_Multiply_32_Table Math::Multiply_S32_U16Y_S32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFFFFFF, $7FFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFF

		.dword	factorA & $FFFFFFFF
		.dword	factorB
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U32_U32XY_U32XY
	Process_Multiply_32_Table Math::Multiply_U32_U32XY_U32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFFFFFF

		.dword	factorA
		.dword	factorB
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U32_S32XY_32XY
	Process_Multiply_32_Table Math::Multiply_U32_S32XY_32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFFFFFF, $7FFFFFFF

		.dword	factorA
		.dword	factorB & $FFFFFFFF
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S32_U32XY_32XY
	Process_Multiply_32_Table Math::Multiply_S32_U32XY_32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFFFFFF, $7FFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FFFFFFFF

		.dword	factorA & $FFFFFFFF
		.dword	factorB
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_S32_S32XY_S32XY
	Process_Multiply_32_Table Math::Multiply_S32_S32XY_S32XY, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFFFFFF, $7FFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, -$7FFFFFFF, $7FFFFFFF

		.dword	factorA & $FFFFFFFF
		.dword	factorB & $FFFFFFFF
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code
.endroutine


.A8
.I16
.routine Multiply_U32XY_U8A_U32XY
	Process_Multiply_32_Table Multiply_U32XY_U8A_U32XY_Caller, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, 0, $FFFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FF

		.dword	factorA
		.dword	factorB
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code

.A16
.I16
Multiply_U32XY_U8A_U32XY_Caller:
	TYA
	LDXY	Math::factor32
	SEP	#$20
.A8
	JMP	Math::Multiply_U32XY_U8A_U32XY
.endroutine


.A8
.I16
.routine Multiply_S32XY_U8A_S32XY
	Process_Multiply_32_Table Multiply_S32XY_U8A_S32XY_Caller, Table

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX factorA, -$7FFFFFFF, $7FFFFFFF
		STATIC_RANDOM_MIN_MAX factorB, 0, $FF

		.dword	(factorA) & $FFFFFFFF
		.dword	factorB
		.dword	(factorA * factorB) & $FFFFFFFF
	.endrepeat
.code

.A16
.I16
Multiply_S32XY_U8A_S32XY_Caller:
	TYA
	LDXY	Math::factor32
	SEP	#$20
.A8
	JMP	Math::Multiply_S32XY_U8A_S32XY
.endroutine


.A8
.I16
.routine Divide_U16Y_U8A
	.repeat	4
		STATIC_RANDOM_MIN_MAX dividend, $FF, $FFFF
		STATIC_RANDOM_MIN_MAX divisor, 1, $FF

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



.A8
.I16
.routine Divide_U16Y_U16X
	Process_Divide_16_Table Math::Divide_U16Y_U16X, Table

.segment TABLE_BANK
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

.segment TABLE_BANK
Table:
	.repeat	MATH_REPEAT
		STATIC_RANDOM_MIN_MAX dividend, -$7FFF, $7FFF
		STATIC_RANDOM_MIN_MAX divisor, 1, $2FFF

		.word	.loword(dividend)
		.word	.loword(divisor)
		.word	.loword(dividend / divisor)
		.if (dividend .mod divisor) > 0
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

.segment TABLE_BANK
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

.segment TABLE_BANK
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


.A8
.I16
.routine Divide_U32_U32
	Process_Divide_32_Table Math::Divide_U32_U32, Table

.segment TABLE_BANK
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


.A8
.I16
.routine Divide_S32_S32
	Process_Divide_32_Table Math::Divide_S32_S32, Table

.segment TABLE_BANK
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


.A8
.I16
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

.segment TABLE_BANK
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

.code

.proc GotoRoutinePtr
	JMP	(routinePtr)
.endproc


; IN: X - table
; IN: Y - routine
.A8
.proc _Process_Multiply_16_16_Table
	.assert .bankbyte(*) & $7E < $30, error, "Can't access shadow"

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
.I16
	STY	routinePtr

	TXA
	ADD	#MATH_REPEAT * .sizeof(Multiply_16_16_Table)
	STA	endTable

	TXA
	REPEAT
		STA	tablePos
		TAX

		LDA	f:tableBankOffset + Multiply_16_16_Table::factorY, X
		TAY
		LDA	f:tableBankOffset + Multiply_16_16_Table::factorX, X
		TAX

		PHP
		JSR	GotoRoutinePtr
		PLP

		LDX	tablePos
		TYA
		CMP	f:tableBankOffset + Multiply_16_16_Table::result, X
		BNE	Failure

		TXA
		ADD	#.sizeof(Multiply_16_16_Table)
		CMP	endTable
	UNTIL_GE

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


; IN: X - table
; IN: Y - routine
.A8
.proc _Process_Multiply_16_32_Table
	.assert .bankbyte(*) & $7E < $30, error, "Can't access shadow"

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
.I16
	STY	routinePtr

	TXA
	ADD	#MATH_REPEAT * .sizeof(Multiply_16_32_Table)
	STA	endTable

	TXA
	REPEAT
		STA	tablePos
		TAX

		LDA	f:tableBankOffset + Multiply_16_32_Table::factorY, X
		TAY
		LDA	f:tableBankOffset + Multiply_16_32_Table::factorX, X
		TAX

		PHP
		JSR	GotoRoutinePtr
		PLP

		CPY	Math::product32
		BNE	Failure
		CPX	Math::product32 + 2
		BNE	Failure

		TXA
		LDX	tablePos
		CMP	f:tableBankOffset + Multiply_16_32_Table::result + 2, X
		BNE	Failure

		TYA
		CMP	f:tableBankOffset + Multiply_16_32_Table::result, X
		BNE	Failure

		TXA
		ADD	#.sizeof(Multiply_16_32_Table)
		CMP	endTable
	UNTIL_GE

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


; IN: X - table
; IN: Y - routine
.A8
.proc _Process_Multiply_32_Table
	.assert .bankbyte(*) & $7E < $30, error, "Can't access shadow"

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
.I16
	STY	routinePtr

	TXA
	ADD	#MATH_REPEAT * .sizeof(Multiply_32_Table)
	STA	endTable

	TXA
	REPEAT
		STA	tablePos
		TAX

		LDA	f:tableBankOffset + Multiply_32_Table::factor32, X
		STA	Math::factor32
		LDA	f:tableBankOffset + Multiply_32_Table::factor32 + 2, X
		STA	Math::factor32 + 2

		LDA	f:tableBankOffset + Multiply_32_Table::XY, X
		TAY
		LDA	f:tableBankOffset + Multiply_32_Table::XY + 2, X
		TAX

		PHP
		JSR	GotoRoutinePtr
		PLP

		CPY	Math::product32
		BNE	Failure
		CPX	Math::product32 + 2
		BNE	Failure

		TXA
		LDX	tablePos
		CMP	f:tableBankOffset + Multiply_32_Table::result + 2, X
		BNE	Failure

		TYA
		CMP	f:tableBankOffset + Multiply_32_Table::result, X
		BNE	Failure

		TXA
		ADD	#.sizeof(Multiply_32_Table)
		CMP	endTable
	UNTIL_GE

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


; IN: X - table
; IN: Y - routine
.A8
.proc _Process_Divide_16_Table
	.assert .bankbyte(*) & $7E < $30, error, "Can't access shadow"

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
.I16
	STY	routinePtr

	TXA
	ADD	#MATH_REPEAT * .sizeof(Divide_16_Table)
	STA	endTable

	TXA
	REPEAT
		STA	tablePos
		TAX

		LDA	f:tableBankOffset + Divide_16_Table::dividend, X
		TAY
		LDA	f:tableBankOffset + Divide_16_Table::divisor, X
		TAX

		PHP
		JSR	GotoRoutinePtr
		PLP

		TXA
		LDX	tablePos
		CMP	f:tableBankOffset + Divide_16_Table::remainder, X
		BNE	Failure

		TYA
		CMP	f:tableBankOffset + Divide_16_Table::result, X
		BNE	Failure

		TXA
		ADD	#.sizeof(Divide_16_Table)
		CMP	endTable
	UNTIL_GE

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc


; IN: X - table
; IN: Y - routine
.A8
.proc	_Process_Divide_32_Table
	.assert .bankbyte(*) & $7E < $30, error, "Can't access shadow"

	LDA	#$7E
	PHA
	PLB

	REP	#$30
.A16
.I16
	STY	routinePtr

	TXA
	ADD	#MATH_REPEAT * .sizeof(Divide_32_Table)
	STA	endTable

	TXA
	REPEAT
		STA	tablePos
		TAX

		LDA	f:tableBankOffset + Divide_32_Table::dividend32, X
		STA	Math::dividend32
		LDA	f:tableBankOffset + Divide_32_Table::dividend32 + 2, X
		STA	Math::dividend32 + 2

		LDA	f:tableBankOffset + Divide_32_Table::divisor32, X
		STA	Math::divisor32
		LDA	f:tableBankOffset + Divide_32_Table::divisor32 + 2, X
		STA	Math::divisor32 + 2

		PHP
		JSR	GotoRoutinePtr
		PLP

		LDX	tablePos
		LDA	Math::result32
		CMP	f:tableBankOffset + Divide_32_Table::result32, X
		BNE	Failure

		LDA	Math::result32 + 2
		CMP	f:tableBankOffset + Divide_32_Table::result32 + 2, X
		BNE	Failure

		LDA	Math::remainder32
		CMP	f:tableBankOffset + Divide_32_Table::remainder32, X
		BNE	Failure

		LDA	Math::remainder32 + 2
		CMP	f:tableBankOffset + Divide_32_Table::remainder32 + 2, X
		BNE	Failure

		TXA
		ADD	#.sizeof(Divide_32_Table)
		CMP	endTable
	UNTIL_GE

	SEC
	RTS

Failure:
	CLC
	RTS
.endproc

.segment TABLE_BANK
	tableBankOffset = .bankbyte(*) << 16


.delmacro Process_Multiply_16_16_Table
.delmacro Process_Multiply_16_32_Table
.delmacro Process_Multiply_32_Table
.delmacro Process_Divide_16_Table
.delmacro Process_Divide_32_Table

.endmodule

; vim: set ft=asm:

