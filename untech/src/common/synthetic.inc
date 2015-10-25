;; Synthetic Instructions.
;;
;; Inspiration: <http:;forums.nesdev.com/viewtopic.php?p=87209#p87209>

.ifndef ::_COMMON__SYNTHETIC_INC_
::_COMMON__SYNTHETIC_INC_ = 1


;; Add to accumulator
;;
;; CLC : ADC
;;
;; (index is optional)
.macro ADD param, index
	.ifblank index
		CLC
		ADC	param
	.else
		CLC
		ADC	param, index
	.endif
.endmacro


;; Subtract from accumulator
;;
;; SEC : SBC
;;
;; (index is optional)
.macro SUB param, index
	.ifblank index
		SEC
		SBC	param
	.else
		SEC
		SBC	param, index
	.endif
.endmacro


;; Reverse Subract
;;
;; A = memory - A
;;
;; (index is optional)
.macro RSB param, index
	EOR	#(1 << .asize) - 1
	SEC
	.ifblank index
		ADC	param
	.else
		ADC	param, index
	.endif
.endmacro


;; Arithmetic Shift Right
;;
;; REQUIRE: 8 bit A
.macro ASR
	.if .asize = 8
		CMP	#$80
	.else
		CMP	#$8000
	.endif

	; carry set to the sign bit
	ROR
.endmacro


;; 8/16 bit rotate right
.macro ROTATEL
	ASL A
	ADC	#0
.endmacro


;; 8/16 bit rotate right
.macro ROTATER
	.local skip

	LSR
	BCC	skip

	; carry is set so will add an extra 1
	.if .asize = 8
		ADC	#$80 - 1
	.else
		ADC	#$8000 - 1
	.endif
skip:
.endmacro


;; Negate 8 bit A
;;
;; REQUIRE: 8 bit A
.macro NEG
	EOR	#(1 << .asize) - 1
	INC
.endmacro


;; Load an absolute signed variable into A.
;;
;; Parameter can be X, Y, blank (A), or a variable.
;;
;; Please note that doing a `IF_MINUS : NEG : ENDIF` would be faster
;; than `LDABS A` if you know the the N flag matches the accumulator's
;; MSB.
;;
;; REQUIRES: 8 bit A
;;
;; (index is optional)
.macro LDABS param, index
	.local skip

	.ifblank index
		.if .xmatch({var}, X)
			TXA
		.elseif .xmatch({var}, Y)
			TYA
		.elseif .blank(var) .or .xmatch({var}, A)
			; Sets N flag depending on MSB of A
			CMP	#0
		.else
			LDA	var
		.endif
	.else
		LDA	var, index
	.endif

	BPL	skip
		NEG
skip:
.endmacro


;; Loads the 32 bit value into XY
;;
;; OUTPUT: X/Y the 32 bit value to load (Y = loword)
;;
;; REQUIRES: 16 bit Index
;;
;; (index is optional)
.macro LDXY param, index
	.assert .isize = 16, error, "Expected 16 bit Index"

	.ifblank index
		.if (.match (.left (1, {param}), #))
			; immediate mode
			LDY	#.loword(.right (.tcount ({param})-1, {param}))
			LDX	#.hiword(.right (.tcount ({param})-1, {param}))
		.else
			; absolute or zero page
			LDY	param
			LDX	2 + (param)
		.endif
	.else
		.if (.match (.left (1, {param}), #))
			.error "invalid addressing mode"
		.else
			; absolute or zero page
			LDY	param, index
			LDX	2 + (param), index
		.endif
	.endif
.endmacro


;; Stores the 32 bit XY into a variable
;;
;; INPUT: X/Y the 32 bit value to load (Y = loword)
;;
;; REQUIRES: 16 bit Index
;;
;; (index is optional)
.macro STXY param, index
	.assert .isize = 16, error, "Expected 16 bit Index"

	.ifblank index
		; absolute or zero page
		STY	param
		STX	2 + (param)
	.else
		; absolute or zero page
		STY	param, index
		STX	2 + (param), index
	.endif
.endmacro


;; Pushes XY into the Stack (loword first)
;;
;; INPUT: X/Y the 16/32 bit value to load (Y = loword)
.macro PHXY
	PHX
	PHY
.endmacro


;; Pulls the XY value from the Stack
;;
;; OUTPUT: X/Y the 16/32 bit value to load (Y = loword)
.macro PLXY
	PLY
	PLX
.endmacro

;
; Branching
; ---------
;

;; Branch less than after CMP
.macro BLT target
	BCC	target
.endmacro

;; Branch greater than or equal after CMP
.macro BGE target
	BCS	target
.endmacro

;; Branch greater than after CMP
.macro BGT target
	.local here

	BEQ	here
	BCS	target
here:
.endmacro

;; Branch less than or equal after CMP
.macro BLE target
	BCC	target
	BEQ	target
.endmacro


;
; Long branches
; -------------

;; Long branch always
;; Uses branch is possible (save 1 byte, same cycles)
.macro JRA target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BRA	target
	.else
		JMP	target
	.endif
.endmacro

;; Long branch if z set
.macro JEQ target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BEQ	target
	.else
		.local skip
		BNE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if z clear
.macro JNE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BNE	target
	.else
		.local skip
		BEQ	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if c clear
.macro JCC target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BCC	target
	.else
		.local skip
		BCS	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if c set
.macro JCS target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BCS	target
	.else
		.local skip
		BCC	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if n set
.macro JMI target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BMI	target
	.else
		.local skip
		BPL	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if n clear
.macro JPL target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BPL	target
	.else
		.local skip
		BMI	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if v set
.macro JVS target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BVS	target
	.else
		.local skip
		BVC	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch if v clear
.macro JVC target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BVC	target
	.else
		.local skip
		BVS	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch less than after CMP
.macro JLT target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BLT	target
	.else
		.local skip
		BGE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch greater than or equal after CMP
.macro JGE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BGE	target
	.else
		.local skip
		BLT	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch greater than after CMP
.macro JGT target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BGT	target
	.else
		.local skip
		BLE	skip
		JMP	target
skip:
	.endif
.endmacro

;; Long branch less than or equal after CMP
.macro JLE target
	.if .def(target) .and ((*+2)-(target) <= 127)
		BLE	target
	.else
		.local skip
		BGT	skip
		JMP	target
skip:
	.endif
.endmacro

.endif ; ::_COMMON__SYNTHETIC_INC_

; vim: ft=asm:

