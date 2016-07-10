; Randomizer module

.include "random.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/math.h"

.module Random

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
    ; LCPR parameters are the same as cc65 (MIT license)
    ;
	; seed = seed * 0x01010101 + 0x31415927

    SEP #$20
.A8
	CLC
	LDA	seed + 0
	ADC	seed + 1
	STA	seed + 1
	ADC	seed + 2
	STA	seed + 2
	ADC	seed + 3
	STA	seed + 3

	REP	#$31
.A16
	; carry clear
	LDA	seed + 0
	ADC	#$5927
	STA	seed + 0

	LDA	seed + 2
	ADC	#$3141
	STA	seed + 2

	RTS
.endroutine


; Y = number of probabilities
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

