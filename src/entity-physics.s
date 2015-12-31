
.include "entity-physics.h"
.include "common/config.inc"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"

.setcpu "65816"

.module EntityPhysics

CONFIG GRAVITY, 40
CONFIG MAX_XVECL, $0400
CONFIG MAX_YVECL, $0600

.define ES EntityStruct

.code

; DB = $7E
; IN: DP = entity
.A16
.I16
.routine ProcessEntityPhyicsWithGravity
	LDA	z:ES::yVecl
	CLC
	ADC	#GRAVITY
	STA	z:ES::yVecl

	.assert *= ProcessEntityPhyicsWithoutGravity, error, "Bad Flow"
.endroutine


; DB = $7E
; IN: DP = entity
.A16
.I16
.routine ProcessEntityPhyicsWithoutGravity

	; Clamp the velocity and add to position
	; ::KUDOS Khaz for the uint24 += sint16::
	; ::: http://forums.nesdev.com/viewtopic.php?f=12&t=12459&p=142645#p142674 ::

	; ::TODO make dynamic clamping (depending on type)::
	; ::: ie, add PhysicsConstants to ES, have set/clear when standing on platform::

	LDA	z:ES::xVecl
	IF_MINUS
		CMP	#.loword(-(MAX_XVECL + 1))
		IF_N_SET
			LDA	#.loword(-MAX_XVECL)
			STA	z:ES::xVecl
		ENDIF

		; xVecl is negative
		CLC
		ADC	z:ES::xPos
		STA	z:ES::xPos
		BCS	End_xPos
			; 16 bit underflow - subtract by one
			SEP	#$20
				DEC	z:ES::xPos + 2	; 8 bit A
			REP     #$20
	ELSE
		CMP	#MAX_XVECL + 1
		IF_GE
			LDA	#MAX_XVECL
		ENDIF
		STA	z:ES::xVecl

		; xVecl is positive
		CLC
		ADC	z:ES::xPos
		STA	z:ES::xPos
		BCC	End_xPos
			; 16 bit overflow - add carry
			SEP	#$20        ; 8 bit A
				INC	z:ES::xPos + 2
			REP	#$20        ; 16 bit A again
End_xPos:
	ENDIF


	LDA	z:ES::yVecl
	IF_MINUS
		CMP	#.loword(-(MAX_YVECL + 1))
		IF_N_SET
			LDA	#.loword(-MAX_YVECL)
			STA	z:ES::yVecl
		ENDIF

		; yVecl is negative
		CLC
		ADC	z:ES::yPos
		STA	z:ES::yPos
		BCS	End_yPos
			; 16 bit underflow - subtract by one
			SEP	#$20
				DEC	z:ES::yPos + 2	; 8 bit A
			REP     #$20
	ELSE
		CMP	#MAX_YVECL + 1
		IF_GE
			LDA	#MAX_YVECL
		ENDIF
		STA	z:ES::yVecl

		; yVecl is positive
		CLC
		ADC	z:ES::yPos
		STA	z:ES::yPos
		BCC	End_yPos
			; 16 bit overflow - add carry
			SEP	#$20        ; 8 bit A
				INC	z:ES::yPos + 2
			REP	#$20        ; 16 bit A again
End_yPos:
	ENDIF

	RTS
.endroutine

.endmodule

; vim: set ft=asm:
