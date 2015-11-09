
.include "console.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/registers.inc"
.include "common/structure.inc"

.include "string.h"

.setcpu "65816"

.define CONSOLE_WIDTH 32

CONFIG_RANGE CONSOLE_HEIGHT, 32, 1, 64
CONFIG_RANGE CONSOLE_MARGIN_TOP, 2, 0, CONSOLE_HEIGHT - 1
CONFIG_RANGE CONSOLE_MARGIN_BOTTOM, 25, CONSOLE_MARGIN_TOP, CONSOLE_HEIGHT
CONFIG_RANGE CONSOLE_MARGIN_LEFT, 2, 0, CONSOLE_WIDTH - 1
CONFIG_RANGE CONSOLE_MARGIN_RIGHT, 30, CONSOLE_MARGIN_LEFT, CONSOLE_WIDTH - 1

;; conversion between ASCII and the tileset
CONFIG CONSOLE_ASCII_DELTA, ' '

;; blank tile to use on screen
CONFIG CONSOLE_EMPTY_TILE, 0

;; The last character to print
CONFIG CONSOLE_LAST_CHARACTER, 144



.module Console


.zeropage
	;; Location of the string to print
	stringPtr:	.res 3

.segment "SHADOW"
	;; The top left of the buffer (byte address)
	startMargin:	.res 2

	;; The bottom right of the buffer (byte address)
	endMargin:	.res 2

	;; The current position (byte address) of the buffer
	cursor:		.res 2

	;; The index of the end of the current line
	endOfLine:	.res 2

	;; When 0:
	;;	Screen is scrolled upwards when the cursor reaches the end
	;; When non-zero:
	;;	Cursor wraps to start of margin
	scrollScreenOnZero:	.res 1

	;; This word is appended to each character to convert it into a tileset
	;; It represents the ' ' character in a fixed tileset
	;; Bits 10-12 are also used to set the text color (palette).
	tilemapOffset:	.res 2


	tmp1:		.res 2


.segment "WRAM7E"
	buffer:		.res CONSOLE_WIDTH * CONSOLE_HEIGHT * 2
	buffer_size	= CONSOLE_WIDTH * CONSOLE_HEIGHT * 2

.exportlabel cursor
.exportlabel buffer, far
.exportconst buffer_size, abs
.exportlabel tilemapOffset, abs
.exportlabel scrollScreenOnZero


EOL = Console::EOL
CURSOR_XMASK = $3F
CURSOR_YMASK = $FFFF - CURSOR_XMASK

.code


.I16
.routine Init
	LDX	#(CONSOLE_MARGIN_TOP * CONSOLE_WIDTH + CONSOLE_MARGIN_LEFT) * 2
	STX	startMargin
	STX	cursor

	LDX	#(CONSOLE_MARGIN_TOP * CONSOLE_WIDTH + CONSOLE_MARGIN_RIGHT) * 2
	STX	endOfLine

	LDX	#(CONSOLE_MARGIN_BOTTOM * CONSOLE_WIDTH + CONSOLE_MARGIN_RIGHT) * 2
	STX	endMargin

	LDX	#0
	STZ	scrollScreenOnZero	; doesn't matter if A=16
	STX	tilemapOffset

	.assert * = Clear, error, "Bad Flow"
.endroutine


.routine Clear
	PHP
	PHB

	REP	#$30
.A16
.I16
	LDA	#0
	STA	f:buffer

	LDX	#.loword(buffer)
	LDY	#.loword(buffer) + 2
	LDA	#buffer_size - 3
	MVN	.bankbyte(buffer), .bankbyte(buffer)

	; cursor = startMargin
	; endOfLine = (endMargin & CURSOR_XMASK) | (cursor & ~CORSOR_XMASK)

	LDA	startMargin
	STA	cursor

	EOR	endMargin
	AND	#CURSOR_XMASK
	EOR	endMargin
	STA	endOfLine

	PLB
	PLP
	RTS
.endroutine



; IN:
; X = top left margin (top * 64 + left * 2)
; Y = bottom right margin (bottom * 64 + right * 2)
.I16
.routine SetMargins
	PHP
	REP	#$30
.A16
.I16
	TYA
	AND	#$FFFE
	CMP	#buffer_size
	IF_GE
		LDA	#(CONSOLE_MARGIN_BOTTOM * CONSOLE_WIDTH + CONSOLE_MARGIN_RIGHT) * 2
	ENDIF
	STA	endMargin

	TXA
	AND	#$FFFE
	CMP	endMargin
	IF_GE
		LDA	#(CONSOLE_MARGIN_TOP * CONSOLE_WIDTH + CONSOLE_MARGIN_LEFT) * 2
	ENDIF
	STA	startMargin

	; cursor = startMargin
	; endOfLine = (cursor & CURSOR_YMASK) | (endMargin & ~CURSOR_YMASK)
	STA	cursor

	EOR	endMargin
	AND	#CURSOR_YMASK
	EOR	endMargin
	STA	endOfLine

	PLP
	RTS
.endroutine



; INTPUT: X = xpos, Y = ypos
.routine SetCursor
	PHP

	REP	#$30
.A16
.I16
	CPY	#CONSOLE_HEIGHT
	IF_GE
		LDY	#0
	ENDIF

	; cursor = (X & 31) * 2 + (Y * 64) + startMargin
	; endOfLine = (cursor & CURSOR_YMASK) | (endMargin & ~CURSOR_YMASK)

	TXA
	AND	#31
	ASL
	STA	cursor

	TYA
	XBA
	LSR
	LSR
	ADC	cursor		; carry always clear
	ADC	startMargin
	STA	cursor

	EOR	endMargin
	AND	#CURSOR_YMASK
	EOR	endMargin
	STA	endOfLine

	PLP
	RTS
.endroutine



; INPUT: A = color (0 - 7)
.A8
.routine SetColor
	; tilemapOffset = (tilemapOffset & $E3FF) | ((A & $7) << 10)
	ASL
	ASL

	EOR	tilemapOffset + 1
	AND	#$7 << 2
	EOR	tilemapOffset + 1
	STA	tilemapOffset + 1

	RTS
.endroutine


.routine ScrollUp
	PHP
	PHB

tmpBytesToCopy = endOfLine
tmpEndBlock = cursor
tmpCurrent	= tmp1

	REP	#$30
.A16
.I16
	; Location of line to copy to
	LDA	cursor
	PHA
	EOR	startMargin
	AND	#CURSOR_YMASK
	EOR	startMargin
	ADD	#.loword(buffer)
	STA	tmpEndBlock


	; Number of bytes to copy per line
	LDA	endMargin
	SUB	startMargin
	AND	#CURSOR_XMASK
	DEC
	STA	tmpBytesToCopy

	; Starting address
	LDA	startMargin
	ADD	#.loword(buffer)
	STA	tmpCurrent

	REPEAT
		LDA	tmpCurrent
		TAY
		ADD	#64
		STA	tmpCurrent
		TAX
		LDA	tmpBytesToCopy
		MVN	.bankbyte(buffer), .bankbyte(buffer)

		CPX	tmpEndBlock
	UNTIL_GE

	; Clear the last line
	LDA	#' ' - CONSOLE_ASCII_DELTA
	ADD	tilemapOffset
	STA	f:buffer, X

	LDX	#.loword(buffer)
	TXY
	INY
	INY
	LDA	tmpBytesToCopy
	DEC
	DEC
	MVN	.bankbyte(buffer), .bankbyte(buffer)

	PLA
	SUB	#64
	CMP	startMargin
	IF_MINUS
		LDA	startMargin
	ENDIF
	STA	cursor

	EOR	endMargin
	AND	#CURSOR_YMASK
	EOR	endMargin
	STA	endOfLine

	PLB
	PLP
.endroutine



.A8
.I16
.routine NewLine
	; if cursor + 64 >= endMargin:
	;	if scrollScreenOnZero:
	;	 	cursor = (cursor & CURSOR_YMASK) | (startMargin & ~CURSOR_YMASK)
	;		return ScrollUp()
	;	else:
	;		cursor = startMargin
	; else
	;	cursor += 64
	; 	cursor = (cursor & CURSOR_YMASK) | (startMargin & ~CURSOR_YMASK)
	; endOfLine = (cursor & CURSOR_YMASK) | (endMargin & ~CURSOR_YMASK)

	REP	#$30
.A16
	LDA	cursor
	ADD	#64
	CMP	endMargin
	IF_GE
		LDA	scrollScreenOnZero
		AND	#$00FF
		IF_EQ
			; Move cursor to start of margin
			; ScrollUp will move cursor up one line
			LDA	cursor
			EOR	startMargin
			AND	#CURSOR_YMASK
			EOR	startMargin
			STA	cursor

			JMP	ScrollUp
		ENDIF

		LDA	startMargin
	ELSE
		EOR	startMargin
		AND	#CURSOR_YMASK
		EOR	startMargin
	ENDIF

	STA	cursor
	TAX

	EOR	endMargin
	AND	#CURSOR_YMASK
	EOR	endMargin
	STA	endOfLine


	; Clear the next line
	LDA	#' ' - CONSOLE_ASCII_DELTA
	ADD	tilemapOffset
	REPEAT
		STA	f:buffer, X
		INX
		INX
		CPX	endOfLine
	UNTIL_GE

	SEP	#$20
.A8
	RTS
.endroutine



; INPUT: A - character to print
.A8
.I16
.routine PrintChar
	CMP	#EOL
	BEQ	NewLine

	SUB	#CONSOLE_ASCII_DELTA

	; Show character
	REP	#$30
.A16
	LDX	cursor

	AND	#$00FF
	ADD	tilemapOffset
	STA	f:buffer, X

	INX
	INX

	CPX	endOfLine
	BGE	NewLine

	STX	cursor

	SEP	#$20
.A8
	RTS
.endroutine



.A8
.I16
.routine PrintString
	PHD
	PEA	0
	PLD

	STX	stringPtr
	STA	stringPtr + 2

	REPEAT
		LDA	[stringPtr]
	WHILE_NOT_ZERO
		JSR	PrintChar

		REP	#$20
.A16
		INC	stringPtr
.A8
		SEP	#$20
	WEND

	PLD
	RTS
.endroutine



.routine PrintInt_U8A
	JSR	String::IntToString_U8A
	BRA	PrintString
.endroutine

.routine PrintInt_U16Y
	JSR	String::IntToString_U16Y
	BRA	PrintString
.endroutine

.routine PrintInt_U32XY
	JSR	String::IntToString_U32XY
	BRA	PrintString
.endroutine

.routine PrintInt_S8A
	JSR	String::IntToString_S8A
	BRA	PrintString
.endroutine

.routine PrintInt_S16Y
	JSR	String::IntToString_S16Y
	BRA	PrintString
.endroutine

.routine PrintInt_S32XY
	JSR	String::IntToString_S32XY
	BRA	PrintString
.endroutine

.endmodule

