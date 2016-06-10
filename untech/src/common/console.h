;; An 8x8 ASCII text console.
;;
;; This module is a SIMPLE 32x32 character buffer using the SNES
;; BG tilemap format.
;;
;; Implementers of this format must be responsible for:
;;	Setting up the tileset
;;	Setting up the palette
;;	Copying the buffer to the screen on VBlank.

.ifndef ::_COMMON__CONSOLE_H_
::_COMMON__CONSOLE_H_ := 1

.include "common/config.inc"
.include "common/modules.inc"
.include "common/synthetic.inc"


.setcpu "65816"

.importmodule Console
	;; The bank in which the CPrintString macro stores the string.
	CONFIG CONSOLE_STRING_BANK, "BANK1"

	;; End of Line Character
	EOL = 13

	;; The console buffer
	.importlabel buffer, far
	;; The size of the console buffer
	.importconst buffer_size, abs

	;; This word is appended to each character to convert it into a tileset
	;; It represents the ' ' character in a fixed tileset
	;; Bits 10-12 are also used to set the text color (palette).
	;; (word)
	.importlabel tilemapOffset, abs


	;; location of the cursor in bytes
	;; Should not edit this directly, instead can be saved/loaded
	;; to create stack functionity
	;; (word)
	.importlabel cursor

	;; When 0:
	;;	Screen is scrolled upwards when the cursor reaches the end
	;; When non-zero:
	;;	Cursor wraps to start of margin
	;; (byte)
	.importlabel scrollScreenOnZero


	;; Initializes the text module
	;;  * Resets the margins
	;;  * Clears the buffer
	;;
	;; REQUIRES: 16 bit Index, DB access shadow
	.importroutine Init

	;; Clears the buffer
	;; REQUIRES: none
	.importroutine Clear

	;; Sets the margins of the console.
	;;
	;; The cursor will be reset to the start of the display.
	;;
	;; REQUIRES: 16 bit Index, DB access shadow
	;; INPUT:
	;;	X = top left margin (top * 64 + left * 2)
	;;      Y = bottom right margin (bottom * 64 + right * 2)
	.importroutine SetMargins

	;; Sets the cursor position
	;; REQUIRES: DB access shadow
	;; INPUT: X = xpos, Y = ypos
	.importroutine SetCursor

	;; Sets the text color
	;; REQUIRES: 8 bit A, DB access shadow
	;; INPUT: A = color (0 - 7)
	.importroutine SetColor

	;; Prints a newline
	;; Will also clear the new line of text
	;; If this is the last line and `scrollScreenOnZero` is zero then
	;; the screen is scrolled up one line
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	.importroutine NewLine

	;; Scrolls the screen up one line
	;; Cursor will also move up one line
	;; REQUIRES: DB access shadow
	.importroutine ScrollUp

	;; Prints a single character to the console
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: A - character to print
	.importroutine PrintChar

	;; Prints a string to the console
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: A:X address of string
	.importroutine PrintString


	;; Prints an unsigned 8 bit integer to the console
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: A = uint8 input
	;; OUTPUT: A:X location of string
	.importroutine PrintInt_U8A

	;; Prints an unsigned 16 bit integer to the console
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: Y = uint16 input
	;; OUTPUT: A:X location of string
	.importroutine PrintInt_U16Y

	;; Prints a unsigned 32 bit integer to the console
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: XY = uint32 input
	;; OUTPUT: A:X location of string
	.importroutine PrintInt_U32XY

	;; Prints a signed 8 bit integer to the console
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: A = sint8 input
	;; OUTPUT: A:X location of string
	.importroutine PrintInt_S8A

	;; Prints a signed 16 bit integer to the console
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: Y = sint16 input
	;; OUTPUT: A:X location of string
	.importroutine PrintInt_S16Y

	;; Prints a signed 32 bit integer to the console
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: XY = sint32 input
	;; OUTPUT: A:X location of string
	.importroutine PrintInt_S32XY


	.macro CPrintString str
		.assert .match(str, ""), error, "Expected string"
		.assert .asize = 8, error, "Requires .asize = 8"
		.assert .isize = 16, error, "Requires .isize = 16"

		.local check, skip, string
		check:

		.segment CONSOLE_STRING_BANK
		string:
				.byte str, 0
		.code
			.assert check = skip, lderror, "Bad flow in CPrintString"
		skip:
			LDA	#.bankbyte(string)
			LDX	#.loword(string)

			JSR	::Console::PrintString
	.endmacro

	.macro CPrintStringLn str
		CPrintString .sprintf("%s%c", str, Console::EOL)
	.endmacro
.endimportmodule

.endif

; vim: ft=asm:

