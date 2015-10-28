; String functions

.ifndef ::_COMMON__STRING_H_
::_COMMON__STRING_H_ := 1

.include "common/modules.inc"

.setcpu "65816"

.importmodule String
	;; Converts an unsigned 8 bit integer to a cstring
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: A = uint8 input
	;; OUTPUT: A:X location of string
	.importroutine IntToString_U8A

	;; Converts an unsigned 16 bit integer to a cstring
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: Y = uint16 input
	;; OUTPUT: A:X location of string
	.importroutine IntToString_U16Y

	;; Converts a unsigned 32 bit integer to a cstring
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: XY = uint32 input
	;; OUTPUT: A:X location of string
	.importroutine IntToString_U32XY

	;; Converts a signed 8 bit integer to a cstring
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: A = sint8 input
	;; OUTPUT: A:X location of string
	.importroutine IntToString_S8A

	;; Converts a signed 16 bit integer to a cstring
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: Y = sint16 input
	;; OUTPUT: A:X location of string
	.importroutine IntToString_S16Y

	;; Converts a signed 32 bit integer to a cstring
	;;
	;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;; INPUT: XY = sint32 input
	;; OUTPUT: A:X location of string
	.importroutine IntToString_S32XY

.endimportmodule

.endif

; vim: ft=asm:

