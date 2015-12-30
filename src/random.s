; Randomizer module

.include "random.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/math.h"

.module Random

; These numbers were selected at random, following the rules
; listed above, I'm not 100% sure about them.
MTH_A =	59069
MTH_C =	739967

.segment "SHADOW"
	seed:			.res 4
	prevJoypadState:	.res 2
	tmp:			.res 2
.code

.exportlabel seed


.A16
.I16
.routine AddJoypadEntropy
	LDA	f:JOY1
	CMP	prevJoypadState
	IF_NE
		STA	prevJoypadState
		JSR	Rnd
	ENDIF

	.assert * = Rnd, lderror, "Bad flow"
.endroutine


.A16
.I16
.routine Rnd
	; seed = seed * MTH_A + MTH_C

	LDXY	seed
	STXY	Math::factor32
	LDY	#MTH_A
	JSR	Math::Multiply_U32_U16Y_U32XY

	CLC
	TYA
	ADC	#.loword(MTH_C)
	STA	seed
	TXA
	ADC	#.hiword(MTH_C)
	STA	seed + 2

	RTS
.endroutine


; A = max
.A8
.I16
.routine Rnd_U16A
	PHA

	JSR	Rnd

	PLX
	LDY	seed + 1
	JSR	Math::Divide_U16Y_U16X

	TXA
	RTS
.endroutine



; X = min
; Y = max
.A16
.I16
.routine Rnd_U16X_U16Y
	STX	tmp
	PHY

	JSR	Rnd

	PLA
	SEC
	SBC	tmp
	TAX

	LDY	seed + 1
	JSR	Math::Divide_U16Y_U16X

	TXA
	CLC
	ADC	tmp

	RTS
.endroutine


.endmodule

; vim: set ft=asm:

