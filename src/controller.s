
.include "controller.h"
.include "common/synthetic.inc"
.include "common/registers.inc"
.include "common/structure.inc"


.module Controller

.segment "SHADOW"
	pressed:		.res 2
	current:		.res 2

	;; The inversion of the controller status of of the previous frame
	invertedPrevious:	.res 2

.exportlabel pressed
.exportlabel current

.code


; DB unknown
.A16
.I16
.routine Update
	LDA	f:JOY1
	IF_BIT	#JOY_TYPE_MASK
		LDA	#0
	ENDIF

	STA	current
	AND	invertedPrevious
	STA	pressed

	LDA	current
	EOR	#$FFFF
	STA	invertedPrevious

	RTS
.endroutine

.endmodule

