; Unit tests modules

.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"
.include "tests/tests.h"
.include "tests/static-random.inc"

.include "common/incdec.inc"

.setcpu "65816"

.module UnitTest_incdec

	UnitTestHeader incdec
		UnitTest	INCXY
		UnitTest	DECXY
		UnitTest	INC16
		UnitTest	INC32
		UnitTest	Decrement32
		UnitTest	INCSAT
		UnitTest	DECSAT
	EndUnitTestHeader


.segment "SHADOW"
	tmp := tmp1

.code


.A8
.I16
.routine INCXY
	STATIC_RANDOM_MIN_MAX rng, 0, $FFFFFFFF

	LDXY	#rng
	INCXY

	BranchIfXyNeConst rng + 1, Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine DECXY
	STATIC_RANDOM_MIN_MAX rng, 0, $FFFFFFFF

	LDXY	#rng
	DECXY

	BranchIfXyNeConst rng - 1, Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine INC16
	LDY	#$FFFF
	STY	tmp

	INC16	tmp

	LDY	tmp
	BNE	Failure


	LDY	#$FFFF
	STY	tmp

	LDX	#tmp
	INC16	0, X

	LDY	tmp
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine INC32
	REP	#$30
.A16

	LDXY	#$FFFFF
	INC32	XY

	BranchIfXyNeConst $100000, Failure


	LDXY	#$FFFF
	STXY	tmp
	INC32	tmp

	LDXY	tmp
	BranchIfXyNeConst $10000, Failure


	LDXY	#$FFFFFF
	STXY	tmp
	LDX	#.loword(tmp) - 128
	INC32 128, X

	LDXY	tmp
	BranchIfXyNeConst $1000000, Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine Decrement32
	REP	#$30
.A16

	LDXY	#0
	Decrement32 XY

	BranchIfXyNeConst $FFFFFFFF, Failure


	STZ	tmp
	STZ	tmp + 2

	Decrement32 tmp

	LDXY	tmp
	BranchIfXyNeConst $FFFFFFFF, Failure


	STZ	tmp
	STZ	tmp + 2

	LDX	#.loword(tmp) - 128
	Decrement32 128, X

	LDXY	tmp
	BranchIfXyNeConst $FFFFFFFF, Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine INCSAT
	REP	#$30
.A16

	LDA	#128
	INCSAT

	CMP	#129
	BNE	Failure

	LDA	#$FFFF
	INCSAT
	CMP	#$FFFF
	BNE	Failure

	SEP	#$20
.A8
	LDA	#99
	INCSAT	#100
	CMP	#100
	BNE	Failure

	INCSAT	#100
	CMP	#100
	BNE	Failure

	LDA	#200
	INCSAT	#100
	CMP	#100
	BNE	Failure


	LDA	#128
	STA	tmp

	LDA	#127
	INCSAT	tmp
	CMP	#128
	BNE	Failure

	INCSAT	tmp
	CMP	#128
	BNE	Failure

	LDA	#200
	INCSAT	tmp
	CMP	#128
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine


.A8
.I16
.routine DECSAT
	REP	#$30
.A16

	LDA	#128
	DECSAT

	CMP	#127
	BNE	Failure

	SEC
	RTS

	LDA	#0
	DECSAT
	CMP	#0
	BNE	Failure

	SEP	#$20
.A8
	LDA	#101
	DECSAT	#100
	CMP	#100
	BNE	Failure

	DECSAT	#100
	CMP	#100
	BNE	Failure

	LDA	#20
	DECSAT	#100
	CMP	#100
	BNE	Failure


	LDA	#128
	STA	tmp

	LDA	#129
	DECSAT	tmp
	CMP	#128
	BNE	Failure

	DECSAT	tmp
	CMP	#128
	BNE	Failure

	LDA	#20
	DECSAT	tmp
	CMP	#128
	BNE	Failure

	SEC
	RTS

Failure:
	CLC
	RTS
.endroutine

.endmodule

; vim: set ft=asm:

