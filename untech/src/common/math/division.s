
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/modules.inc"
.include "common/incdec.inc"

.include "common/math.h"

; Note: I have to use `RDDIV_DP` / `RDMPY_DP` / `divisor_DP` in order to
; prevent a Suspicious address expression error in ca65.
RDMPY_DP := .lobyte(RDMPY)
RDDIV_DP := .lobyte(RDDIV)

.setcpu "65816"

.module Math

.exportlabel dividend32
.exportlabel divisor32
.exportlabel remainder32



.segment "SHADOW"
	dividend32:	.res 4
	divisor32:	.res 4
	remainder32:	.res 4

	result32 := dividend32

	; Divide_U32_U32 requires these values to exist in the same page
	.assert .hibyte(dividend32) = .hibyte(remainder32 + 3), lderror, "Bad Value"

	tmp:		.res 2


.code

.A8
.I16
.routine Divide_U16Y_U8A
	PHD
	PEA	.hibyte(WRDIV) << 8
	PLD

	STY	z:<WRDIV
	STA	z:<WRDIVB			; Load to SNES division registers

	; Wait 16 Cycles
	PHB				; 3
	PLB				; 4
	PHB				; 3
	PLB				; 4

	LDY	z:RDDIV_DP		; 1 from instruction fetch
	LDX	z:RDMPY_DP

	PLD
	RTS
.endroutine



.I16
.routine Divide_U16Y_S16X
	CPX	#$8000
	IF_GE
		PHP
		REP	#$30
.A16

		TXA
		NEG
		TAX

		JSR	Divide_U16Y_U16X

		; Result is negative
		TYA
		NEG
		TAY

		PLP
		RTS
	ENDIF

	BRA	Divide_U16Y_U16X
.endroutine



.I16
.routine Divide_S16Y_S16X
	CPY	#$8000
	IF_GE
		PHP
		REP	#$30
.A16
		; dividend Negative
		TYA
		NEG
		TAY

		CPX	#$8000
		IF_GE
			; divisor Negative
			TXA
			NEG
			TAX

			JSR	Divide_U16Y_U16X

			; Result is positive
			PLP
			RTS
		ENDIF

		; Else - divisor is positive
		JSR	Divide_U16Y_U16X

		; Result is negative
		TYA
		NEG
		TAY

		PLP
		RTS
	ENDIF
	; Else - dividend is positive

	CPX	#$8000
	IF_GE
		PHP
		REP	#$30
.A16

		TXA
		NEG
		TAX

		JSR	Divide_U16Y_U16X

		; Result is negative
		TYA
		NEG
		TAY

		PLP
		RTS
	ENDIF

	BRA	Divide_U16Y_U16X
.endroutine



; This one is here because it is the most common of the signed divisions
.I16
.routine Divide_S16Y_U16X
	CPY	#$8000
	IF_GE
		PHP
		REP	#$30
.A16

		TYA
		NEG
		TAY

		JSR	Divide_U16Y_U16X

		; Result is negative
		TYA
		NEG
		TAY

		PLP
		RTS
	ENDIF

	.assert * = Divide_U16Y_U16X, lderror, "Bad Flow"
.endroutine



; DB anywhere
.I16
.routine Divide_U16Y_U16X
	; Inspiration: http://codebase64.org/doku.php?id=base:16bit_division_16-bit_result

	; if divisor < 256
	;	calculate using SNES registers
	; else
	; 	remainder = 0
	; 	repeat 16 times
	; 		remainder << 1 | MSB(dividend)
	; 		dividend << 1
	; 		if (remainder >= divisor)
	;			remainder -= divisor
	;			result++

divisor := tmp

; fixes Illegal addressing mode error
divisor_DP := .lobyte(divisor)

	PHD
	PHP

	CPX	#$0100
	IF_LT

		REP	#$30
.I16
.A16
		LDA	#.hibyte(WRDIV) << 8
		TCD

		STY	z:<WRDIV

		SEP	#$30
.I8
		STX	z:<WRDIVB

		; Wait 16 Cycles
		NOP				; 2
		PHD				; 4
		PLD				; 5
		PLP				; 4
.I16
		LDY	z:RDDIV_DP		; 1 from instruction fetch
		LDX	z:RDMPY_DP

		PLD
		RTS
	ENDIF

	; Else
	; X > 256
		REP	#$30
.I16
.A16
		; using DP to access divisor saves 2 cycles
		; and allows this routine to be called with DB anywhere
		.assert divisor_DP <> $FF, lderror, "Bad DP value"
		LDA	#.hibyte(divisor) << 8
		TCD

		STX	z:divisor_DP
		LDX	#0			; Remainder

		.repeat 16
			TYA			; Dividend / result
			ASL A
			TAY
			TXA 			; Remainder
			ROL A
			TAX

			SUB	z:divisor_DP
			IF_C_SET		; C set if positive
				TAX
				INY 		; Result
			ENDIF
		.endrepeat

		PLP
		PLD
		RTS

	; Endif
.endroutine



.routine Divide_S32_S32
	PHP
	REP	#$30
.A16
.I16
	LDY	dividend32 + 2
	IF_MINUS
		LDA	dividend32
		EOR	#$FFFF
		CLC
		ADC	#1
		STA	dividend32
		TYA
		EOR	#$FFFF
		ADC	#0
		STA	dividend32 + 2

		LDY	divisor32 + 2
		IF_MINUS
		; divisor is negative
			LDA	divisor32
			EOR	#$FFFF
			CLC
			ADC	#1
			STA	divisor32
			TYA
			EOR	#$FFFF
			ADC	#0
			STA	divisor32 + 2

			; result is positive
			BRA	_Divide_U32_U32__AfterPHP
		ENDIF

		; Else, divisor is positive

		JSR	Divide_U32_U32

		; only 1 negative, result negative
		Negate32	result32

		PLP
		RTS
	ENDIF

	; dividend is positive

	LDY	divisor32 + 2
	IF_MINUS
	; divisor is negative
		LDA	divisor32
		EOR	#$FFFF
		CLC
		ADC	#1
		STA	divisor32
		TYA
		EOR	#$FFFF
		ADC	#0
		STA	divisor32 + 2

		Negate32 divisor32

		JSR	Divide_U32_U32

		; only 1 negative, result negative
		Negate32 result32

		PLD
		PLP
		RTS
	ENDIF

	; result is positive
	BRA	_Divide_U32_U32__AfterPHP
.endroutine


.routine Divide_U32_U32

; fixes Illegal addressing mode error
dividend32_DP	= .lobyte(dividend32)
divisor32_DP	= .lobyte(divisor32)
result32_DP	= .lobyte(result32)
remainder32_DP	= .lobyte(remainder32)

	; Inspiration: http://codebase64.org/doku.php?id=base:16bit_division_16-bit_result

	; remainder = 0
	; Repeat 32 times:
	; 	remainder << 1 | MSB(dividend)
	; 	dividend << 1
	; 	if (remainder >= divisor)
	;		remainder -= divisor
	;		result++

	PHP
	REP	#$30

.A16
.I16
::_Divide_U32_U32__AfterPHP:

	PHD
	LDA	#.hibyte(dividend32) << 8
	TCD

	STZ	z:remainder32_DP
	STZ	z:remainder32_DP + 2

	LDX	#32
	REPEAT
		ASL	z:dividend32_DP
		ROL	z:dividend32_DP + 2
		ROL	z:remainder32_DP
		ROL	z:remainder32_DP + 2

		LDA	z:remainder32_DP
		SEC
		SBC	z:divisor32_DP
		TAY
		LDA	z:remainder32_DP + 2
		SBC	z:divisor32_DP + 2
		IF_C_SET
			STY	z:remainder32_DP
			STA	z:remainder32_DP + 2
			INC	z:result32_DP		; result32 = dividend32, no overflow possible
		ENDIF
		DEX
	UNTIL_ZERO

	PLD
	PLP
	RTS
.endroutine



.routine Divide_U32_U8A
	PHP
	PHD

	PEA	.hibyte(WRDIV) << 8
	PLD

	SEP	#$30
.A8
.I8
	LDY	dividend32 + 3
	STY	z:<WRDIVL
	STZ	z:<WRDIVH

	STA	z:<WRDIVB

	; Wait 16 cycles
	PHD			; 4
	PLD			; 5
	NOP			; 2
	LDX	dividend32 + 2	; 4 - preload next byte
	LDY	z:RDDIV_DP	; 1 from instruction fetch
	STY	result32 + 3


	LDY	z:RDMPY_DP
	STX	z:<WRDIVL
	STY	z:<WRDIVH

	STA	z:<WRDIVB

	; Wait 16 cycles
	PHD			; 4
	PLD			; 5
	NOP			; 2
	LDX	dividend32 + 1	; 4 - preload next byte
	LDY	z:RDDIV_DP	; 1 from instruction fetch
	STY	result32 + 2


	LDY	z:RDMPY_DP
	STX	z:<WRDIVL
	STY	z:<WRDIVH

	STA	z:<WRDIVB

	; Wait 16 cycles
	PHD			; 4
	PLD			; 5
	NOP			; 2
	LDX	dividend32 + 0	; 4 - preload next byte
	LDY	z:RDDIV_DP	; 1 from instruction fetch
	STY	result32 + 1


	LDY	z:RDMPY_DP
	STX	z:<WRDIVL
	STY	z:<WRDIVH

	STA	z:<WRDIVB

	; Wait 16 cycles
	PHB			; 3
	PLB			; 4
	PHB			; 3
	PLB			; 4
	LDY	z:RDDIV_DP	; 2 from instruction fetch
	STY	result32 + 0

	LDA	z:RDMPY_DP	; remainder

	PLD
	PLP
	RTS
.endroutine

.endmodule

