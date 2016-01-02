
.include "player.h"
.include "common/modules.inc"
.include "common/structure.inc"
.include "common/registers.inc"

.include "entity.h"
.include "entity-physics.h"
.include "entities/platform.h"

.include "controller.h"
.include "camera.h"
.include "resources/metasprites.h"

CONFIG	JUMP_VELOCITY,	$0300
CONFIG	PLAYER_Y_BOTTOM_OFFSET,	15

.setcpu "65816"

.module PlayerEntity

START_X = 256 / 2

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
	LDA	#START_X + Camera::STARTING_XOFFSET
	STZ	z:PES::xPos
	STA	z:PES::xPos + 1

	LDA	#PlatformEntity::FIRST_START_Y + Camera::STARTING_YOFFSET - PLAYER_Y_BOTTOM_OFFSET
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
	LDA	z:PES::yPos + 1
	SEC
	SBC	#Camera::WINDOW_HEIGHT
	CMP	Camera::yPos
	IF_GE
		; Player offscreen - now dead
		CLC
		RTS
	ENDIF

	LDA	z:PES::standingOnPlatform
	IF_NOT_ZERO
		; Jump only if standing on a platform
		LDA	Controller::pressed
		IF_BIT	#JOY_B | JOY_A
			LDA	#.loword(-JUMP_VELOCITY)
			STA	z:PES::yVecl
		ENDIF
	ENDIF

	LDA	Controller::current
	JMP	EntityPhysics::ProcessEntityPhyicsWithMovement
.endroutine

.endmodule

; vim: set ft=asm:

