
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/modules.inc"
.include "common/incdec.inc"

.include "common/math.h"

; Note: I have to use `RDMPY_DP` in order to
; prevent a Suspicious address expression error in ca65.
RDMPY_DP := .lobyte(RDMPY)
RDMPYL_DP := .lobyte(RDMPYL)
RDMPYH_DP := .lobyte(RDMPYH)

.setcpu "65816"

.module Math

.exportlabel product32
.exportlabel factor32


.segment "SHADOW"
	product32:	.res 4
	factor32:	.res 4
	tmp1:		.res 2
	tmp2:		.res 2
	tmp3:		.res 2

.code


.routine Multiply_U8Y_U8X_UY
	PHP
	SEP	#$20
.A8
	TYA
	STA	f:WRMPYA

	TXA
	STA	f:WRMPYB

	; Wait 8 cycles
	REP	#$30		; 3
	NOP			; 2
	LDA	f:RDMPY		; 3 instruction fetch

	TAY
	PLP
	RTS
.endroutine


.A8
.I16
Multiply_S16Y_U8A_S16Y:
.routine Multiply_U16Y_U8A_U16Y
; 1 cycle faster than using DP

	STA	f:WRMPYA
	TYA
	STA	f:WRMPYB

	; Wait 8 cycles
	STY	tmp1	; 5
	REP	#$30	; 3
.A16
	LDA	f:RDMPY
	TAY
	SEP	#$20
.A8
	LDA	tmp1 + 1
	STA	f:WRMPYB

	; Wait 8 cycles
	REP	#$31	; 3
	TYA		; 2
	XBA		; 3
	SEP	#$20	; 3
	ADC	f:RDMPY
	XBA
	TAY

	RTS
.endroutine


.A8
.I16
Multiply_U16Y_U8A_U32:
.routine Multiply_U16Y_U8A_U32XY
; Using DP faster than far by 2 cycles
	PHD
	PEA	.hibyte(WRMPYA) << 8
	PLD

	STA	z:<WRMPYA
	TYA
	STA	z:<WRMPYB

	; Wait 8 Cycles
	STY	product32	; 5
	LDA	product32 + 1	; 4

	LDY	z:RDMPY_DP
	STY	product32

	STA	z:<WRMPYB	; WRMPYA already set

	; Wait 8 cycles
	REP	#$31		; 3 - also clear carry
.A16
	LDA	product32 + 1	; 5
	AND	#$00FF
	ADC	z:RDMPY_DP

	STA	product32 + 1
	LDY	product32

	SEP	#$20
.A8
	LDA	#0
	XBA
	TAX			; 16 bits transfered
	STX	product32 + 2

	PLD
	RTS
.endroutine


Multiply_U16Y_S16X_16Y:
Multiply_S16Y_U16X_16Y:
Multiply_S16Y_S16X_S16Y:
.routine Multiply_U16Y_U16X_U16Y
	;      Y y
	; *    X x
	; -----------
	;      y*x
	; +  Y*x
	; +  y*X

tmpY = tmp1
tmpX = tmp2

	PHP
	PHD
	REP	#$30
.A16
.I16
	LDA	#.hibyte(WRMPYA) << 8
	TCD

	SEP	#$20
.A8
	TXA
	STA	z:<WRMPYA

	TYA
	STA	z:<WRMPYB

	; Wait 8 Cycles
	STY	tmpY  		; 5
	STX	tmpX		; 5

	LDX	z:RDMPY_DP	; yl*xl

	LDA	tmpY + 1	; last use of tmpY to hold Y
	STA	z:<WRMPYB

	; Wait 8 Cycles
	STX	tmp1		; 5
	LDA	tmp1 + 1	; 4
	ADC	z:RDMPY_DP	; yH*xl	; no carry needed
	STA	tmp1 + 1


	LDA	tmpX + 1
	STA	z:<WRMPYA

	TYA
	STA	z:<WRMPYB

	; Wait 8 cycles
	CLC			; 2
	LDA	tmp1 + 1	; 4
	ADC	z:RDMPY_DP	; 2 - load address yL*xH
	STA	tmp1 + 1

	LDY	tmp1

	PLD
	PLP
	RTS
.endroutine


.I16
.routine Multiply_U16Y_U16X_U32XY
	;       Y y
	;   *   X x
	; -----------
	;       y*x
	;     Y*x	; no carry needed $FF * $FF + $FF < $FFFF
	; + c y*X
	; + Y*X

tmpY = tmp1
tmpX = tmp2

	PHP
	PHD
	REP	#$30
.A16
.I16
	LDA	#.hibyte(WRMPYA) << 8
	TCD

	SEP	#$20
.A8

	TXA
	STA	z:<WRMPYA

	TYA
	STA	z:<WRMPYB

	; Wait 8 Cycles
	STY	tmpY  		; 5
	STX	tmpX		; 5

	LDX	z:RDMPY_DP	; xL * yL

	LDA	tmpY + 1
	STA	z:<WRMPYB

	; MUST NOT USE Y
	; Wait 8 Cycles
	STX	product32	; 5
	REP	#$31		; 3
.A16	; c clear
	TXA
	XBA
	AND	#$00FF		; A is bits 8-15 of X
	ADC	z:RDMPY_DP	; xL * yH
	STA	product32 + 1

	SEP	#$20
.A8
	LDA	tmpX + 1	; High byte of X
	STA	z:<WRMPYA

	TYA			; Y not set above
	STA	z:<WRMPYB

	; Wait 8 cycles
	REP	#$31		; 3
.A16	; c clear
	LDA	product32 + 1	; 5
	ADC	z:RDMPY_DP	; xH * yL
	STA	product32 + 1

	SEP	#$20
.A8
	LDA	#0
	ROL
	STA	product32 + 3

	LDA	tmpY + 1
	STA	z:<WRMPYB

	; Wait 8 cycles
	REP	#$31		; 3
.A16	; c clear
	LDA	product32 + 2	; 5
	ADC	z:RDMPY_DP	; xH * yH
	STA	product32 + 2
	TAX
	LDY	product32

	PLD
	PLP
	RTS
.endroutine


.I16
.routine Multiply_S16Y_S16X_S32XY
	CPY	#$8000
	IF_LT
		; Y is Positive

		CPX	#$8000
		BLT	Multiply_U16Y_U16X_U32XY

		; Y is Positive, X is Negative
		STX	factor32 + 0
		LDX	#$FFFF
		STX	factor32 + 2

		BRA	Multiply_S32_U16Y_S32XY
	ENDIF

	; Y is Negative
	STY	factor32 + 0
	LDY	#$FFFF
	STY	factor32 + 2

	TXY

	.assert * = Multiply_S32_S16Y_S32XY, lderror, "Bad Flow"
.endroutine


.I16
Multiply_U32_S16Y_32XY:
.routine Multiply_S32_S16Y_S32XY
	CPY	#$8000
	IF_GE
		LDX	#$FFFF
		JMP	Multiply_S32_S32XY_S32XY
	ENDIF

	.assert * = Multiply_U32_U16Y_U32XY, lderror, "Bad Flow"
.endroutine


; Moving to a macro as it is use in both
; Multiply_U32_U16Y_U32XY and Multiply_U32_U32XY_U32XY
; REQUIRES: 8 bit A, 16 bit Index, DP access Multiplication
; RETURNS: 8 bit A, 8 bit Index
.macro _Multiply_S32_U16Y_product32
	.assert .asize = 8, error, "Bad asize"
	.assert .isize = 16, error, "Bad asize"

	STY	tmpY
	TYA			; Yl
	IF_ZERO
		LDY	#0
		STY	product32 + 0
		STY	product32 + 2
		SEP	#$30
		BRA	SkipYl
	ENDIF
	STA	z:<WRMPYA

	LDA	factor32 + 0
	STA	z:<WRMPYB

	REP	#$21
.A16	; c clear

	; Wait 8 Cycles
	LDY	factor32 + 1	; 5
	LDX	factor32 + 2	; 5
	LDA	z:RDMPY_DP	; f0*Yl

	SEP	#$10
.I8
	STY	z:<WRMPYB

	; Wait 8 cycles
	STA	product32 + 0	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; f1*Yl

	STX	z:<WRMPYB

	; Wait 8 cycles
	STA	product32 + 1	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; f2*Yl


	LDX	factor32 + 3
	STX	z:<WRMPYB

	; Wait 8 cycles
	STA	product32 + 2	; 5
	SEP	#$20

.A8
	XBA
	ADC	z:RDMPY_DP	; f3*Yl
	STA	product32 + 3


SkipYl:
	; This check is preformed here instead of at start
	; because I would have to load factor32 to XY which wastes cycles
	LDA	tmpY + 1	; Yh
	BEQ	SkipYh

	STA	z:<WRMPYA

	LDA	factor32 + 0
	STA	z:<WRMPYB

	REP	#$21
.A16	; c clear

	; Wait 8 Cycles
	LDY	factor32 + 1	; 5
	LDX	factor32 + 2	; 5
	LDA	z:RDMPY_DP	; f0*Yh

	STY	z:<WRMPYB

	; Wait 8 cycles
	STA	mathTmp + 0	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; f1*Yh

	STX	z:<WRMPYB

	; Wait 8 cycles
	STA	mathTmp + 1	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; f2*Yh
	TAX

	; Add 2 halves together
	; Could not combine with previous, always caused an off by 1 error
	CLC
	LDA	mathTmp + 0
	ADC	product32 + 1
	STA	product32 + 1

	SEP	#$20
.A8
	TXA
	ADC	product32 + 3
	STA	product32 + 3

SkipYh:
.endmacro

.I16
Multiply_S32_U16Y_S32XY:
.routine Multiply_U32_U16Y_U32XY
	;      f3 f2 f1 f0
	;  *         Yh Yl
	; ------------------
	;            f0*Yl
	; +       f1*Yl
	; +    f2*Yl
	; + f3*Yl
	; +       f0*Yh
	; +    f1*Yh
	; + f2*Yh

tmpY	:= tmp1
mathTmp := tmp2
.assert mathTmp + 2 = tmp3, error, "Bad Flow"

	PHD
	PHP

	REP	#$31
.A16
	LDA	#WRMPYA & $FF00
	TCD

	SEP	#$20
.A8
	_Multiply_S32_U16Y_product32

	PLP
.I16
	LDXY	product32

	PLD
	RTS
.endroutine


.I16
Multiply_U32_S32XY_32XY:
Multiply_S32_U32XY_32XY:
Multiply_S32_S32XY_S32XY:
.routine Multiply_U32_U32XY_U32XY
	;      f3 f2 f1 f0
	;  *   Xh Xl Yh Yl
	; ------------------
	;            f1*Yl
	; +       f1*Yl
	; +  c f1*Yl
	; + f1*Xl
	; +       f0*Yh
	; +    f1*Yh
	; + f2*Yh
	; +    f0*Xl
	; + f1*Xl
	; + f0*Xh

tmpY	:= tmp1
mathTmp := tmp2
.assert mathTmp + 2 = tmp3, error, "Bad Flow"
	PHP
	PHD

	REP	#$31
.A16
	LDA	#WRMPYA & $FF00
	TCD

	SEP	#$20
.A8
	PHX

	_Multiply_S32_U16Y_product32
.A8
.I8
	LDY	factor32 + 0

	PLX
	BEQ	SkipXl
	STX	z:<WRMPYA	; Xl

	STY	z:<WRMPYB

	REP	#$21
.A16	; c clear

	; Wait 8 Cycles
	LDX	factor32 + 1	; 5
	NOP			; 4
	LDA	z:RDMPY_DP	; f0*Xl

	STX	z:<WRMPYB

	; Wait 8 cycles
	STA	mathTmp + 0	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; f1*Xl
	STA	mathTmp + 1

	LDA	mathTmp + 0
	CLC
	ADC	product32 + 2
	STA	product32 + 2

SkipXl:
	PLX
	BEQ	SkipXh
	STX	z:<WRMPYA	; Xh
	STY	z:<WRMPYB

	; Wait 8 cycles
	SEP	#$20		; 3
.A8
	LDA	product32 + 3	; 4
	CLC			; 2
	ADC	z:RDMPYL_DP	; f0*Xh
	STA	product32 + 3
SkipXh:

	PLD
	PLP
.I16
	LDXY	product32
	RTS
.endroutine


.A8
.I16
Multiply_S32XY_U8A_S32XY:
.routine Multiply_U32XY_U8A_U32XY
	;      Xh Xl Yh Yl
	;  *             A
	; ------------------
	;             A*Yl
	; +        A*Yh
	; +     A*Xl
	; +  A*Xh

tmpY = tmp1
tmpX = tmp2

	PHD

	PEA	WRMPYA & $FF00
	PLD

	STA	z:<WRMPYA
	TYA
	STA	z:<WRMPYB

	REP	#$21
.A16	; c clear

	; Wait 8 Cycles
	STY	tmpY		; 5
	STX	tmpX		; 5
	LDA	z:RDMPY_DP	; A*Yl

	SEP	#$10
.I8
	LDY	tmpY + 1
	STY	z:<WRMPYB

	; Wait 8 cycles
	STA	product32 + 0	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; A*Yh

	STX	z:<WRMPYB

	; Wait 8 cycles
	STA	product32 + 1	; 5
	XBA			; 3
	AND	#$00FF
	ADC	z:RDMPY_DP	; A*Xl


	LDX	tmpX + 1
	STX	z:<WRMPYB

	; Wait 8 cycles
	STA	product32 + 2	; 5
	REP	#$30		; 3
	SEP	#$20
.A8
.I16
	XBA
	ADC	z:RDMPY_DP	; A*Xl
	STA	product32 + 3


	LDXY	product32
	PLD
	RTS
.endroutine

.endmodule

