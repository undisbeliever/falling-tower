;; Macros for incrementing/decrementing values

.ifndef ::_COMMON__INCDEC_INC_
::_COMMON__INCDEC_INC_ = 1


;; Increment XY pair
;;
;; MODIFIES: XY
.macro INCXY
	.local skip

	INY
	BNE	skip
	INX
skip:
.endmacro


;; Decrement XY pair
;;
;; MODIFIES: XY
.macro DECXY
	.local skip

	CPY	#0
	BNE	skip
	DEX
skip:
	DEY
.endmacro


;; 16 bit increment on 8 bit Accumulator
;;
;; REQUIRES: 8 bit A
;;
;; (index is optional)
.macro INC16 param, index
	.assert .asize = 8, error, "Expected 8 bit A"

	.local skip

	.ifblank index
		INC	param
		BNE	skip
		INC	1 + (param)
	.else
		INC	param, index
		BNE	skip
		INC	1 + (param), index
	.endif
skip:
.endmacro


;; 32 bit increment of memory
;;
;; REQUIRES: 16 bit A
;;
;; param can be XY
;;
;; (index is optional)
.macro INC32 param, index
	.assert .asize = 16, error, "Expected 16 bit A"

	.local skip
	.ifblank index
		.if .xmatch({param}, XY)
			.assert .isize = 16, error, "Expected 16 bit Index"
			.assert .blank(index), error, "Unexpected index"

			INCXY
		.else
			.assert .asize = 16, error, "Expected 16 bit A"

			INC	param
			BNE	skip
			INC	2 + (param)
		skip:
		.endif
	.else
		.assert .asize = 16, error, "Expected 16 bit A"

		.if .xmatch({param}, XY)
			.error "invalid addressing mode"
		.else
			INC	param, index
			BNE	skip
			INC	2 + (param), index
		skip:
		.endif
	.endif
.endmacro


;; 32 bit decrement of memory
;;
;; REQUIRES: 16 bit A
;; MODIFIES: A
;;
;; param can be XY
;;
;; (index is optional)
.macro Decrement32 param, index
	.local skip
	.ifblank index
		.if .xmatch({param}, XY)
			.assert .isize = 16, error, "Expected 16 bit Index"
			.assert .blank(index), error, "Unexpected index"

			DECXY
		.else
			.assert .asize = 16, error, "Expected 16 bit A"

			LDA	param
			BNE	skip
			DEC	2 + (param)
		skip:
			DEC	param
		.endif
	.else
		.assert .asize = 16, error, "Expected 16 bit A"

		.if .xmatch({param}, XY)
			.error "invalid addressing mode"
		.else
			LDA	param
			BNE	skip
			DEC	2 + (param), index
		skip:
			DEC	param, index
		.endif
	.endif
.endmacro


;; Saturation increment of an unsigned Accumulator
;;
;; max is the maximum value for the accumulator:
;;	max can be a memory address or an immediate with #<int>
;;	if blank then the maximum accumulator value is chosen
.macro INCSAT max
	.ifblank max
		INCSAT #(1 << .asize) - 1

	.elseif (.match (.left (1, {max}), #))
		; immediate mode
		.local i
		.local skip

		i = .right (.tcount({max})-1, {max})

		.if i = (1 << .asize) - 1
			INC
			BNE	skip
			DEC
		.else
			INC
			CMP	#i
			BLT	skip
			LDA	#i
		.endif
skip:
	.else
		.local increment

		CMP	max
		BLT	increment
		LDA	max
		DEC
increment:
		INC
	.endif
.endmacro


;; Saturation decrement of an unsigned Accumulator
;;
;; min is the minimum value for the accumulator:
;;	min can be a memory address or an immediate with #<int>
;;	if blank then the maximum accumulator value is chosen
.macro DECSAT min
	.local skip

	.ifblank min
		DECSAT #0

	.elseif (.match (.left (1, {min}), #))
		; immediate mode
		.local i

		i = .right (.tcount({min})-1, {min}) = 0

		.if .const(i) .and i = 0
			CMP	#0
			BEQ	skip
			DEC
		.else
			DEC
			CMP	#i
			BGE	skip
			LDA	#i
		.endif
	.else
		DEC
		CMP	min
		BGE	skip
		LDA	min
	.endif
skip:
.endmacro

.endif ; ::_COMMON__INCDEC_INC_

; vim: ft=asm:

