
.include "string.h"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"
.include "common/synthetic.inc"

.include "common/math.h"

.setcpu "65816"

; Note: I have to use `RDDIV_DP` / `RDMPY_DP` in order to
; prevent a Suspicious address expression error in ca65.
RDMPY_DP := .lobyte(RDMPY)
RDDIV_DP := .lobyte(RDDIV)


.module String

.define STRING_BUFFER_SIZE 13
.assert STRING_BUFFER_SIZE > .strlen(.sprintf("-%i", $FFFFFFFF)) + 1, error, "Bad constant"

.segment "SHADOW"
	; string buffer
	string:		.res	STRING_BUFFER_SIZE


.code


; IN: A: sint8
; OUT: A:X string pointer
; DB access shadow
.A8
.I16
.routine IntToString_S8A
	CMP	#$80
	IF_GE
		; if negative
		NEG
		JSR	IntToString_U8A

		LDA	#'-'
		DEX
		STA	a:0, X
		RTS
	ENDIF

	.assert * = IntToString_U8A, error, "Bad Flow"
.endroutine



; IN: A: uint8
; OUT: A:X string pointer
; DB access shadow
.A8
.I16
.routine IntToString_U8A
	XBA
	LDA	#0
	XBA
	TAY	; 16 bits transfered

	BRA	IntToString_U16Y
.endroutine



; IN: Y: sint16
; OUT: A:X string pointer
; DB access shadow
.A8
.I16
.routine IntToString_S16Y
	CPY	#$8000
	IF_GE
		; Y is negative
		REP	#$30
.A16
		TYA
		NEG
		TAY

		SEP	#$20
.A8
		JSR	IntToString_U16Y

		LDA	#'-'
		DEX
		STA	a:0, X
		RTS
	ENDIF

	.assert * = IntToString_U16Y, error, "Bad Flow"
.endroutine



; IN: Y: uint16
; OUT: A:X string pointer
; DB access shadow
.A8
.I16
.routine IntToString_U16Y
	; Uses DP to access multiplication
	; wastes `18 - 4*digits` cycles, but allows this routine to be called when DB = $7E

	PHD

	LDA	#.hibyte(WRDIV)
	XBA
	LDA	#0
	TCD

	LDX	#string + STRING_BUFFER_SIZE - 1

	REPEAT
Loop:
		STY	z:<WRDIV

		LDA	#10
		STA	z:<WRDIVB

		; Wait 16 cycles
		NOP					; 2
		LDA	#0				; 2
		STA	a:0 + STRING_BUFFER_SIZE - 1	; 4
		DEX					; 2
		LDA	#'0'				; 2
		CLC					; 2
		ADC	z:RDMPY_DP			; 2 from instruction fetch

		STA	a:0, X

		LDY	z:RDDIV_DP
	UNTIL_ZERO

	LDA	#$7E

	PLD
	RTS
.endroutine



; IN: XY: sint32
; OUT: A:X string pointer
; DB access shadow
.A8
.I16
.routine IntToString_S32XY
	CPX	#$8000
	IF_GE
		; XY is negative
		REP	#$30
.A16
		Negate32	XY

		SEP	#$20
.A8
		JSR	IntToString_U32XY

		LDA	#'-'
		DEX
		STA	a:0, X
		RTS
	ENDIF

	.assert * = IntToString_U32XY, error, "Bad Flow"
.endroutine



; IN: XY: uint32
; OUT: A:X string pointer
; DB access shadow
.A8
.I16
.routine IntToString_U32XY
	; no need to set terminating '\0' character,
	; set by `IntToString_U16Y::Loop`

	CPX	#0
	BEQ	IntToString_U16Y

	STXY	Math::dividend32

	LDX	#string + STRING_BUFFER_SIZE - 1

	REPEAT
		PHX

		LDA	#10
		JSR	Math::Divide_U32_U8A

		PLX
		DEX
		ADD	#'0'
		STA	a:0, X

		LDY	Math::dividend32 + 2
	UNTIL_ZERO

	; save cycles by switching to uint16 mode when possible
	PHD
	LDA	#.hibyte(WRDIV)
	XBA
	LDA	#0
	TCD

	LDY	Math::dividend32
	BRA	IntToString_U16Y::Loop
.endroutine

.endmodule

