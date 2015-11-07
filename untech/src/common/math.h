; Math functions

.ifndef ::_COMMON__MATH_H_
::_COMMON__MATH_H_ := 1

.include "common/modules.inc"

.importmodule Math
	.importlabel product32
	.importlabel factor32


	.importlabel dividend32
	.importlabel divisor32
	.importlabel remainder32
	result32 := dividend32


	;; Multiplication

	;;; Mutliply an 8 bit unsigned integer by an 8 bit unsigned integer
	;;;
	;;; REQUIRES: nothing
	;;;
	;;; INPUT:
	;;;	Y: unsigned integer (only low 8 bits are used)
	;;;	X: unsigned integer (only low 8 bit are used)
	;;;
	;;; OUTPUT:
	;;;	Y: result (8 or 16 bits depending on Index size)
	.importroutine Multiply_U8Y_U8X_UY


	;;; Mutliply a 16 bit integer by an 8 bit unsigned integer
	;;;
	;;; REQUIRES: 8 bit A, 16 bit Index
	;;;
	;;; INPUT:
	;;;	Y: 16 bit integer
	;;;	A: 8 bit unsigned integer
	;;;
	;;; OUTPUT:
	;;;	Y: 16 bit product
	.importroutine Multiply_U16Y_U8A_U16Y
	Multiply_S16Y_U8A_S16Y := Multiply_U16Y_U8A_U16Y


	;;; Mutliply a 16 bit unsigned integer by an 8 bit unsigned integer, resulting in a 32 bit unsigned integer
	;;;
	;;; REQUIRES: 8 bit A, 16 bit Index, DB access shadow
	;;;
	;;; INPUT:
	;;;	Y: 16 bit unsigned integer
	;;;	A: 8 bit unsigned integer
	;;;
	;;; OUTPUT:
	;;;	XY: 32 bit unsigned product
	;;;	product32: 32 bit unsigned product
	.importroutine Multiply_U16Y_U8A_U32XY
	Multiply_U16Y_U8A_U32 := Multiply_U16Y_U8A_U32XY


	;;; Multiply two 16 bit integers.
	;;;
	;;; The signs of the inputs and ouputs are in the parameters.
	;;;
	;;; REQUIRES: nothing, reccomend 16 bit Index, DB access shadow
	;;;
	;;; INPUT:
	;;;	Y: 16 bit factor
	;;;	X: 16 bit factor
	;;;
	;;; OUTPUT:
	;;;	Y: 16 bit product
	.importroutine Multiply_U16Y_U16X_U16Y
	Multiply_U16Y_S16X_16Y := Multiply_U16Y_U16X_U16Y
	Multiply_S16Y_U16X_16Y := Multiply_U16Y_U16X_U16Y
	Multiply_S16Y_S16X_S16Y := Multiply_U16Y_U16X_U16Y


	;;; Multiply two 16 bit integers resulting in a 32 integer.
	;;;
	;;; The signs of the inputs and ouputs are in the parameters.
	;;;
	;;; REQUIRES: 16 bit Index, DB access shadow
	;;;
	;;; INPUT:
	;;;	Y: 16 bit factor
	;;;	X: 16 bit factor
	;;;
	;;; OUTPUT:
	;;;	XY: 32 bit product
	;;;	product32: 32 bit product
	.importroutine Multiply_U16Y_U16X_U32XY
	Multiply_U16Y_U16X_U32 := Multiply_U16Y_U16X_U32XY
	Multiply_U16Y_S16X_32XY := Multiply_U16Y_U16X_U32XY
	.importroutine Multiply_S16Y_S16X_S32XY
	Multiply_S16Y_S16X_S32 := Multiply_U16Y_U16X_U32XY



	;;; Multiply a 32 bit integer by a 16 bit integer
	;;;
	;;; The signs of the inputs and ouputs are in the parameters.
	;;;
	;;; REQUIRES: 16 bit Index, DB access shadow
	;;;
	;;; INPUT:
	;;; 	factor32: 32 bit factor
	;;;	Y: 16 bit factor
	;;;
	;;; OUTPUT:
	;;;	XY: 32 bit product
	;;;	product32: 32 bit product
	.importroutine Multiply_U32_U16Y_U32XY
	Multiply_U32_U16Y_U32 := Multiply_U32_U16Y_U32XY
	Multiply_S32_U16Y_S32 := Multiply_U32_U16Y_U32XY
	Multiply_S32_U16Y_S32XY := Multiply_U32_U16Y_U32XY
	.importroutine Multiply_S32_S16Y_S32XY
	Multiply_S32_S16Y_S32 := Multiply_S32_S16Y_S32XY
	Multiply_U32_S16Y_32XY := Multiply_S32_S16Y_S32XY
	Multiply_U32_S16Y_32 := Multiply_S32_S16Y_S32XY


	;;; Multiply a 32 bit integer by another 32 bit integer.
	;;;
	;;; REQUIRES: 16 bit Index, DB access shadow
	;;;
	;;; INPUT:
	;;;	factor32: 32 bit factor
	;;;	XY: 32 bit factor (Y = loword)
	;;;
	;;; OUTPUT:
	;;;	XY: 32 bit product
	;;;	product32: 32 bit product
	.importroutine Multiply_U32_U32XY_U32XY
	Multiply_U32_U32XY_U32 := Multiply_U32_U32XY_U32XY
	Multiply_U32_S32XY_32XY := Multiply_U32_U32XY_U32XY
	Multiply_U32_S32XY_32 := Multiply_U32_U32XY_U32XY
	Multiply_S32_U32XY_32XY := Multiply_U32_U32XY_U32XY
	Multiply_S32_U32XY_32 := Multiply_U32_U32XY_U32XY
	Multiply_S32_S32XY_S32XY := Multiply_U32_U32XY_U32XY
	Multiply_S32_S32XY_S32 := Multiply_U32_U32XY_U32XY


	;;; Mutliply a 32 bit integer by an 8 bit unsigned integer
	;;;
	;;; REQUIRES: 16 bit Index, DB access shadow
	;;;
	;;; INPUT:
	;;;	XY: 32 bit factor (Y loword)
	;;;	A: 8 bit unsigned factor
	;;;
	;;; OUTPUT:
	;;;	XY: 32 bit product
	;;;	product32: 32 bit product
	.importroutine Multiply_U32XY_U8A_U32XY
	Multiply_U32XY_U8A_U32 := Multiply_U32XY_U8A_U32XY
	Multiply_S32XY_U8A_S32XY := Multiply_U32XY_U8A_U32XY
	Multiply_S32XY_U8A_S32 := Multiply_U32XY_U8A_U32XY



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

