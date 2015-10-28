; Math functions

.ifndef ::_COMMON__MATH_H_
::_COMMON__MATH_H_ := 1

.include "common/modules.inc"

.importmodule Math

	.importlabel dividend32
	.importlabel divisor32
	.importlabel remainder32
	result32 := dividend32


	;; Multiplication

	;;; ::TODO multiplication::


	;; Division

	;;; uint16 / uint8 Integer Division
	;;;
	;;; REQUIRES: 8 bit A, 16 bit Index, DB anywhere
	;;;
	;;; INPUT:
	;;;	Y: uint16 dividend
	;;;	A: uint8 divisor
	;;;
	;;; OUTPUT:
	;;;	Y: uint16 result
	;;;	X: uint16 remainder
	.importroutine Divide_U16Y_U8A


	;;; uint16 / uint16 Integer Division
	;;;
	;;; REQUIRES: 16 bit Index, DB anywhere
	;;;
	;;; INPUT:
	;;;	Y: uint16 dividend
	;;;	X: uint16 divisor
	;;;
	;;; OUTPUT:
	;;;	Y: uint16 result
	;;;	X: uint16 remainder
	.importroutine Divide_U16Y_U16X


	;;; sint16 / uint16 Integer Division
	;;;
	;;; REQUIRES: 16 bit Index, DB anywhere
	;;;
	;;; INPUT:
	;;;	Y: sint16 dividend
	;;;	X: uint16 divisor
	;;;
	;;; OUTPUT:
	;;;	Y: sint16 result
	;;;	X: uint16 remainder (Always positive, Euclidian division)
	.importroutine Divide_S16Y_U16X


	;;; uint16 / sint16 Integer Division
	;;;
	;;; REQUIRES: 16 bit Index, DB anywhere
	;;;
	;;; INPUT:
	;;;	Y: uint16 dividend
	;;;	X: sint16 divisor
	;;;
	;;; OUTPUT:
	;;;	Y: sint16 result
	;;;	X: uint16 remainder (Always positive, Euclidian division)
	.importroutine Divide_U16Y_S16X


	;;; sint16 / sint16 Integer Division
	;;;
	;;; REQUIRES: 16 bit Index, DB anywhere
	;;;
	;;; INPUT:
	;;;	Y: sint16 dividend
	;;;	X: sint16 divisor
	;;;
	;;; OUTPUT:
	;;;	Y: sint16 result
	;;;	X: uint16 remainder (Always positive, Euclidian division)
	.importroutine Divide_S16Y_S16X


	;;; uint32 / uint32 Integer Division
	;;;
	;;; REQUIRES: DB access shadow
	;;;
	;;; INPUT:
	;;;	dividend32: uint32 dividend
	;;;	divisor32: uint32 divisor
	;;;
	;;; OUTPUT:
	;;;	result32: uint32 result
	;;;	remainder32: uint32 remainder
	;;;
	;;; NOTES:
	;;;	`result32` and `dividend32` share the same memory location
	.importroutine Divide_U32_U32


	;;; sint32 / sint32 Integer Division
	;;;
	;;; REQUIRES: DB access shadow
	;;;
	;;; INPUT:
	;;;	dividend32: sint32 dividend
	;;;	divisor32: sint32 divisor
	;;;
	;;; OUTPUT:
	;;;	result32: sint32 result
	;;;	remainder32: uint32 remainder (Always positive, Euclidian division)
	;;;
	;;; NOTES:
	;;;	`result32` and `dividend32` share the same memory location
	.importroutine Divide_S32_S32


	;;; uint32 / uint8 Integer Division
	;;;
	;;; REQUIRES: DB access shadow
	;;;
	;;; INPUT:
	;;;	dividend32: uint32 dividend
	;;;	A: uint8 divisor
	;;;
	;;; OUTPUT:
	;;;	result32: uint32 result
	;;;	A: uint8 remainder
	;;;
	;;; NOTES:
	;;;	`result32` and `dividend32` share the same memory location
	.importroutine Divide_U32_U8A

.endimportmodule



;; Negates a 32 bit variable.
;;
;; var can be XY
;;
;; REQUIRE: 16 bit A
.macro Negate32 var, index
	.assert .asize = 16, error, "Require 16 bit Accumulator"

	.ifblank index
		.if .xmatch({var}, XY)
			TYA
			EOR	#$FFFF
			CLC
			ADC	#1
			TAY
			TXA
			EOR	#$FFFF
			ADD	#0
			TAX
		.else
			LDA	var
			EOR	#$FFFF
			CLC
			ADC	#1
			STA	var
			LDA	2 + (var)
			EOR	#$FFFF
			ADC	#0
			STA	2 + (var)
		.endif
	.else
		.if .xmatch({var}, XY)
			.error "invalid addressing mode"
		.else
			LDA	var, X
			EOR	#$FFFF
			CLC
			ADC	#1
			STA	var, X
			LDA	2 + (var), index
			EOR	#$FFFF
			ADC	#0
			STA	2 + (var), index
		.endif
	.endif
.endmacro

.endif

; vim: ft=asm:

