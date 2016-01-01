
.include "player.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"
.include "entity-physics.h"

.include "controller.h"
.include "resources/metasprites.h"

CONFIG	JUMP_VELOCITY,	$0300

.setcpu "65816"

.module PlayerEntity

.rodata

.proc PlayerEntity
	.addr	Init
	.addr	ProcessFrame
.endproc
.export PlayerEntity


.define PES PlayerEntityStruct

.code

; DP = player
; DB = $7E
.A16
.I16
.routine Init
	; ::DEBUG example starting location::
	LDA	#120 + ENTITY_POS_OFFSET
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#8 + ENTITY_POS_OFFSET
	STZ	z:PES::yPos
	STA	z:PES::yPos + 1

	STZ	z:PES::xVecl
	STZ	z:PES::yVecl

	; Reset platform state
	STZ	z:PES::standingOnPlatform

	LDA	#MetaSprites::Player::frameSetId
	LDY	#0
	JSR	MetaSprite::Init

	LDA	#MetaSprites::Player::Frames::stand_right
	JSR	MetaSprite::SetFrame

	RTS
.endroutine



; DP = player
; DB = $7E
.A16
.I16
.routine ProcessFrame
	; Jump only if standing on a platform
	LDA	z:PES::standingOnPlatform
	IF_NOT_ZERO
		LDA	Controller::pressed
		IF_BIT	#JOY_B | JOY_A
			LDA	#.loword(-JUMP_VELOCITY)
			STA	z:PES::yVecl
		ENDIF
	ENDIF

	JSR	EntityPhysics::ProcessEntityPhyicsWithGravity

	RTS
.endroutine

.endmodule

; vim: set ft=asm:

